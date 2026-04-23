`ifndef PPU_SPR_SEQUENCES_SV
`define PPU_SPR_SEQUENCES_SV

// Base sequence
class ppu_spr_base_seq extends uvm_sequence #(ppu_spr_sequence_item);
  `uvm_object_utils(ppu_spr_base_seq)

  function new(string name = "ppu_spr_base_seq");
    super.new(name);
  endfunction

endclass

// Sanity sequence: Write some OAM, run a few scanlines
class ppu_spr_sanity_seq extends ppu_spr_base_seq;
  `uvm_object_utils(ppu_spr_sanity_seq)

  function new(string name = "ppu_spr_sanity_seq");
    super.new(name);
  endfunction

  virtual task body();
    // 1. Initialize OAM via Master Driver
    for (int i=0; i<32; i++) begin
       `uvm_create(req)
       req.oam_wr_in = 1;
       req.oam_a_in  = i;
       req.oam_d_in  = $urandom_range(0, 255);
       req.en_in     = 0;
       `uvm_send(req)
    end

    // 2. Run simulation cycles (Scanline rhythm)
    for (int y=0; y<10; y++) begin
       for (int x=0; x<341; x++) begin
          bit [7:0] vram_sample;
          bit       clip_sample;
          bit       pt_sel_sample;

          vram_sample = ($urandom_range(0, 3) == 0) ? 8'h00 : $urandom_range(1, 255);
          clip_sample = $urandom_range(0, 1);
          pt_sel_sample = $urandom_range(0, 1);

          `uvm_create(req)
          req.en_in         = 1;
          req.ls_clip_in    = clip_sample;
          req.spr_pt_sel_in = pt_sel_sample;
          req.nes_x_in      = x;
          req.nes_y_in      = y;
          req.nes_y_next_in = (x == 340) ? y + 1 : y;
          req.pix_pulse_in  = 1;
          req.vram_d_in     = vram_sample;
          req.oam_wr_in     = 0;
          `uvm_send(req)

          `uvm_create(req)
          req.en_in         = 1;
          req.ls_clip_in    = clip_sample;
          req.spr_pt_sel_in = pt_sel_sample;
          req.nes_x_in      = x;
          req.nes_y_in      = y;
          req.nes_y_next_in = (x == 340) ? y + 1 : y;
          req.pix_pulse_in  = 0;
          req.vram_d_in     = vram_sample;
          req.oam_wr_in     = 0;
          `uvm_send(req)
       end
    end
  endtask
endclass

// OAM Read/Write Stress Sequence
class ppu_spr_oam_seq extends ppu_spr_base_seq;
  `uvm_object_utils(ppu_spr_oam_seq)

  function new(string name = "ppu_spr_oam_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [7:0] shadow_oam [256];

    `uvm_info("OAM_SEQ", "Starting OAM R/W Stress Sequence", UVM_LOW)

    // 1. Write phase: Fill all 256 entries with weighted distribution
    for (int i = 0; i < 256; i++) begin
      `uvm_do_with(req, {
        oam_wr_in == 1;
        // Focus on boundary conditions for coverage: 0, 255, and random mid-range
        oam_a_in dist { 0 := 20, [1:254] := 60, 255 := 20 };
        en_in     == 0; 
      })
      shadow_oam[req.oam_a_in] = req.oam_d_in;
    end

    // 2. Read phase: Check random entries
    for (int i = 0; i < 256; i++) begin
      `uvm_do_with(req, {
        oam_wr_in == 0;
        oam_a_in dist { 0 := 20, [1:254] := 60, 255 := 20 };
        en_in     == 0;
      })
    end
    
    `uvm_info("OAM_SEQ", "OAM R/W Stress Sequence Completed", UVM_LOW)
  endtask
endclass

// Sprite Evaluation Sequence
class ppu_spr_eval_seq extends ppu_spr_base_seq;
  `uvm_object_utils(ppu_spr_eval_seq)

  function new(string name = "ppu_spr_eval_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("EVAL_SEQ", "Starting Sprite Evaluation Sequence", UVM_LOW)

    clear_oam();

    // 1. Setup sprites in OAM
    // Sprite 0: Y=10 (Visible on Line 11)
    // Sprite 1: Y=20 (Visible on Line 21)
    // Sprite 2: Y=10 (Visible on Line 11)
    write_oam(0, 8'h0A, 8'hAA, 8'h00, 8'h10); // Index 0, Y=10, Tile=AA
    write_oam(1, 8'h14, 8'hBB, 8'h00, 8'h20); // Index 1, Y=20, Tile=BB
    write_oam(2, 8'h0A, 8'hCC, 8'h00, 8'h30); // Index 2, Y=10, Tile=CC

    // 2. Run Scanlines to trigger evaluation
    // Evaluation for Line N happens during Line N-1 (X=0..255)
    // We check Line 11, so we must run Line 10 carefully.
    for (int y = 0; y < 30; y++) begin
      for (int x = 0; x < 341; x++) begin
        `uvm_do_with(req, {
          en_in         == 1;
          ls_clip_in    == 0;
          spr_pt_sel_in == 0;
          nes_x_in      == x;
          nes_y_in      == y;
          nes_y_next_in == (x == 340) ? y + 1 : y;
          pix_pulse_in  == 1;
          oam_wr_in     == 0;
        })
      end
    end
    
    `uvm_info("EVAL_SEQ", "Sprite Evaluation Sequence Completed", UVM_LOW)
  endtask

  // Helper task to write OAM easily
  task write_oam(bit [5:0] idx, bit [7:0] y, bit [7:0] tile, bit [7:0] attr, bit [7:0] x);
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b00}; oam_d_in == y;    en_in == 0;})
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b01}; oam_d_in == tile; en_in == 0;})
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b10}; oam_d_in == attr; en_in == 0;})
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b11}; oam_d_in == x;    en_in == 0;})
  endtask

  task clear_oam();
    for (int idx = 0; idx < 64; idx++) begin
      write_oam(idx[5:0], 8'hF0, 8'h00, 8'h00, 8'h00);
    end
  endtask
