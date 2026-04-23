`ifndef PPU_RI_CFG_SV
`define PPU_RI_CFG_SV

// Configuration object for PPU RI verification block.
class ppu_ri_cfg extends uvm_object;
    `uvm_object_utils(ppu_ri_cfg)

    bit enable_block;
    bit enable_file_log;
    bit strict_ppustatus_x;
    bit strict_ppudata_buffered_read;
    bit check_initial_reset;
    bit check_random_reset;
    int unsigned random_reset_pulses;
    int unsigned random_iters;
    int unsigned timeout_ms;
    bit verbose_case_header;

    function new(string name = "ppu_ri_cfg");
        super.new(name);
        set_regression_defaults();
    endfunction

    function void set_smoke_defaults();
        enable_block                 = 1;
        enable_file_log              = 0;
        strict_ppustatus_x           = 0;
        strict_ppudata_buffered_read = 0;
        check_initial_reset          = 1;
        check_random_reset           = 0;
        random_reset_pulses          = 1;
        random_iters                 = 24;
        timeout_ms                   = 50;
        verbose_case_header          = 1;
    endfunction

    function void set_regression_defaults();
        enable_block                 = 1;
        enable_file_log              = 1;
        strict_ppustatus_x           = 1;
        strict_ppudata_buffered_read = 1;
        check_initial_reset          = 1;
        check_random_reset           = 1;
        random_reset_pulses          = 5;
        random_iters                 = 120;
        timeout_ms                   = 80;
        verbose_case_header          = 1;
    endfunction

    function void set_signoff_defaults();
        enable_block                 = 1;
        enable_file_log              = 1;
        strict_ppustatus_x           = 1;
        strict_ppudata_buffered_read = 1;
        check_initial_reset          = 1;
        check_random_reset           = 1;
        random_reset_pulses          = 10;
        random_iters                 = 400;
        timeout_ms                   = 120;
        verbose_case_header          = 1;
    endfunction
endclass

`endif
