`ifndef PPU_BG_SEQUENCES_SV
`define PPU_BG_SEQUENCES_SV

class ppu_bg_base_sequence extends uvm_sequence #(ppu_bg_sequence_item);
  `uvm_object_utils(ppu_bg_base_sequence)

  function new(string name = "ppu_bg_base_sequence");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    if (starting_phase != null) begin
      starting_phase.raise_objection(this);
    end
  endtask

  virtual task post_body();
    if (starting_phase != null) begin
      starting_phase.drop_objection(this);
    end
  endtask
endclass

class ppu_bg_sanity_sequence extends ppu_bg_base_sequence;
  `uvm_object_utils(ppu_bg_sanity_sequence)

  function new(string name = "ppu_bg_sanity_sequence");
    super.new(name);
  endfunction

  virtual task body();
    repeat(10) begin
      req = ppu_bg_sequence_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) begin
        `uvm_error("RAND", "Randomization failed")
      end
      // Override some variables for simple sanity
      req.en_in = 1;
      req.nes_y_in = 0;
      req.nes_y_next_in = 0;
      finish_item(req);
    end
  endtask
endclass

// ==============================================================================
// 1. SEQUENCE: Test RI Counter Updates and Address Increments (ri_inc_addr)
// ==============================================================================
class ppu_bg_ri_update_seq extends ppu_bg_base_sequence;
  `uvm_object_utils(ppu_bg_ri_update_seq)

  function new(string name = "ppu_bg_ri_update_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("SEQ", "Starting RI Update Sequence", UVM_LOW)
    // 1. Set latches and trigger upd_cntrs
    req = ppu_bg_sequence_item::type_id::create("req");
    start_item(req);
    void'(req.randomize());
    req.fv_in = 3'b101;
    req.vt_in = 5'b10101;
    req.v_in = 1;
    req.ht_in = 5'b01010;
    req.h_in = 0;
    req.ri_upd_cntrs_in = 1; // triggers load
    req.ri_inc_addr_in = 0;
    finish_item(req);

    // 2. Increment address by 1
    repeat(5) begin
      req = ppu_bg_sequence_item::type_id::create("req");
      start_item(req);
      void'(req.randomize() with {
        en_in == 0;
        ri_upd_cntrs_in == 0;
        ri_inc_addr_in == 1;
        ri_inc_addr_amt_in == 0; // inc by 1
      });
      finish_item(req);
    end
    
    // 3. Increment address by 32
    repeat(5) begin
      req = ppu_bg_sequence_item::type_id::create("req");
      start_item(req);
      void'(req.randomize() with {
        en_in == 0;
        ri_upd_cntrs_in == 0;
        ri_inc_addr_in == 1;
        ri_inc_addr_amt_in == 1; // inc by 32
      });
      finish_item(req);
    end
  endtask
endclass

// ==============================================================================
// 2. SEQUENCE: Test Background Rendering Fetching Cycle (NT -> AT -> PT0 -> PT1)
// ==============================================================================
class ppu_bg_render_fetch_seq extends ppu_bg_base_sequence;
  `uvm_object_utils(ppu_bg_render_fetch_seq)

  function new(string name = "ppu_bg_render_fetch_seq");
    super.new(name);
  endfunction

  // Sequence kiem tra chu ky rut du lieu tu VRAM de hien thi hinh nen
  virtual task body();
    `uvm_info("SEQ", "Starting Render Fetch Sequence (NT->AT->PT0->PT1)", UVM_LOW)
    
    // Mo phong 1 dong quet (Scanline): Cho X chay tu 0 den 31 (ung voi 32 o gach Tile)
    for (int i = 0; i < 32; i++) begin
      // Buoc 1: Pix_pulse len cao (Gia lap nhip clock tich cuc cua PPU)
      req = ppu_bg_sequence_item::type_id::create("req");
      start_item(req);
      req.en_in = 1;         // Bat che do ve Background
      req.nes_y_in = 10;
      req.nes_y_next_in = 10;
      req.nes_x_in = i;
      req.pix_pulse_in = 1;  // Xung kich hoat fetching
      
      // Gia lap du lieu VRAM tra ve. Moi nhip BG se hut data tu RAM qua cong nay
      req.vram_d_in = i;     
      
      req.ri_upd_cntrs_in = 0;
      req.ri_inc_addr_in = 0;
      finish_item(req);
      
      // Buoc 2: Pix_pulse xuong thap (Ket thuc 1 nhip pixel)
      req = ppu_bg_sequence_item::type_id::create("req");
      start_item(req);
      req.en_in = 1;
      req.nes_y_in = 10;
      req.nes_y_next_in = 10;
      req.nes_x_in = i;
      req.pix_pulse_in = 0;
      req.vram_d_in = i;
      req.ri_upd_cntrs_in = 0;
      req.ri_inc_addr_in = 0;
      finish_item(req);
    end
  endtask
endclass

