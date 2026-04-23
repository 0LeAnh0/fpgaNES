// PPU BG Base Test
// This file is included in ppu_bg_pkg.sv and should not be compiled standalone.

class ppu_bg_base_test extends nes_ram_base_test;
  `uvm_component_utils(ppu_bg_base_test)

  ppu_bg_env env;
  ppu_bg_cfg cfg;
  virtual tb_ctrl_if tb_ctrl_vif;
  virtual ppu_bg_if  bg_vif;

  function new(string name = "ppu_bg_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function bit enable_ram_env();
    return 1'b0;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    cfg = ppu_bg_cfg::type_id::create("cfg");
    uvm_config_db#(ppu_bg_cfg)::set(this, "*", "cfg", cfg);

    if (!uvm_config_db#(virtual tb_ctrl_if)::get(this, "", "tb_ctrl_vif", tb_ctrl_vif)) begin
      `uvm_fatal("TEST", "Cannot get tb_ctrl_vif from uvm_config_db");
    end

    if (!uvm_config_db#(virtual ppu_bg_if)::get(this, "", "bg_vif", bg_vif)) begin
        // Fallback or warning if specifically using MASTER/MONITOR modports
        void'(uvm_config_db#(virtual ppu_bg_if)::get(this, "*master_agent*", "vif", bg_vif));
    end

    env = ppu_bg_env::type_id::create("env", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

  // Reset ban dau cho PPU BG
  protected task tc_initial_reset_observe();
    print_case_header("BG_RST01_INITIAL_RESET", "Confirm PPU BG outputs are stable 0 after initial reset");
    apply_reset_pulse(10);
    check_ppu_bg_reset_state("BG_RST01_INITIAL_RESET");
  endtask

  // Reset ngau nhien de stress PPU BG
  protected task tc_random_reset_stress();
    int i;
    int hold_cycles;
    print_case_header("BG_RST02_RANDOM_RESET", "Stress PPU BG with multiple random reset pulses");
    for (i = 0; i < 5; i++) begin
        #(50ns + $urandom_range(0, 200)*1ns);
        hold_cycles = $urandom_range(2, 10);
        `uvm_info("PPU_BG_RST", $sformatf("[RANDOM_RST_%0d] hold_cycles=%0d", i, hold_cycles), UVM_NONE)
        apply_reset_pulse(hold_cycles);
        check_ppu_bg_reset_state($sformatf("BG_RST02_RANDOM_RESET_%0d", i));
    end
  endtask

  // Check logic sau reset cho BG
  protected task check_ppu_bg_reset_state(string tag);
    bit pass = 1;
    if (bg_vif == null) return;
    `uvm_info("PPU_BG_RST_CHK", "-------------- PPU_BG RESET CHECK --------------", UVM_NONE)
    `uvm_info("PPU_BG_RST_CHK", $sformatf("TAG: %s", tag), UVM_NONE)
    // Sau reset, dia chi VRAM out phai ve 0 hoac trang thai mac dinh
    if (bg_vif.vram_a_out !== 14'h0000) pass = 0;
    
    if (pass)
        `uvm_info("PPU_BG_RST_CHK", "RESULT: PASS (VRAM_A reset to 0)", UVM_LOW)
    else
        `uvm_warning("PPU_BG_RST_CHK", "RESULT: FAIL (VRAM_A is not 0 after reset)")
    `uvm_info("PPU_BG_RST_CHK", "------------------------------------------------", UVM_NONE)
  endtask

endclass
