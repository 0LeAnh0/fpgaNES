`ifndef NES_WRAM_VRAM_CFG_SV
`define NES_WRAM_VRAM_CFG_SV

// Configuration object for WRAM/VRAM verification block.
class nes_wram_vram_cfg extends uvm_object;
    `uvm_object_utils(nes_wram_vram_cfg)

    bit enable_block;
    bit enable_file_log;
    bit check_initial_reset;
    bit check_random_reset;
    int unsigned random_reset_pulses;
    int unsigned timeout_ms;
    int unsigned random_iters;
    bit verbose_case_header;

    function new(string name = "nes_wram_vram_cfg");
        super.new(name);
        set_regression_defaults();
    endfunction

    function void set_smoke_defaults();
        enable_block         = 1;
        enable_file_log      = 0;
        check_initial_reset  = 1;
        check_random_reset   = 0;
        random_reset_pulses  = 1;
        timeout_ms           = 50;
        random_iters         = 16;
        verbose_case_header  = 1;
    endfunction

    function void set_regression_defaults();
        enable_block         = 1;
        enable_file_log      = 0;
        check_initial_reset  = 1;
        check_random_reset   = 1;
        random_reset_pulses  = 3;
        timeout_ms           = 500;
        random_iters         = 64;
        verbose_case_header  = 1;
    endfunction

    function void set_signoff_defaults();
        enable_block         = 1;
        enable_file_log      = 0;
        check_initial_reset  = 1;
        check_random_reset   = 1;
        random_reset_pulses  = 8;
        timeout_ms           = 150;
        random_iters         = 256;
        verbose_case_header  = 1;
    endfunction
endclass

`endif