endclass

// Sprite Overflow Sequence
class ppu_spr_overflow_seq extends ppu_spr_eval_seq;
  `uvm_object_utils(ppu_spr_overflow_seq)

  bit spr_h_mode;

  function new(string name = "ppu_spr_overflow_seq");
    super.new(name);
    spr_h_mode = 1'b0;
  endfunction

  virtual task body();
    `uvm_info("OVERFLOW_SEQ", "Starting Sprite Overflow Sequence", UVM_LOW)

    clear_oam();

    // Setup 10 sprites on the same Y=10 line
    for (int i = 0; i < 10; i++) begin
      write_oam(i, 8'h0A, 8'h00 + i, 8'h00, 8'h10 + i);
    end

    // Run scanline 10 (which evaluates for 11)
    for (int y = 0; y < 15; y++) begin
      for (int x = 0; x < 341; x++) begin
        `uvm_do_with(req, {
          en_in         == 1;
          spr_h_in      == spr_h_mode;
          nes_x_in      == x;
          nes_y_in      == y;
          // The DUT evaluates "objects on the next scanline" using nes_y_next_in.
          // Keep that next-line value visible across the whole evaluation window.
          nes_y_next_in == y + 1;
          pix_pulse_in  == 1;
          oam_wr_in     == 0;
        })
      end
    end
    `uvm_info("OVERFLOW_SEQ", "Sprite Overflow Sequence Completed", UVM_LOW)
  endtask
endclass

