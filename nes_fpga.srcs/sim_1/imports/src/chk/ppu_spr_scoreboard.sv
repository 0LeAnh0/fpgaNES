`ifndef PPU_SPR_SCOREBOARD_SV
`define PPU_SPR_SCOREBOARD_SV

class ppu_spr_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ppu_spr_scoreboard)

  uvm_tlm_analysis_fifo #(ppu_spr_sequence_item) master_fifo;
  uvm_tlm_analysis_fifo #(ppu_spr_sequence_item) slave_fifo;

  // Mirror State
  logic [ 7:0] m_oam [255:0];
  logic [24:0] m_stm [7:0];
  logic [27:0] m_sbm [7:0];

  logic [3:0] q_in_rng_cnt;
  logic       q_spr_overflow;
  logic [7:0] q_pd0;
  logic [7:0] q_pd1;

  logic [7:0] q_obj_pd1_shift [7:0];
  logic [7:0] q_obj_pd0_shift [7:0];

  int unsigned checks_passed;
  int unsigned checks_failed;

  function new(string name = "ppu_spr_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    master_fifo = new("master_fifo", this);
    slave_fifo  = new("slave_fifo", this);

    reset_all_state();
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_spr_sequence_item item;

    forever begin
      master_fifo.get(item);
      process_item(item);
    end
  endtask

  function logic [7:0] bit_rev(logic [7:0] value);
    return { value[0], value[1], value[2], value[3],
             value[4], value[5], value[6], value[7] };
  endfunction

  protected function void reset_runtime_state();
    q_in_rng_cnt   = 4'h0;
    q_spr_overflow = 1'b0;
    q_pd0          = 8'h00;
    q_pd1          = 8'h00;
    for (int i = 0; i < 8; i++) begin
      m_stm[i] = 25'h0;
      m_sbm[i] = 28'h0;
      q_obj_pd1_shift[i] = 8'h00;
      q_obj_pd0_shift[i] = 8'h00;
    end
  endfunction

  protected function void reset_all_state();
    for (int i = 0; i < 256; i++) begin
      m_oam[i] = 8'h00;
    end

    reset_runtime_state();
  endfunction

  protected task process_item(ppu_spr_sequence_item item);
    if (item.rst_in) begin
      reset_runtime_state();
      return;
    end

    check_outputs(item);
    update_model(item);
  endtask

  protected task update_model(ppu_spr_sequence_item item);
    logic [3:0] d_in_rng_cnt;
    logic       d_spr_overflow;
    logic [7:0] d_pd0;
    logic [7:0] d_pd1;
    logic [7:0] next_obj_pd1_shift [7:0];
    logic [7:0] next_obj_pd0_shift [7:0];

    if (item.oam_wr_in) begin
      m_oam[item.oam_a_in] = item.oam_d_in;
    end

    d_in_rng_cnt = q_in_rng_cnt;
    if ((item.nes_y_next_in == 0) && (item.nes_x_in == 0))
      d_spr_overflow = 1'b0;
    else
      d_spr_overflow = q_spr_overflow || q_in_rng_cnt[3];

    if (item.en_in && item.pix_pulse_in && (item.nes_y_next_in < 239)) begin
      if (item.nes_x_in == 320) begin
        d_in_rng_cnt = 4'h0;
      end else if ((item.nes_x_in < 256) && (item.nes_x_in[1:0] == 2'h0) && !q_in_rng_cnt[3]) begin
        logic [5:0] idx;
        logic [7:0] y_coord;
        logic [8:0] rng_cmp_res;
        logic       in_rng;
        logic [24:0] stm_din;

        idx         = item.nes_x_in[7:2];
        y_coord     = m_oam[{idx, 2'b00}] + 8'h01;
        rng_cmp_res = item.nes_y_next_in - y_coord;
        in_rng      = (~|rng_cmp_res[8:4]) & (~rng_cmp_res[3] | item.spr_h_in);

        if (in_rng) begin
          stm_din[24]    = ~|idx;
          stm_din[23:16] = m_oam[{idx, 2'b01}];
          stm_din[15: 8] = m_oam[{idx, 2'b11}];
          stm_din[ 7: 6] = m_oam[{idx, 2'b10}][1:0];
          stm_din[    5] = m_oam[{idx, 2'b10}][5];
          stm_din[    4] = m_oam[{idx, 2'b10}][6];
          stm_din[ 3: 0] = m_oam[{idx, 2'b10}][7] ? ~rng_cmp_res[3:0] : rng_cmp_res[3:0];

          m_stm[q_in_rng_cnt[2:0]] = stm_din;
          d_in_rng_cnt = q_in_rng_cnt + 4'h1;
        end
      end
    end

    q_in_rng_cnt   = d_in_rng_cnt;
    q_spr_overflow = d_spr_overflow;

    d_pd0 = q_pd0;
    d_pd1 = q_pd1;

    if (item.en_in && (item.nes_y_next_in < 239) && (item.nes_x_in >= 256) && (item.nes_x_in < 320)) begin
      logic [2:0]  stm_rd_idx;
      logic [24:0] stm_entry;

      stm_rd_idx = item.nes_x_in[5:3];
      stm_entry  = m_stm[stm_rd_idx];

      if (stm_rd_idx < q_in_rng_cnt) begin
        case (item.nes_x_in[2:1])
          2'h0: d_pd0 = stm_entry[4] ? item.vram_d_in : bit_rev(item.vram_d_in);
          2'h1: d_pd1 = stm_entry[4] ? item.vram_d_in : bit_rev(item.vram_d_in);
          2'h2: m_sbm[stm_rd_idx] = { stm_entry[24], stm_entry[5], stm_entry[7:6], q_pd1, q_pd0, stm_entry[15:8] };
          default: begin end
        endcase
      end else if (item.nes_x_in[2:1] == 2'h2) begin
        m_sbm[stm_rd_idx] = 28'h0000000;
      end
    end

    q_pd0 = d_pd0;
    q_pd1 = d_pd1;

    for (int i = 0; i < 8; i++) begin
      next_obj_pd1_shift[i] = q_obj_pd1_shift[i];
      next_obj_pd0_shift[i] = q_obj_pd0_shift[i];

      if (item.en_in && (item.nes_y_in < 239)) begin
        if (item.pix_pulse_in) begin
          next_obj_pd1_shift[i] = { 1'b0, q_obj_pd1_shift[i][7:1] };
          next_obj_pd0_shift[i] = { 1'b0, q_obj_pd0_shift[i][7:1] };
        end else if ((item.nes_x_in - m_sbm[i][7:0]) == 8'h00) begin
          next_obj_pd1_shift[i] = m_sbm[i][23:16];
          next_obj_pd0_shift[i] = m_sbm[i][15:8];
        end
      end
    end

    for (int i = 0; i < 8; i++) begin
      q_obj_pd1_shift[i] = next_obj_pd1_shift[i];
      q_obj_pd0_shift[i] = next_obj_pd0_shift[i];
    end
  endtask

  protected task check_outputs(ppu_spr_sequence_item item);
    logic [13:0] exp_vram_a;
    logic        exp_vram_req;
    logic        exp_primary;
    logic        exp_priority;
    logic [3:0]  exp_palette;

    if (item.oam_d_out !== m_oam[item.oam_a_in]) begin
      checks_failed++;
      `uvm_error("SCB_OAM_D_MISMATCH",
        $sformatf("OAM_A=%02h mismatch exp=%02h act=%02h",
          item.oam_a_in, m_oam[item.oam_a_in], item.oam_d_out))
    end else begin
      checks_passed++;
    end

    if (item.overflow_out !== q_spr_overflow) begin
      checks_failed++;
      `uvm_error("SCB_OVERFLOW_MISMATCH",
        $sformatf("X=%0d Y=%0d overflow mismatch exp=%0b act=%0b",
          item.nes_x_in, item.nes_y_in, q_spr_overflow, item.overflow_out))
    end else begin
      checks_passed++;
    end

    exp_vram_req = 1'b0;
    exp_vram_a   = item.vram_a_out;
    if (item.en_in && (item.nes_y_next_in < 239) && (item.nes_x_in >= 256) && (item.nes_x_in < 320)) begin
      logic [2:0]  stm_rd_idx;
      logic [24:0] stm_entry;
      logic [7:0]  tile_idx;
      logic [3:0]  obj_row;

      stm_rd_idx = item.nes_x_in[5:3];
      stm_entry  = m_stm[stm_rd_idx];
      tile_idx   = stm_entry[23:16];
      obj_row    = stm_entry[3:0];

      if (item.spr_h_in)
        exp_vram_a = { 1'b0, tile_idx[0], tile_idx[7:1], obj_row[3], item.nes_x_in[1], obj_row[2:0] };
      else
        exp_vram_a = { 1'b0, item.spr_pt_sel_in, tile_idx, item.nes_x_in[1], obj_row[2:0] };

      if ((stm_rd_idx < q_in_rng_cnt) && ((item.nes_x_in[2:1] == 2'h0) || (item.nes_x_in[2:1] == 2'h1)))
        exp_vram_req = 1'b1;
    end

    if (item.vram_req_out !== exp_vram_req) begin
      checks_failed++;
      `uvm_error("SCB_VRAM_REQ_MISMATCH",
        $sformatf("X=%0d Y=%0d req mismatch exp=%0b act=%0b",
          item.nes_x_in, item.nes_y_in, exp_vram_req, item.vram_req_out))
    end else begin
      checks_passed++;
    end

    if (exp_vram_req && (item.vram_a_out !== exp_vram_a)) begin
      checks_failed++;
      `uvm_error("SCB_VRAM_ADDR_MISMATCH",
        $sformatf("X=%0d Y=%0d addr mismatch exp=%04h act=%04h",
          item.nes_x_in, item.nes_y_in, exp_vram_a, item.vram_a_out))
    end else if (exp_vram_req) begin
      checks_passed++;
    end

    exp_primary  = 1'b0;
    exp_priority = 1'b0;
    exp_palette  = 4'h0;

    if (item.en_in && !(item.ls_clip_in && (item.nes_x_in < 8))) begin
      for (int i = 0; i < 8; i++) begin
        if ({ q_obj_pd1_shift[i][0], q_obj_pd0_shift[i][0] } != 0) begin
          exp_primary  = m_sbm[i][27];
          exp_priority = m_sbm[i][26];
          exp_palette  = { m_sbm[i][25:24], q_obj_pd1_shift[i][0], q_obj_pd0_shift[i][0] };
          break;
        end
      end
    end

    if (item.palette_idx_out !== exp_palette) begin
      checks_failed++;
      `uvm_error("SCB_PALETTE_MISMATCH",
        $sformatf("X=%0d Y=%0d palette mismatch exp=%0h act=%0h",
          item.nes_x_in, item.nes_y_in, exp_palette, item.palette_idx_out))
    end else begin
      checks_passed++;
    end

    if (item.primary_out !== exp_primary) begin
      checks_failed++;
      `uvm_error("SCB_PRIMARY_MISMATCH",
        $sformatf("X=%0d Y=%0d primary mismatch exp=%0b act=%0b",
          item.nes_x_in, item.nes_y_in, exp_primary, item.primary_out))
    end else begin
      checks_passed++;
    end

    if (item.priority_out !== exp_priority) begin
      checks_failed++;
      `uvm_error("SCB_PRIORITY_MISMATCH",
        $sformatf("X=%0d Y=%0d priority mismatch exp=%0b act=%0b",
          item.nes_x_in, item.nes_y_in, exp_priority, item.priority_out))
    end else begin
      checks_passed++;
    end
  endtask

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SPR_SCB_RPT",
      $sformatf("Sprite scoreboard summary: PASS=%0d FAIL=%0d", checks_passed, checks_failed),
      UVM_LOW)
  endfunction

endclass

`endif
