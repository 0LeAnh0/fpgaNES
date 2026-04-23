`ifndef NES_RAM_SCOREBOARD_SV
`define NES_RAM_SCOREBOARD_SV

// Scoreboard nay su dung macros `uvm_analysis_imp_decl de phan biet 2 cong nhan (WRAM va VRAM)
`uvm_analysis_imp_decl(_wram)
`uvm_analysis_imp_decl(_vram)

class nes_ram_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(nes_ram_scoreboard)

    // Analysis exports cho phep Monitor gui transaction toi day
    uvm_analysis_imp_wram #(nes_ram_item, nes_ram_scoreboard) wram_export;
    uvm_analysis_imp_vram #(nes_ram_item, nes_ram_scoreboard) vram_export;

    // Reference Models: Bo nho mo phong bang Associative Array
    logic [7:0] wram_ref_model[logic [15:0]];
    logic [7:0] vram_ref_model[logic [15:0]];

    // Thong ke don gian
    int wram_match, wram_mismatch;
    int vram_match, vram_mismatch;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        wram_export = new("wram_export", this);
        vram_export = new("vram_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        wram_match = 0; wram_mismatch = 0;
        vram_match = 0; vram_mismatch = 0;
    endfunction

    // Ham nhan du lieu tu WRAM Monitor
    virtual function void write_wram(nes_ram_item tr);
        logic [15:0] mapped_addr;
        // Cat lay 11-bit cuoi de gia lap tinh nang Mirroring bang phan cung (chap mach)
        mapped_addr = tr.addr & 16'h07FF; 

        if (tr.r_nw == 0) begin // WRITE
            wram_ref_model[mapped_addr] = tr.data;
            `uvm_info("SCB_WRAM", $sformatf("WRITE: addr=%04h (mapped=%04h), data=%02h", tr.addr, mapped_addr, tr.data), UVM_LOW)
        end else begin // READ
            if (wram_ref_model.exists(mapped_addr)) begin
                if (tr.data == wram_ref_model[mapped_addr]) begin
                    wram_match++;
                    `uvm_info("SCB_WRAM", $sformatf("MATCH! addr=%04h (mapped=%04h), data=%02h", tr.addr, mapped_addr, tr.data), UVM_LOW)
                end else begin
                    wram_mismatch++;
                    `uvm_error("SCB_WRAM", $sformatf("MISMATCH! addr=%04h (mapped=%04h), EXPECTED: %02h, ACTUAL: %02h", 
                                tr.addr, mapped_addr, wram_ref_model[mapped_addr], tr.data))
                end
            end else begin
                // Doc khi chua ghi (hoac la gia tri rac)
                `uvm_warning("SCB_WRAM", $sformatf("READ unknown: addr=%04h (mapped=%04h)", tr.addr, mapped_addr))
            end
        end
    endfunction

    // Ham nhan du lieu tu VRAM Monitor
    virtual function void write_vram(nes_ram_item tr);
        logic [15:0] mapped_addr;
        // Tuong tu, VRAM cung lay 11-bit de xac dinh 2KB nametable
        mapped_addr = tr.addr & 16'h07FF; 

        if (tr.r_nw == 0) begin // WRITE
            vram_ref_model[mapped_addr] = tr.data;
            `uvm_info("SCB_VRAM", $sformatf("WRITE: addr=%04h (mapped=%04h), data=%02h", tr.addr, mapped_addr, tr.data), UVM_LOW)
        end else begin // READ
            if (vram_ref_model.exists(mapped_addr)) begin
                if (tr.data == vram_ref_model[mapped_addr]) begin
                    vram_match++;
                    `uvm_info("SCB_VRAM", $sformatf("MATCH! addr=%04h (mapped=%04h), data=%02h", tr.addr, mapped_addr, tr.data), UVM_LOW)
                end else begin
                    vram_mismatch++;
                    `uvm_error("SCB_VRAM", $sformatf("MISMATCH! addr=%04h (mapped=%04h), EXPECTED: %02h, ACTUAL: %02h", 
                                tr.addr, mapped_addr, vram_ref_model[mapped_addr], tr.data))
                end
            end else begin
                `uvm_warning("SCB_VRAM", $sformatf("READ unknown: addr=%04h (mapped=%04h)", tr.addr, mapped_addr))
            end
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_REPORT", "=========================================", UVM_LOW)
        `uvm_info("SCB_REPORT", "      NES MEMORY VERIFICATION REPORT     ", UVM_LOW)
        `uvm_info("SCB_REPORT", "-----------------------------------------", UVM_LOW)
        `uvm_info("SCB_REPORT", $sformatf("  WRAM Matches: %0d, Mismatches: %0d", wram_match, wram_mismatch), UVM_LOW)
        `uvm_info("SCB_REPORT", $sformatf("  VRAM Matches: %0d, Mismatches: %0d", vram_match, vram_mismatch), UVM_LOW)
        `uvm_info("SCB_REPORT", "=========================================", UVM_LOW)
    endfunction

endclass

`endif