// Sprite Rendering Sequence
class ppu_spr_render_seq extends ppu_spr_eval_seq;
  `uvm_object_utils(ppu_spr_render_seq)

  function new(string name = "ppu_spr_render_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("RENDER_SEQ", "Starting Sprite Rendering Sequence", UVM_LOW)

    clear_oam();

    // Setup overlapping sprites
    // Spr 0: Y=10, X=10, Color 1, Priority High
    // Spr 1: Y=10, X=12, Color 2, Priority Low
    write_oam(0, 8'h0A, 8'h00, 8'h00, 8'h0A); 
    write_oam(1, 8'h0A, 8'h01, 8'h20, 8'h0C); // Priority bit (bit 5) = 1

    for (int y = 0; y < 15; y++) begin
      for (int x = 0; x < 341; x++) begin
        bit [7:0] vram_sample;
        bit       clip_sample;

        vram_sample = (x % 3 == 0) ? 8'h00 : 8'hFF;
        clip_sample = (x < 8);

        `uvm_create(req)
        req.en_in         = 1;
        req.ls_clip_in    = clip_sample;
        req.spr_pt_sel_in = 0;
        req.nes_x_in      = x;
        req.nes_y_in      = y;
        req.nes_y_next_in = (x == 340) ? y + 1 : y;
        req.pix_pulse_in  = 1;
        req.oam_wr_in     = 0;
        req.vram_d_in     = vram_sample;
        `uvm_send(req)

        `uvm_create(req)
        req.en_in         = 1;
        req.ls_clip_in    = clip_sample;
        req.spr_pt_sel_in = 0;
        req.nes_x_in      = x;
        req.nes_y_in      = y;
        req.nes_y_next_in = (x == 340) ? y + 1 : y;
        req.pix_pulse_in  = 0;
        req.oam_wr_in     = 0;
        req.vram_d_in     = vram_sample;
        `uvm_send(req)
      end
    end

    // Re-run with swapped priorities so the coverage model sees both
    // primary/background combinations on the final sprite output.
    clear_oam();
    write_oam(0, 8'h0A, 8'h00, 8'h20, 8'h14); // Sprite 0 behind background
    write_oam(1, 8'h0A, 8'h01, 8'h00, 8'h16); // Sprite 1 in foreground

    for (int y = 0; y < 15; y++) begin
      for (int x = 0; x < 341; x++) begin
        bit [7:0] vram_sample;
        bit       clip_sample;

        vram_sample = (x % 5 == 0) ? 8'h00 : 8'hFF;
        clip_sample = (x < 8);

        `uvm_create(req)
        req.en_in         = 1;
        req.ls_clip_in    = clip_sample;
        req.spr_pt_sel_in = 0;
        req.nes_x_in      = x;
        req.nes_y_in      = y;
        req.nes_y_next_in = (x == 340) ? y + 1 : y;
        req.pix_pulse_in  = 1;
        req.oam_wr_in     = 0;
        req.vram_d_in     = vram_sample;
        `uvm_send(req)

        `uvm_create(req)
        req.en_in         = 1;
        req.ls_clip_in    = clip_sample;
        req.spr_pt_sel_in = 0;
        req.nes_x_in      = x;
        req.nes_y_in      = y;
        req.nes_y_next_in = (x == 340) ? y + 1 : y;
        req.pix_pulse_in  = 0;
        req.oam_wr_in     = 0;
        req.vram_d_in     = vram_sample;
        `uvm_send(req)
      end
    end
    `uvm_info("RENDER_SEQ", "Sprite Rendering Sequence Completed", UVM_LOW)
  endtask
endclass

// Complex Attributes Sequence (8x16 Mode, H-Flip, V-Flip)
class ppu_spr_complex_seq extends ppu_spr_eval_seq;
  `uvm_object_utils(ppu_spr_complex_seq)
  function new(string name = "ppu_spr_complex_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info("COMPLEX_SEQ", "Starting Complex (8x16 & Flip) Sequence with Random Constraints", UVM_LOW)

    clear_oam();

    // Scrub one scanline with all sprites out of range so SBM/shift registers
    // do not inherit stale state from an earlier sequence.
    for (int x = 0; x < 341; x++) begin
      `uvm_create(req)
      req.en_in         = 1;
      req.spr_h_in      = 1;
      req.nes_x_in      = x;
      req.nes_y_in      = 0;
      req.nes_y_next_in = (x == 340) ? 1 : 0;
      req.pix_pulse_in  = 1;
      req.oam_wr_in     = 0;
      req.vram_d_in     = 8'h00;
      `uvm_send(req)

      `uvm_create(req)
      req.en_in         = 1;
      req.spr_h_in      = 1;
      req.nes_x_in      = x;
      req.nes_y_in      = 0;
      req.nes_y_next_in = (x == 340) ? 1 : 0;
      req.pix_pulse_in  = 0;
      req.oam_wr_in     = 0;
      req.vram_d_in     = 8'h00;
      `uvm_send(req)
    end

    // Setup sprites with varying attributes
    write_oam(0, 8'h0A, 8'h00, 8'h80, 8'h10); // V-Flip
    write_oam(1, 8'h20, 8'h02, 8'h40, 8'h30); // H-Flip
    write_oam(2, 8'h40, 8'h04, 8'hC0, 8'h50); // Both Flips

    for (int y = 1; y < 100; y++) begin
      for (int x = 0; x < 341; x++) begin
        bit [7:0] vram_sample;
        vram_sample = $urandom_range(0, 255);

        `uvm_create(req)
        req.en_in         = 1;
        req.spr_h_in      = 1;
        req.nes_x_in      = x;
        req.nes_y_in      = y;
        req.nes_y_next_in = (x == 340) ? y + 1 : y;
        req.pix_pulse_in  = 1;
        req.oam_wr_in     = 0;
        req.vram_d_in     = vram_sample;
        `uvm_send(req)

        `uvm_create(req)
        req.en_in         = 1;
        req.spr_h_in      = 1;
        req.nes_x_in      = x;
        req.nes_y_in      = y;
        req.nes_y_next_in = (x == 340) ? y + 1 : y;
        req.pix_pulse_in  = 0;
        req.oam_wr_in     = 0;
        req.vram_d_in     = vram_sample;
        `uvm_send(req)
      end
    end
    `uvm_info("COMPLEX_SEQ", "Complex Sequence Completed", UVM_LOW)
  endtask
