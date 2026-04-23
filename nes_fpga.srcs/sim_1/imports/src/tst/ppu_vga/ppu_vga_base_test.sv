// PPU VGA Base Test
// This file is included in ppu_vga_pkg.sv and should not be compiled standalone.

class ppu_vga_base_test extends nes_ram_base_test;
  `uvm_component_utils(ppu_vga_base_test)

  ppu_vga_env env;
  virtual ppu_vga_if  vga_vif;
  virtual tb_ctrl_if  tb_ctrl_vif;

  function new(string name = "ppu_vga_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function bit enable_ram_env();
    return 1'b0;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // UVM timeouts are interpreted in the library time precision here, so use
    // an absolute value large enough for a near-full VGA frame.
    uvm_top.set_timeout(64'd50_000_000_000, 0);

    if (!uvm_config_db#(virtual tb_ctrl_if)::get(this, "", "tb_ctrl_vif", tb_ctrl_vif)) begin
      `uvm_fatal("TEST", "Cannot get tb_ctrl_vif from uvm_config_db");
    end

    if (!uvm_config_db#(virtual ppu_vga_if)::get(this, "", "vga_vif", vga_vif)) begin
      `uvm_fatal("TEST", "Cannot get vga_vif from uvm_config_db");
    end

    env = ppu_vga_env::type_id::create("env", this);
  endfunction

  protected task print_case_header(string case_name, string goal);
    `uvm_info("PPU_VGA_CASE", " ", UVM_NONE)
    `uvm_info("PPU_VGA_CASE", "############################################################", UVM_NONE)
    `uvm_info("PPU_VGA_CASE", "################### PPU VGA TESTCASE #######################", UVM_NONE)
    `uvm_info("PPU_VGA_CASE", "############################################################", UVM_NONE)
    `uvm_info("PPU_VGA_CASE", $sformatf("CASE_ID : %s", case_name), UVM_NONE)
    `uvm_info("PPU_VGA_CASE", $sformatf("PURPOSE : %s", goal), UVM_NONE)
    `uvm_info("PPU_VGA_CASE", "############################################################", UVM_NONE)
    `uvm_info("PPU_VGA_CASE", " ", UVM_NONE)
  endtask

  protected task run_cycles(int unsigned cycles);
    repeat (cycles) @(vga_vif.mon_cb);
  endtask

  protected task drive_palette(bit [5:0] palette_idx, int unsigned cycles = 1);
    ppu_vga_hold_palette_seq seq;
    seq = ppu_vga_hold_palette_seq::type_id::create("seq");
    seq.palette_idx = palette_idx;
    seq.cycles      = cycles;
    seq.start(env.master_agent.sequencer);
  endtask

  protected task drive_random_palette(int unsigned cycles = 16);
    ppu_vga_random_palette_seq seq;
    seq = ppu_vga_random_palette_seq::type_id::create("seq");
    seq.cycles = cycles;
    seq.start(env.master_agent.sequencer);
  endtask

  protected task sweep_palette_visible(int unsigned cycles_per_entry = 2);
    ppu_vga_palette_sweep_seq seq;
    seq = ppu_vga_palette_sweep_seq::type_id::create("seq");
    seq.start_idx        = 6'h00;
    seq.end_idx          = 6'h3f;
    seq.cycles_per_entry = cycles_per_entry;
    seq.start(env.master_agent.sequencer);
  endtask

  protected task wait_for_visible_line_start();
    do @(vga_vif.mon_cb);
    while (!(vga_vif.mon_cb.sync_en &&
             (vga_vif.mon_cb.sync_x == 10'd64) &&
             (vga_vif.mon_cb.nes_y_out >= 10'd8) &&
             (vga_vif.mon_cb.nes_y_out < 10'd232)));
  endtask

  protected task wait_for_top_border();
    do @(vga_vif.mon_cb);
    while (!(vga_vif.mon_cb.sync_en &&
             (vga_vif.mon_cb.sync_x == 10'd64) &&
             (vga_vif.mon_cb.nes_y_out < 10'd8)));
  endtask

  protected task wait_for_right_border();
    do @(vga_vif.mon_cb);
    while (!(vga_vif.mon_cb.sync_en &&
             (vga_vif.mon_cb.nes_x_out >= 10'd256) &&
             (vga_vif.mon_cb.nes_y_out >= 10'd8) &&
             (vga_vif.mon_cb.nes_y_out < 10'd232)));
  endtask

  protected task wait_for_bottom_border();
    do @(vga_vif.mon_cb);
    while (!(vga_vif.mon_cb.sync_en &&
             (vga_vif.mon_cb.sync_x == 10'd64) &&
             (vga_vif.mon_cb.nes_y_out >= 10'd232)));
  endtask

  protected task wait_for_sync_coord(int unsigned x, int unsigned y);
    do @(vga_vif.mon_cb);
    while (!((vga_vif.mon_cb.sync_x == x[9:0]) && (vga_vif.mon_cb.sync_y == y[9:0])));
  endtask

  protected task check_reset_rgb_vblank(string tag);
    bit pass;
    pass = ({vga_vif.r_out, vga_vif.g_out, vga_vif.b_out} === 8'h00) && (vga_vif.vblank_out === 1'b0);
    if (pass)
      `uvm_info("PPU_VGA_RST", $sformatf("[%s] PASS rgb=00 vblank=0 during reset", tag), UVM_LOW)
    else
      `uvm_error("PPU_VGA_RST",
        $sformatf("[%s] FAIL rgb=%02h vblank=%0b during reset",
        tag, {vga_vif.r_out, vga_vif.g_out, vga_vif.b_out}, vga_vif.vblank_out))
  endtask

  protected task tc_reset();
    print_case_header("VGA_RST01_RESET", "Assert reset and confirm RGB/vblank are cleared");
    tb_ctrl_vif.rst_req <= 1'b1;
    run_cycles(4);
    check_reset_rgb_vblank("VGA_RST01_RESET_EARLY");
    run_cycles(4);
    check_reset_rgb_vblank("VGA_RST01_RESET_LATE");
    tb_ctrl_vif.rst_req <= 1'b0;
    run_cycles(4);
  endtask

  protected task tc_palette_visible_area();
    print_case_header("VGA_PAL01_VISIBLE_SWEEP", "Sweep palette indices inside visible non-border area");
    wait_for_visible_line_start();
    sweep_palette_visible(2);
    run_cycles(4);
  endtask

  protected task tc_border_color();
    print_case_header("VGA_BDR01_BORDER_COLOR", "Drive random palette while checking top/right/bottom border color forcing");
    wait_for_top_border();
    drive_random_palette(12);
    wait_for_right_border();
    drive_random_palette(12);
    wait_for_bottom_border();
    drive_random_palette(12);
    run_cycles(4);
  endtask

  protected task tc_vblank_timing();
    print_case_header("VGA_VBL01_TIMING", "Check vblank set/clear timing at the documented VGA coordinates");
    wait_for_sync_coord(730, 477);
    @(vga_vif.mon_cb);
    if (vga_vif.vblank_out !== 1'b1)
      `uvm_error("PPU_VGA_VBL", "VBLANK did not assert one clock after sync=(730,477)")
    else
      `uvm_info("PPU_VGA_VBL", "VBLANK asserted at the expected timing point", UVM_LOW)

    wait_for_sync_coord(64, 519);
    @(vga_vif.mon_cb);
    if (vga_vif.vblank_out !== 1'b0)
      `uvm_error("PPU_VGA_VBL", "VBLANK did not clear one clock after sync=(64,519)")
    else
      `uvm_info("PPU_VGA_VBL", "VBLANK cleared at the expected timing point", UVM_LOW)
  endtask

endclass