// ==============================================================================
// 3. SEQUENCE: Full Scanline Sequence (0 to 340)
// ==============================================================================
class ppu_bg_full_scanline_seq extends ppu_bg_base_sequence;
  `uvm_object_utils(ppu_bg_full_scanline_seq)

  rand int num_scanlines;
  constraint c_num { num_scanlines inside {[1:3]}; }

  function new(string name = "ppu_bg_full_scanline_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("SEQ", $sformatf("Starting Full Scanline Seq for %0d lines", num_scanlines), UVM_LOW)
    
    for (int line = 0; line < num_scanlines; line++) begin
      for (int dot = 0; dot < 341; dot++) begin
        req = ppu_bg_sequence_item::type_id::create("req");
        start_item(req);
        req.en_in = 1;
        req.nes_x_in = dot;
        req.nes_y_in = 10 + line;
        req.nes_y_next_in = (dot == 319) ? (10 + line + 1) : (10+line);
        req.pix_pulse_in = 1;
        req.vram_d_in = $urandom & 8'hFF;
        finish_item(req);

        // Low pulse
        start_item(req);
        req.pix_pulse_in = 0;
        finish_item(req);
      end
    end
  endtask
endclass

// ==============================================================================
// 4. SEQUENCE: Stress Scroll Wrap Sequence
// ==============================================================================
class ppu_bg_stress_scroll_seq extends ppu_bg_base_sequence;
  `uvm_object_utils(ppu_bg_stress_scroll_seq)

  function new(string name = "ppu_bg_stress_scroll_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("SEQ", "Starting Stress Scroll Seq", UVM_LOW)
    
    // Test Horizontal Wrap (HT 31 -> 0, H flip)
    req = ppu_bg_sequence_item::type_id::create("req");
    start_item(req);
    req.randomize();
    req.ht_in = 5'd31; // Max HT
    req.h_in  = 0;
    req.ri_upd_cntrs_in = 1;
    finish_item(req);

    // Trigger increments to see wrap
    repeat(16) begin
      start_item(req);
      req.ri_upd_cntrs_in = 0;
      req.ri_inc_addr_in  = 1;
      req.ri_inc_addr_amt_in = 0; // inc by 1
      finish_item(req);
    end

    // Test Vertical Wrap (VT 29 -> 0, V flip)
    start_item(req);
    req.vt_in = 5'd29;
    req.v_in = 0;
    req.ri_upd_cntrs_in = 1;
    req.ri_inc_addr_in = 0;
    finish_item(req);

    repeat(10) begin
       start_item(req);
       req.ri_upd_cntrs_in = 0;
       req.ri_inc_addr_in = 1;
       req.ri_inc_addr_amt_in = 1; // inc by 32 (increments VT)
       finish_item(req);
    end
  endtask
endclass

// ==============================================================================
// 5. SEQUENCE: Targeted Coverage Sequence for VBlank/Pre-render and Scroll Corners
// ==============================================================================
class ppu_bg_cov_target_seq extends ppu_bg_base_sequence;
  `uvm_object_utils(ppu_bg_cov_target_seq)

  function new(string name = "ppu_bg_cov_target_seq");
    super.new(name);
  endfunction

  protected task drive_sample(
    bit        en_in,
    bit        ls_clip_in,
    bit        s_in,
    bit [2:0]  fh_in,
    bit [2:0]  fv_in,
    bit [4:0]  ht_in,
    bit [4:0]  vt_in,
    bit        v_in,
    bit        h_in,
    int        nes_x_in,
    int        nes_y_in,
    int        nes_y_next_in,
    bit [7:0]  vram_d_in
  );
    req = ppu_bg_sequence_item::type_id::create("req");
    start_item(req);
    req.en_in         = en_in;
    req.ls_clip_in    = ls_clip_in;
    req.s_in          = s_in;
    req.fh_in         = fh_in;
    req.fv_in         = fv_in;
    req.ht_in         = ht_in;
    req.vt_in         = vt_in;
    req.v_in          = v_in;
    req.h_in          = h_in;
    req.nes_x_in      = nes_x_in;
    req.nes_y_in      = nes_y_in;
    req.nes_y_next_in = nes_y_next_in;
    req.pix_pulse_in  = 1'b1;
    req.vram_d_in     = vram_d_in;
    req.ri_upd_cntrs_in = 1'b0;
    req.ri_inc_addr_in  = 1'b0;
    finish_item(req);

    start_item(req);
    req.pix_pulse_in = 1'b0;
    finish_item(req);
  endtask

  virtual task body();
    int y_samples[$] = '{0, 239, 240, 250, 261};
    int x_samples[$] = '{0, 7, 255, 256, 320, 340};

    `uvm_info("SEQ", "Starting BG targeted coverage sequence", UVM_LOW)

    foreach (y_samples[y_idx]) begin
      foreach (x_samples[x_idx]) begin
        drive_sample(
          1'b1, 1'b0,
          y_idx[0],
          (x_idx * 3) % 8,
          (y_idx * 2) % 8,
          (x_idx == 0) ? 5'd0 : 5'd31,
          (y_idx < 2) ? 5'd0 : 5'd29,
          y_idx[0],
          x_idx[0],
          x_samples[x_idx],
          y_samples[y_idx],
          (x_samples[x_idx] == 340) ? ((y_samples[y_idx] == 261) ? 0 : (y_samples[y_idx] + 1)) : y_samples[y_idx],
          8'hFF
        );

        drive_sample(
          1'b1, 1'b1,
          ~y_idx[0],
          3'd0,
          3'd7,
          5'd31,
          5'd29,
          ~y_idx[0],
          ~x_idx[0],
          (x_samples[x_idx] < 8) ? x_samples[x_idx] : 7,
          y_samples[y_idx],
          (x_samples[x_idx] == 340) ? ((y_samples[y_idx] == 261) ? 0 : (y_samples[y_idx] + 1)) : y_samples[y_idx],
          8'h00
        );
      end
    end
  endtask
endclass

`endif
