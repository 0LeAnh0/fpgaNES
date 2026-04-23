class ppu_full_integration_test extends ppu_top_base_test;
  `uvm_component_utils(ppu_full_integration_test)

  function new(string name = "ppu_full_integration_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_top.set_timeout(64'd90_000_000_000, 0);
  endfunction

  protected function bit [7:0] palette_to_rgb(bit [5:0] idx);
    case (idx)
      6'h00: palette_to_rgb = { 3'h3, 3'h3, 2'h1 };
      6'h01: palette_to_rgb = { 3'h1, 3'h0, 2'h2 };
      6'h02: palette_to_rgb = { 3'h0, 3'h0, 2'h2 };
      6'h03: palette_to_rgb = { 3'h2, 3'h0, 2'h2 };
      6'h04: palette_to_rgb = { 3'h4, 3'h0, 2'h1 };
      6'h05: palette_to_rgb = { 3'h5, 3'h0, 2'h0 };
      6'h06: palette_to_rgb = { 3'h5, 3'h0, 2'h0 };
      6'h07: palette_to_rgb = { 3'h3, 3'h0, 2'h0 };
      6'h08: palette_to_rgb = { 3'h2, 3'h1, 2'h0 };
      6'h09: palette_to_rgb = { 3'h0, 3'h2, 2'h0 };
      6'h0a: palette_to_rgb = { 3'h0, 3'h2, 2'h0 };
      6'h0b: palette_to_rgb = { 3'h0, 3'h1, 2'h0 };
      6'h0c: palette_to_rgb = { 3'h0, 3'h1, 2'h1 };
      6'h10: palette_to_rgb = { 3'h5, 3'h5, 2'h2 };
      6'h11: palette_to_rgb = { 3'h0, 3'h3, 2'h3 };
      6'h12: palette_to_rgb = { 3'h1, 3'h1, 2'h3 };
      6'h13: palette_to_rgb = { 3'h4, 3'h0, 2'h3 };
      6'h14: palette_to_rgb = { 3'h5, 3'h0, 2'h2 };
      6'h15: palette_to_rgb = { 3'h7, 3'h0, 2'h1 };
      6'h16: palette_to_rgb = { 3'h6, 3'h1, 2'h0 };
      6'h17: palette_to_rgb = { 3'h6, 3'h2, 2'h0 };
      6'h18: palette_to_rgb = { 3'h4, 3'h3, 2'h0 };
      6'h19: palette_to_rgb = { 3'h0, 3'h4, 2'h0 };
      6'h1a: palette_to_rgb = { 3'h0, 3'h5, 2'h0 };
      6'h1b: palette_to_rgb = { 3'h0, 3'h4, 2'h0 };
      6'h1c: palette_to_rgb = { 3'h0, 3'h4, 2'h2 };
      6'h20: palette_to_rgb = { 3'h7, 3'h7, 2'h3 };
      6'h21: palette_to_rgb = { 3'h1, 3'h5, 2'h3 };
      6'h22: palette_to_rgb = { 3'h2, 3'h4, 2'h3 };
      6'h23: palette_to_rgb = { 3'h5, 3'h4, 2'h3 };
      6'h24: palette_to_rgb = { 3'h7, 3'h3, 2'h3 };
      6'h25: palette_to_rgb = { 3'h7, 3'h3, 2'h2 };
      6'h26: palette_to_rgb = { 3'h7, 3'h3, 2'h1 };
      6'h27: palette_to_rgb = { 3'h7, 3'h4, 2'h0 };
      6'h28: palette_to_rgb = { 3'h7, 3'h5, 2'h0 };
      6'h29: palette_to_rgb = { 3'h4, 3'h6, 2'h0 };
      6'h2a: palette_to_rgb = { 3'h2, 3'h6, 2'h1 };
      6'h2b: palette_to_rgb = { 3'h2, 3'h7, 2'h2 };
      6'h2c: palette_to_rgb = { 3'h0, 3'h7, 2'h3 };
      6'h30: palette_to_rgb = { 3'h7, 3'h7, 2'h3 };
      6'h31: palette_to_rgb = { 3'h5, 3'h7, 2'h3 };
      6'h32: palette_to_rgb = { 3'h6, 3'h6, 2'h3 };
      6'h33: palette_to_rgb = { 3'h6, 3'h6, 2'h3 };
      6'h34: palette_to_rgb = { 3'h7, 3'h6, 2'h3 };
      6'h35: palette_to_rgb = { 3'h7, 3'h6, 2'h3 };
      6'h36: palette_to_rgb = { 3'h7, 3'h5, 2'h2 };
      6'h37: palette_to_rgb = { 3'h7, 3'h6, 2'h2 };
      6'h38: palette_to_rgb = { 3'h7, 3'h7, 2'h2 };
      6'h39: palette_to_rgb = { 3'h7, 3'h7, 2'h2 };
      6'h3a: palette_to_rgb = { 3'h5, 3'h7, 2'h2 };
      6'h3b: palette_to_rgb = { 3'h5, 3'h7, 2'h3 };
      6'h3c: palette_to_rgb = { 3'h4, 3'h7, 2'h3 };
      default: palette_to_rgb = 8'h00;
    endcase
  endfunction

  protected task write_ppuctrl(bit nmi_en, bit bg_pt, bit spr_pt, bit addr_inc, bit v_nt, bit h_nt, bit spr_h = 0);
    ppu_ri_ppuctrl_sequence seq;
    seq = ppu_ri_ppuctrl_sequence::type_id::create("seq_ppuctrl");
    seq.nvbl_en  = nmi_en;
    seq.spr_h    = spr_h;
    seq.s        = bg_pt;
    seq.spr_pt   = spr_pt;
    seq.addr_inc = addr_inc;
    seq.v        = v_nt;
    seq.h        = h_nt;
    seq.start(m_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
  endtask

  protected task write_ppumask(bit spr_en, bit bg_en, bit spr_show_left = 1, bit bg_show_left = 1);
    ppu_ri_ppumask_sequence seq;
    seq = ppu_ri_ppumask_sequence::type_id::create("seq_ppumask");
    seq.spr_en        = spr_en;
    seq.bg_en         = bg_en;
    seq.spr_show_left = spr_show_left;
    seq.bg_show_left  = bg_show_left;
    seq.start(m_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
  endtask

  protected task write_ppuaddr_data(bit [13:0] addr, bit [7:0] data);
    ppu_ri_ppuaddr_sequence seq_addr;
    ppu_ri_ppudata_write_sequence seq_data;

    seq_addr = ppu_ri_ppuaddr_sequence::type_id::create("seq_addr");
    seq_data = ppu_ri_ppudata_write_sequence::type_id::create("seq_data");
    seq_addr.vram_addr = addr;
    seq_data.ppu_data  = data;
    seq_addr.start(m_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
    seq_data.start(m_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
  endtask

  protected task write_oam_byte(bit [7:0] addr, bit [7:0] data);
    ppu_ri_oamaddr_sequence seq_addr;
    ppu_ri_oamdata_sequence seq_data;
    seq_addr = ppu_ri_oamaddr_sequence::type_id::create("seq_oamaddr");
    seq_data = ppu_ri_oamdata_sequence::type_id::create("seq_oamdata");
    seq_addr.oam_addr = addr;
    seq_data.oam_data = data;
    seq_addr.start(m_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
    seq_data.start(m_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
  endtask

  protected task program_sprite0();
    print_case_header("PPU_TOP_OAM01", "Program sprite-0 through RI path so sprite block requests VRAM");
    write_oam_byte(8'h00, 8'h18);
    write_oam_byte(8'h01, 8'h00);
    write_oam_byte(8'h02, 8'h00);
    write_oam_byte(8'h03, 8'h20);
  endtask

  protected task program_overflow_sprite_band(bit sprite_8x16);
    print_case_header("PPU_TOP_OAM02", "Program more than 8 sprites on one scanline through RI/OAM path");
    for (int i = 0; i < 10; i++) begin
      write_oam_byte((i * 4) + 8'h00, 8'h0A);
      write_oam_byte((i * 4) + 8'h01, i[7:0]);
      write_oam_byte((i * 4) + 8'h02, 8'h00);
      write_oam_byte((i * 4) + 8'h03, (8'h10 + i[7:0]));
    end
    write_ppuctrl(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, sprite_8x16);
  endtask

  protected task wait_for_visible_non_border();
    do @(vga_vif.mon_cb);
    while (!(vga_vif.mon_cb.sync_en &&
             (vga_vif.mon_cb.nes_x_out < 10'd256) &&
             (vga_vif.mon_cb.nes_y_out >= 10'd8) &&
             (vga_vif.mon_cb.nes_y_out < 10'd232)));
  endtask

  protected task tc_palette_path_to_vga();
    bit [5:0] palette_idx;
    bit [7:0] exp_rgb;

    print_case_header("PPU_TOP_PRAM01", "Verify RI -> PRAM -> top palette mux -> VGA output path");
    palette_idx = 6'h21;
    exp_rgb = palette_to_rgb(palette_idx);

    write_ppuctrl(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    write_ppumask(1'b0, 1'b0, 1'b1, 1'b1);
    write_ppuaddr_data(14'h3f00, {2'b00, palette_idx});

    wait_for_visible_non_border();
    repeat (2) @(vga_vif.mon_cb);

    if (ppu_top_vif.vga_sys_palette_idx !== palette_idx)
      `uvm_error("PPU_TOP_PRAM", $sformatf("Expected system palette idx %02h, got %02h", palette_idx, ppu_top_vif.vga_sys_palette_idx))
    else
      `uvm_info("PPU_TOP_PRAM", $sformatf("System palette idx observed correctly: %02h", palette_idx), UVM_LOW)

    if ({vga_vif.r_out, vga_vif.g_out, vga_vif.b_out} !== exp_rgb)
      `uvm_error("PPU_TOP_PRAM", $sformatf("Expected VGA RGB %02h, got %02h", exp_rgb, {vga_vif.r_out, vga_vif.g_out, vga_vif.b_out}))
    else
      `uvm_info("PPU_TOP_PRAM", $sformatf("VGA RGB matched expected system color %02h", exp_rgb), UVM_LOW)
  endtask

  protected task tc_sprite_arbiter();
    int unsigned wait_cycles;

    print_case_header("PPU_TOP_ARB01", "Verify sprite fetch requests take ownership of top-level VRAM address bus");
    program_sprite0();
    write_ppumask(1'b1, 1'b1, 1'b1, 1'b1);

    wait_cycles = 0;
    while ((spr_vif.vram_req_out !== 1'b1) && (wait_cycles < 4_000_000)) begin
      @(spr_vif.mon_cb);
      wait_cycles++;
    end

    if (spr_vif.vram_req_out !== 1'b1)
      `uvm_error("PPU_TOP_ARB", "Did not observe sprite VRAM request within expected integration window")
    else begin
      `uvm_info("PPU_TOP_ARB",
        $sformatf("Observed sprite VRAM request after %0d cycles; top arbiter should already be checked by scoreboard", wait_cycles),
        UVM_LOW)
    end
  endtask

  protected task tc_sprite_overflow_top();
    int unsigned wait_cycles;

    print_case_header("PPU_TOP_SPR01", "Verify sprite overflow can be observed through the full top path");
    program_overflow_sprite_band(1'b0);
    write_ppumask(1'b1, 1'b0, 1'b1, 1'b1);

    wait_cycles = 0;
    while ((spr_vif.overflow_out !== 1'b1) && (wait_cycles < 4_000_000)) begin
      @(spr_vif.mon_cb);
      wait_cycles++;
    end

    if (spr_vif.overflow_out !== 1'b1)
      `uvm_error("PPU_TOP_SPR", "Did not observe sprite overflow in top-level integration window")
    else
      `uvm_info("PPU_TOP_SPR",
        $sformatf("Observed sprite overflow after %0d sprite monitor cycles", wait_cycles),
        UVM_LOW)
  endtask

  protected task tc_vblank_gate();
    int unsigned wait_cycles;

    print_case_header("PPU_TOP_VBL01", "Verify top-level /VBL output follows RI vblank gated by PPUCTRL NMI enable");
    write_ppuctrl(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

    wait_cycles = 0;
    while (!((ppu_top_vif.ri_vblank === 1'b1) && (ppu_top_vif.ri_nvbl_en === 1'b1)) &&
           (wait_cycles < 4_000_000)) begin
      @(ppu_top_vif.mon_cb);
      wait_cycles++;
    end

    if (!((ppu_top_vif.ri_vblank === 1'b1) && (ppu_top_vif.ri_nvbl_en === 1'b1)))
      `uvm_error("PPU_TOP_VBL", "Did not observe gated RI vblank state within expected integration window")
    else if (ppu_top_vif.nvbl_out !== 1'b0)
      `uvm_error("PPU_TOP_VBL", "Expected nvbl_out to go low during vblank when NMI enable is set")
    else
      `uvm_info("PPU_TOP_VBL", "Observed vblank and active-low /VBL gating correctly", UVM_LOW)
  endtask

  protected task tc_live_palette_update_during_visible();
    bit [5:0] initial_idx;
    bit [5:0] updated_idx;
    bit [7:0] exp_rgb;
    int unsigned wait_cycles;

    print_case_header("PPU_TOP_PRAM02", "Verify PRAM writes during active display update the live top palette path");

    initial_idx = 6'h11;
    updated_idx = 6'h2c;
    exp_rgb     = palette_to_rgb(updated_idx);

    write_ppuctrl(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    write_ppumask(1'b0, 1'b0, 1'b1, 1'b1);
    write_ppuaddr_data(14'h3f00, {2'b00, initial_idx});

    wait_for_visible_non_border();
    repeat (2) @(vga_vif.mon_cb);

    fork
      begin : live_pram_writer
        repeat (8) @(vga_vif.mon_cb);
        write_ppuaddr_data(14'h3f00, {2'b00, updated_idx});
      end
      begin : live_pram_observer
        wait_cycles = 0;
        while ((ppu_top_vif.vga_sys_palette_idx !== updated_idx) && (wait_cycles < 2000)) begin
          @(vga_vif.mon_cb);
          wait_cycles++;
        end
        if (ppu_top_vif.vga_sys_palette_idx !== updated_idx)
          `uvm_error("PPU_TOP_PRAM", "Did not observe live PRAM update on system palette path during active display")
        else
          `uvm_info("PPU_TOP_PRAM",
            $sformatf("Observed live PRAM update after %0d monitor cycles", wait_cycles),
            UVM_LOW)
      end
    join

    wait_for_visible_non_border();
    repeat (2) @(vga_vif.mon_cb);
    if ({vga_vif.r_out, vga_vif.g_out, vga_vif.b_out} !== exp_rgb)
      `uvm_error("PPU_TOP_PRAM", $sformatf("Expected updated visible RGB %02h after live PRAM write, got %02h",
        exp_rgb, {vga_vif.r_out, vga_vif.g_out, vga_vif.b_out}))
  endtask

  protected task tc_vblank_enable_disable_race();
    int unsigned wait_cycles;
    bit [5:0] masked_idx;
    bit [5:0] gated_idx;

    print_case_header("PPU_TOP_VBL02", "Verify /VBL reacts correctly when NMI enable is toggled during active vblank");

    masked_idx = 6'h16;
    gated_idx  = 6'h2a;
    write_ppuctrl(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

    wait_cycles = 0;
    while ((ppu_top_vif.ri_vblank !== 1'b1) && (wait_cycles < 4_000_000)) begin
      @(ppu_top_vif.mon_cb);
      wait_cycles++;
    end

    if (ppu_top_vif.ri_vblank !== 1'b1) begin
      `uvm_error("PPU_TOP_VBL", "Could not reach active vblank window for NMI gate race test")
      return;
    end

    if (ppu_top_vif.nvbl_out !== 1'b1)
      `uvm_error("PPU_TOP_VBL", "Expected /VBL to stay high when vblank is active but NMI enable is still low")

    write_ppuaddr_data(14'h3f01, {2'b00, masked_idx});

    fork
      begin : enable_nmi_during_vblank
        write_ppuctrl(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
      end
      begin : wait_for_low_gate
        wait_cycles = 0;
        while ((ppu_top_vif.nvbl_out !== 1'b0) && (wait_cycles < 2000)) begin
          @(ppu_top_vif.mon_cb);
          wait_cycles++;
        end
        if (ppu_top_vif.nvbl_out !== 1'b0)
          `uvm_error("PPU_TOP_VBL", "Expected /VBL to go low after enabling NMI during active vblank")
      end
    join

    write_ppuaddr_data(14'h3f02, {2'b00, gated_idx});

    fork
      begin : disable_nmi_during_vblank
        repeat (8) @(ppu_top_vif.mon_cb);
        write_ppuctrl(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
      end
      begin : wait_for_high_gate
        wait_cycles = 0;
        while ((ppu_top_vif.nvbl_out !== 1'b1) && (wait_cycles < 2000)) begin
          @(ppu_top_vif.mon_cb);
          wait_cycles++;
        end
        if (ppu_top_vif.nvbl_out !== 1'b1)
          `uvm_error("PPU_TOP_VBL", "Expected /VBL to return high after clearing NMI enable during same vblank interval")
        else
          `uvm_info("PPU_TOP_VBL", "Observed /VBL gate respond to live NMI enable/disable toggles", UVM_LOW)
      end
    join
  endtask

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this, "Starting full PPU integration test");
    `uvm_info("PPU_TOP_TEST", ">>> START: ppu_full_integration_test <<<", UVM_NONE)

    #220ns;
    tc_initial_reset_observe();
    tc_palette_path_to_vga();
    tc_live_palette_update_during_visible();
    tc_sprite_arbiter();
    tc_sprite_overflow_top();
    tc_vblank_gate();
    tc_vblank_enable_disable_race();

    #200ns;
    `uvm_info("PPU_TOP_TEST", ">>> DONE: ppu_full_integration_test <<<", UVM_NONE)
    phase.drop_objection(this, "Finished full PPU integration test");
  endtask
endclass
