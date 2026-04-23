`ifndef PPU_BG_SCOREBOARD_SV
`define PPU_BG_SCOREBOARD_SV

class ppu_bg_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ppu_bg_scoreboard)

  uvm_tlm_analysis_fifo #(ppu_bg_sequence_item) master_fifo;
  uvm_tlm_analysis_fifo #(ppu_bg_sequence_item) slave_fifo;

  logic [ 2:0] q_fvc;
  logic [ 4:0] q_vtc;
  logic        q_vc;
  logic [ 4:0] q_htc;
  logic        q_hc;
  logic [ 7:0] q_par;
  logic [ 1:0] q_ar;
  logic [ 7:0] q_pd0;
  logic [ 7:0] q_pd1;
  logic [ 8:0] q_bg_bit3_shift;
  logic [ 8:0] q_bg_bit2_shift;
  logic [15:0] q_bg_bit1_shift;
  logic [15:0] q_bg_bit0_shift;

  int unsigned checks_passed;
  int unsigned checks_failed;

  function new(string name = "ppu_bg_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    master_fifo = new("master_fifo", this);
    slave_fifo  = new("slave_fifo", this);
    reset_model();
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_bg_sequence_item item;

    forever begin
      master_fifo.get(item);
      process_item(item);
    end
  endtask

  protected function void reset_model();
    q_fvc           = 3'h0;
    q_vtc           = 5'h00;
    q_vc            = 1'b0;
    q_htc           = 5'h00;
    q_hc            = 1'b0;
    q_par           = 8'h00;
    q_ar            = 2'h0;
    q_pd0           = 8'h00;
    q_pd1           = 8'h00;
    q_bg_bit3_shift = 9'h000;
    q_bg_bit2_shift = 9'h000;
    q_bg_bit1_shift = 16'h0000;
    q_bg_bit0_shift = 16'h0000;
  endfunction

  protected task process_item(ppu_bg_sequence_item item);
    if (item.rst_in) begin
      reset_model();
      return;
    end

    check_outputs(item);
    update_model(item);
  endtask

  protected task update_model(ppu_bg_sequence_item item);
    logic [ 2:0] d_fvc;
    logic [ 4:0] d_vtc;
    logic        d_vc;
    logic [ 4:0] d_htc;
    logic        d_hc;
    logic [ 7:0] d_par;
    logic [ 1:0] d_ar;
    logic [ 7:0] d_pd0;
    logic [ 7:0] d_pd1;
    logic [ 8:0] d_bg_bit3_shift;
    logic [ 8:0] d_bg_bit2_shift;
    logic [15:0] d_bg_bit1_shift;
    logic [15:0] d_bg_bit0_shift;
    bit upd_v_cntrs;
    bit upd_h_cntrs;
    bit inc_v_cntrs;
    bit inc_h_cntrs;

    d_fvc           = q_fvc;
    d_vtc           = q_vtc;
    d_vc            = q_vc;
    d_htc           = q_htc;
    d_hc            = q_hc;
    d_par           = q_par;
    d_ar            = q_ar;
    d_pd0           = q_pd0;
    d_pd1           = q_pd1;
    d_bg_bit3_shift = q_bg_bit3_shift;
    d_bg_bit2_shift = q_bg_bit2_shift;
    d_bg_bit1_shift = q_bg_bit1_shift;
    d_bg_bit0_shift = q_bg_bit0_shift;

    upd_v_cntrs = 1'b0;
    upd_h_cntrs = 1'b0;
    inc_v_cntrs = 1'b0;
    inc_h_cntrs = 1'b0;

    if (item.ri_inc_addr_in) begin
      if (item.ri_inc_addr_amt_in)
        { d_fvc, d_vc, d_hc, d_vtc } = { q_fvc, q_vc, q_hc, q_vtc } + 10'h001;
      else
        { d_fvc, d_vc, d_hc, d_vtc, d_htc } = { q_fvc, q_vc, q_hc, q_vtc, q_htc } + 15'h0001;
    end else begin
      if (item.en_in && ((item.nes_y_in < 239) || (item.nes_y_next_in == 0))) begin
        if (item.pix_pulse_in && (item.nes_x_in == 319)) begin
          upd_h_cntrs = 1'b1;

          if (item.nes_y_next_in != item.nes_y_in) begin
            if (item.nes_y_next_in == 0)
              upd_v_cntrs = 1'b1;
            else
              inc_v_cntrs = 1'b1;
          end
        end

        if ((item.nes_x_in < 256) || ((item.nes_x_in >= 320) && (item.nes_x_in < 336))) begin
          if (item.pix_pulse_in) begin
            d_bg_bit3_shift = { q_bg_bit3_shift[8], q_bg_bit3_shift[8:1] };
            d_bg_bit2_shift = { q_bg_bit2_shift[8], q_bg_bit2_shift[8:1] };
            d_bg_bit1_shift = { 1'b0, q_bg_bit1_shift[15:1] };
            d_bg_bit0_shift = { 1'b0, q_bg_bit0_shift[15:1] };
          end

          if (item.pix_pulse_in && (item.nes_x_in[2:0] == 3'h7)) begin
            inc_h_cntrs = 1'b1;

            d_bg_bit3_shift[8]  = q_ar[1];
            d_bg_bit2_shift[8]  = q_ar[0];

            d_bg_bit1_shift[15] = q_pd1[0];
            d_bg_bit1_shift[14] = q_pd1[1];
            d_bg_bit1_shift[13] = q_pd1[2];
            d_bg_bit1_shift[12] = q_pd1[3];
            d_bg_bit1_shift[11] = q_pd1[4];
            d_bg_bit1_shift[10] = q_pd1[5];
            d_bg_bit1_shift[ 9] = q_pd1[6];
            d_bg_bit1_shift[ 8] = q_pd1[7];

            d_bg_bit0_shift[15] = q_pd0[0];
            d_bg_bit0_shift[14] = q_pd0[1];
            d_bg_bit0_shift[13] = q_pd0[2];
            d_bg_bit0_shift[12] = q_pd0[3];
            d_bg_bit0_shift[11] = q_pd0[4];
            d_bg_bit0_shift[10] = q_pd0[5];
            d_bg_bit0_shift[ 9] = q_pd0[6];
            d_bg_bit0_shift[ 8] = q_pd0[7];
          end

          case (item.nes_x_in[2:0])
            3'b000: d_par = item.vram_d_in;
            3'b001: d_ar  = item.vram_d_in >> { q_vtc[1], q_htc[1], 1'b0 };
            3'b010: d_pd0 = item.vram_d_in;
            3'b011: d_pd1 = item.vram_d_in;
            default: begin end
          endcase
        end
      end

      if (inc_v_cntrs) begin
        if ({ q_vtc, q_fvc } == { 5'b1_1101, 3'b111 })
          { d_vc, d_vtc, d_fvc } = { ~q_vc, 8'h00 };
        else
          { d_vc, d_vtc, d_fvc } = { q_vc, q_vtc, q_fvc } + 9'h001;
      end

      if (inc_h_cntrs)
        { d_hc, d_htc } = { q_hc, q_htc } + 6'h01;

      if (upd_v_cntrs || item.ri_upd_cntrs_in) begin
        d_vc  = item.v_in;
        d_vtc = item.vt_in;
        d_fvc = item.fv_in;
      end

      if (upd_h_cntrs || item.ri_upd_cntrs_in) begin
        d_hc  = item.h_in;
        d_htc = item.ht_in;
      end
    end

    q_fvc           = d_fvc;
    q_vtc           = d_vtc;
    q_vc            = d_vc;
    q_htc           = d_htc;
    q_hc            = d_hc;
    q_par           = d_par;
    q_ar            = d_ar;
    q_pd0           = d_pd0;
    q_pd1           = d_pd1;
    q_bg_bit3_shift = d_bg_bit3_shift;
    q_bg_bit2_shift = d_bg_bit2_shift;
    q_bg_bit1_shift = d_bg_bit1_shift;
    q_bg_bit0_shift = d_bg_bit0_shift;
  endtask

  protected task check_outputs(ppu_bg_sequence_item item);
    logic [13:0] exp_vram_a;
    logic [ 3:0] exp_palette_idx;
    bit          clip;

    exp_vram_a = { q_fvc[1:0], q_vc, q_hc, q_vtc, q_htc };
    if (item.en_in && ((item.nes_y_in < 239) || (item.nes_y_next_in == 0))) begin
      if ((item.nes_x_in < 256) || ((item.nes_x_in >= 320) && (item.nes_x_in < 336))) begin
        case (item.nes_x_in[2:0])
          3'b000: exp_vram_a = { 2'b10, q_vc, q_hc, q_vtc, q_htc };
          3'b001: exp_vram_a = { 2'b10, q_vc, q_hc, 4'b1111, q_vtc[4:2], q_htc[4:2] };
          3'b010: exp_vram_a = { 1'b0, item.s_in, q_par, 1'b0, q_fvc };
          3'b011: exp_vram_a = { 1'b0, item.s_in, q_par, 1'b1, q_fvc };
          default: begin end
        endcase
      end
    end

    clip = item.ls_clip_in && (item.nes_x_in < 8);
    if (!clip && item.en_in)
      exp_palette_idx = { q_bg_bit3_shift[item.fh_in], q_bg_bit2_shift[item.fh_in],
                          q_bg_bit1_shift[item.fh_in], q_bg_bit0_shift[item.fh_in] };
    else
      exp_palette_idx = 4'h0;

    if (item.vram_a_out !== exp_vram_a) begin
      checks_failed++;
      `uvm_error("SCB_ADDR_MISMATCH",
        $sformatf("X=%0d Y=%0d mismatch exp=%04h act=%04h",
          item.nes_x_in, item.nes_y_in, exp_vram_a, item.vram_a_out))
    end else begin
      checks_passed++;
    end

    if (item.palette_idx_out !== exp_palette_idx) begin
      checks_failed++;
      `uvm_error("SCB_BG_PIXEL_MISMATCH",
        $sformatf("X=%0d Y=%0d palette mismatch exp=%0h act=%0h",
          item.nes_x_in, item.nes_y_in, exp_palette_idx, item.palette_idx_out))
    end else begin
      checks_passed++;
    end
  endtask

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("BG_SCB_RPT",
      $sformatf("Background scoreboard summary: PASS=%0d FAIL=%0d", checks_passed, checks_failed),
      UVM_LOW)
  endfunction

endclass

`endif
