`ifndef UART_COV_SV
`define UART_COV_SV

`uvm_analysis_imp_decl(_cmd)
`uvm_analysis_imp_decl(_evt)

class uart_cov extends uvm_component;
    `uvm_component_utils(uart_cov)

    uvm_analysis_imp_cmd #(uart_item, uart_cov) cmd_export;
    uvm_analysis_imp_evt #(uart_item, uart_cov) evt_export;

    uart_tr_kind_e sample_kind;
    bit [7:0]      sample_data;
    bit            sample_bad_parity;
    bit            sample_tx_accept;
    bit            sample_rx_empty;
    bit            sample_tx_full;

    covergroup cg_uart_cmd;
        option.per_instance = 1;
        option.get_inst_coverage = 1;
        type_option.merge_instances = 0;
        option.name = "uart_command_coverage";

        cp_kind: coverpoint sample_kind {
            bins tx_write  = {UART_CMD_TX_WRITE};
            bins rx_read   = {UART_CMD_RX_READ};
            bins inject_rx = {UART_CMD_INJECT_RX};
            bins reset_cmd = {UART_CMD_RESET};
        }

        cp_data: coverpoint sample_data iff (sample_kind inside {UART_CMD_TX_WRITE, UART_CMD_INJECT_RX}) {
            bins zero      = {8'h00};
            bins ff        = {8'hFF};
            bins stripe55  = {8'h55};
            bins stripeAA  = {8'hAA};
            bins walk1[]   = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
            bins walk0[]   = {8'hFE, 8'hFD, 8'hFB, 8'hF7, 8'hEF, 8'hDF, 8'hBF, 8'h7F};
            bins other     = default;
        }

        cp_bad_parity: coverpoint sample_bad_parity iff (sample_kind == UART_CMD_INJECT_RX) {
            bins clean = {0};
            bins bad   = {1};
        }

        cp_tx_accept: coverpoint sample_tx_accept iff (sample_kind == UART_CMD_TX_WRITE) {
            bins accepted = {1};
            bins rejected = {0};
        }

        cp_tx_full: coverpoint sample_tx_full iff (sample_kind inside {UART_CMD_TX_WRITE, UART_CMD_RX_READ}) {
            bins clear = {0};
            bins full  = {1};
        }

        cp_rx_empty: coverpoint sample_rx_empty iff (sample_kind == UART_CMD_RX_READ) {
            bins empty     = {1};
            bins not_empty = {0};
        }
    endgroup

    covergroup cg_uart_evt;
        option.per_instance = 1;
        option.get_inst_coverage = 1;
        type_option.merge_instances = 0;
        option.name = "uart_event_coverage";

        cp_evt_kind: coverpoint sample_kind {
            bins rx_data_evt    = {UART_EVT_RX_DATA};
            bins parity_err_evt = {UART_EVT_PARITY_ERR};
        }

        cp_evt_data: coverpoint sample_data iff (sample_kind == UART_EVT_RX_DATA) {
            bins zero      = {8'h00};
            bins ff        = {8'hFF};
            bins stripe55  = {8'h55};
            bins stripeAA  = {8'hAA};
            bins walk1[]   = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
            bins walk0[]   = {8'hFE, 8'hFD, 8'hFB, 8'hF7, 8'hEF, 8'hDF, 8'hBF, 8'h7F};
            bins other     = default;
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cmd_export = new("cmd_export", this);
        evt_export = new("evt_export", this);
        cg_uart_cmd = new();
        cg_uart_evt = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cg_uart_cmd.set_inst_name({get_full_name(), ".cg_uart_cmd"});
        cg_uart_evt.set_inst_name({get_full_name(), ".cg_uart_evt"});
    endfunction

    protected function void sample_common(uart_item t);
        sample_kind       = t.kind;
        sample_data       = t.data;
        sample_bad_parity = t.inject_bad_parity;
        sample_tx_accept  = t.tx_accept;
        sample_rx_empty   = t.rx_empty_snapshot;
        sample_tx_full    = t.tx_full_snapshot;
    endfunction

    function void write_cmd(uart_item t);
        sample_common(t);
        cg_uart_cmd.sample();
    endfunction

    function void write_evt(uart_item t);
        sample_common(t);
        cg_uart_evt.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        real overall_cov;
        super.report_phase(phase);
        overall_cov = (cg_uart_cmd.get_inst_coverage() + cg_uart_evt.get_inst_coverage()) / 2.0;
        `uvm_info("UART_COV", $sformatf("Overall UART Coverage = %0.2f%%", overall_cov), UVM_NONE)
        `uvm_info("UART_COV", $sformatf("  Command Coverage = %0.2f%%", cg_uart_cmd.get_inst_coverage()), UVM_NONE)
        `uvm_info("UART_COV", $sformatf("  Event Coverage = %0.2f%%", cg_uart_evt.get_inst_coverage()), UVM_NONE)
    endfunction
endclass

`endif