endclass

// Background traffic for Reset Stress
class ppu_spr_background_render_seq extends ppu_spr_base_seq;
  `uvm_object_utils(ppu_spr_background_render_seq)
  function new(string name = "ppu_spr_background_render_seq"); super.new(name); endfunction

  virtual task body();
    forever begin
      `uvm_do_with(req, {
        en_in        == 1;
        pix_pulse_in == 1;
        oam_wr_in    == 0;
      })
    end
  endtask
endclass

// FORCE Overflow & Priority Sequence
class ppu_spr_force_seq extends ppu_spr_base_seq;
  `uvm_object_utils(ppu_spr_force_seq)
  function new(string name = "ppu_spr_force_seq"); super.new(name); endfunction

  virtual task body();
    for (int idx = 0; idx < 64; idx++) begin
      write_oam(idx[5:0], 8'hF0, 8'h00, 8'h00, 8'h00);
    end

    // Setup 10 sprites on the same Y=10 line with Priority bit 1 (0x20)
    for (int i = 0; i < 10; i++) begin
       write_oam(i, 8'h0A, 8'h00, 8'h20, 8'h10); 
    end
    // Force traffic to stimulate overflow and priority states
    repeat(2000) begin
      `uvm_do_with(req, { 
        en_in        == 1; 
        pix_pulse_in == 1; 
        oam_wr_in    == 0;
      })
    end
  endtask
  
  task write_oam(bit [5:0] idx, bit [7:0] y, bit [7:0] tile, bit [7:0] attr, bit [7:0] x);
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b00}; oam_d_in == y;    en_in == 0;})
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b01}; oam_d_in == tile; en_in == 0;})
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b10}; oam_d_in == attr; en_in == 0;})
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b11}; oam_d_in == x;    en_in == 0;})
  endtask
endclass

// Full Frame Sequence (VBlank crossing)
class ppu_spr_full_frame_seq extends ppu_spr_base_seq;
  `uvm_object_utils(ppu_spr_full_frame_seq)
  function new(string name = "ppu_spr_full_frame_seq"); super.new(name); endfunction

  task write_oam(bit [5:0] idx, bit [7:0] y, bit [7:0] tile, bit [7:0] attr, bit [7:0] x);
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b00}; oam_d_in == y;    en_in == 0;})
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b01}; oam_d_in == tile; en_in == 0;})
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b10}; oam_d_in == attr; en_in == 0;})
    `uvm_do_with(req, {oam_wr_in == 1; oam_a_in == {idx, 2'b11}; oam_d_in == x;    en_in == 0;})
  endtask

  virtual task body();
    `uvm_info("FRAME_SEQ", "Starting Full Frame Scanline Sequence (Cross VBLANK)", UVM_LOW)

    // Put every sprite out of range first so overflow/render checks are deterministic.
    for (int idx = 0; idx < 64; idx++) begin
      write_oam(idx[5:0], 8'hF0, 8'h00, 8'h00, 8'h00);
    end

    // Setup one visible sprite to track across the frame.
    write_oam(6'd0, 8'h10, 8'hAA, 8'h00, 8'h10);

    // 262 Scanlines: 0-239 (Visible), 240 (Post), 241-260 (VBlank), 261 (Pre)
    for (int y = 0; y < 262; y++) begin
      for (int x = 0; x < 341; x++) begin
        bit [7:0] vram_sample;
        vram_sample = ($urandom_range(0, 99) < 30) ? 8'h00 : $urandom_range(1, 255);

        `uvm_create(req)
        req.en_in         = 1;
        req.nes_x_in      = x;
        req.nes_y_in      = y;
        req.nes_y_next_in = (x == 340) ? ((y == 261) ? 0 : y + 1) : y;
        req.pix_pulse_in  = 1;
        req.oam_wr_in     = 0;
        req.vram_d_in     = vram_sample;
        `uvm_send(req)

        `uvm_create(req)
        req.en_in         = 1;
        req.nes_x_in      = x;
        req.nes_y_in      = y;
        req.nes_y_next_in = (x == 340) ? ((y == 261) ? 0 : y + 1) : y;
        req.pix_pulse_in  = 0;
        req.oam_wr_in     = 0;
        req.vram_d_in     = vram_sample;
        `uvm_send(req)
      end
    end
    `uvm_info("FRAME_SEQ", "Full Frame Scanline Sequence Completed", UVM_LOW)
  endtask
endclass

`endif
