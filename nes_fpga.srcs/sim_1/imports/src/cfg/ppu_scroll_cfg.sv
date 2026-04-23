`ifndef PPU_SCROLL_CFG_SV
`define PPU_SCROLL_CFG_SV

// Configuration object for scroll-focused verification in PPU RI.
class ppu_scroll_cfg extends uvm_object;
    `uvm_object_utils(ppu_scroll_cfg)

    bit enable_block;
    bit check_initial_reset;
    bit check_random_reset;
    int unsigned random_reset_pulses;
    int unsigned random_iters;
    bit strict_scroll_state;
    bit verbose_snapshot_log;

    function new(string name = "ppu_scroll_cfg");
        super.new(name);
        set_regression_defaults();
    endfunction

    function void set_smoke_defaults();
        enable_block         = 1;
        check_initial_reset  = 1;
        check_random_reset   = 0;
        random_reset_pulses  = 1;
        random_iters         = 20;
        strict_scroll_state  = 1;
        verbose_snapshot_log = 1;
    endfunction

    function void set_regression_defaults();
        enable_block         = 1;
        check_initial_reset  = 1;
        check_random_reset   = 1;
        random_reset_pulses  = 5;
        random_iters         = 80;
        strict_scroll_state  = 1;
        verbose_snapshot_log = 1;
    endfunction

    function void set_signoff_defaults();
        enable_block         = 1;
        check_initial_reset  = 1;
        check_random_reset   = 1;
        random_reset_pulses  = 10;
        random_iters         = 300;
        strict_scroll_state  = 1;
        verbose_snapshot_log = 1;
    endfunction
endclass

`endif
