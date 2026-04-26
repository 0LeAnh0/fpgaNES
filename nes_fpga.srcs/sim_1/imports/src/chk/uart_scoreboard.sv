`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

`uvm_analysis_imp_decl(_exp)
`uvm_analysis_imp_decl(_act)

class uart_scoreboard extends uvm_component;
    `uvm_component_utils(uart_scoreboard)

    uvm_analysis_imp_exp #(uart_item, uart_scoreboard) exp_export;
    uvm_analysis_imp_act #(uart_item, uart_scoreboard) act_export;

    uart_item m_expected_rx_q[$];
    int unsigned m_expected_parity_events;
    int unsigned m_actual_parity_events;
    int unsigned m_compare_count;
    int unsigned m_error_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        exp_export = new("exp_export", this);
        act_export = new("act_export", this);
    endfunction

    function void write_exp(uart_item t);
        uart_item exp_clone;

        case (t.kind)
            UART_CMD_TX_WRITE: begin
                if (t.tx_accept && t.expect_rx) begin
                    exp_clone = uart_item::type_id::create("exp_clone");
                    exp_clone.copy(t);
                    m_expected_rx_q.push_back(exp_clone);
                end
            end

            UART_CMD_INJECT_RX: begin
                if (t.expect_rx) begin
                    exp_clone = uart_item::type_id::create("inj_clone");
                    exp_clone.copy(t);
                    m_expected_rx_q.push_back(exp_clone);
                end
                if (t.expect_parity_err)
                    m_expected_parity_events++;
            end

            UART_CMD_RESET: begin
                m_expected_rx_q.delete();
            end

            default: begin
            end
        endcase
    endfunction

    function void write_act(uart_item t);
        uart_item exp_item;

        case (t.kind)
            UART_EVT_RX_DATA: begin
                if (m_expected_rx_q.size() == 0) begin
                    m_error_count++;
                    `uvm_error("UART_SCB", $sformatf("Unexpected RX data observed: 0x%02h", t.data))
                end else begin
                    exp_item = m_expected_rx_q.pop_front();
                    m_compare_count++;
                    if (exp_item.data == t.data)
                        `uvm_info("UART_SCB", $sformatf("PASS RX[%0d] exp=0x%02h act=0x%02h", m_compare_count, exp_item.data, t.data), UVM_MEDIUM)
                    else begin
                        m_error_count++;
                        `uvm_error("UART_SCB", $sformatf("FAIL RX[%0d] exp=0x%02h act=0x%02h", m_compare_count, exp_item.data, t.data))
                    end
                end
            end

            UART_EVT_PARITY_ERR: begin
                m_actual_parity_events++;
                `uvm_info("UART_SCB", $sformatf("Observed parity error event %0d", m_actual_parity_events), UVM_MEDIUM)
            end

            default: begin
            end
        endcase
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        if (m_expected_rx_q.size() != 0) begin
            m_error_count++;
            `uvm_error("UART_SCB_RPT", $sformatf("Expected RX queue not empty at end of test: %0d item(s)", m_expected_rx_q.size()))
        end

        if (m_actual_parity_events != m_expected_parity_events) begin
            m_error_count++;
            `uvm_error("UART_SCB_RPT", $sformatf("Parity event mismatch exp=%0d act=%0d", m_expected_parity_events, m_actual_parity_events))
        end

        `uvm_info("UART_SCB_RPT",
            $sformatf("UART scoreboard summary: compares=%0d parity_exp=%0d parity_act=%0d errors=%0d",
            m_compare_count, m_expected_parity_events, m_actual_parity_events, m_error_count), UVM_NONE)
    endfunction
endclass

`endif
