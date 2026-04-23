`ifndef TB_CTRL_IF_SV
`define TB_CTRL_IF_SV

interface tb_ctrl_if(input logic clk_in);
    // Active-high reset request wired to DUT BTN_SOUTH.
    logic rst_req;

    // Optional helper clocking block for test-side synchronization.
    clocking ctrl_cb @(posedge clk_in);
        default input #1ns output #1ns;
        output rst_req;
    endclocking

    // Task thuc hien Reset ban dau (Initial Reset)
    // Tu dong keo rst_req len cao roi ha xuong sau mot khoang thoi gian
    task initial_reset(int duration_ns = 100);
        rst_req = 1'b1;
        #(duration_ns * 1ns);
        rst_req = 1'b0;
    endtask

    // Task thuc hien Reset ngau nhien (Random Reset)
    // Rat huu ich de kiem tra do ben cua thiet ke khi bi Reset bat thinh linh
    task random_reset(int min_delay_ns = 50, int max_delay_ns = 200, int duration_ns = 50);
        int delay;
        delay = $urandom_range(min_delay_ns, max_delay_ns);
        #(delay * 1ns); // Cho mot khoang ngau nhien
        rst_req = 1'b1; // Keo reset
        #(duration_ns * 1ns);
        rst_req = 1'b0; // Nha reset
    endtask
endinterface

`endif
