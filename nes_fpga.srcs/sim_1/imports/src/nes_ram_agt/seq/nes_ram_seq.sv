`ifndef NES_RAM_SEQ_SV
`define NES_RAM_SEQ_SV

class nes_base_seq extends uvm_sequence #(nes_ram_item);
    `uvm_object_utils(nes_base_seq)

    function new(string name="nes_base_seq");
        super.new(name);
    endfunction

    // Helper task cho viec Ghi RAM (Write)
    virtual task write_mem(logic [15:0] a, logic [7:0] d);
        nes_ram_item req;
        req = nes_ram_item::type_id::create("req");
        start_item(req);
        if(!req.randomize()) `uvm_error("SEQ", "Randomize failed")
        req.r_nw = 0; // 0: Write
        req.addr = a;
        req.data = d;
        finish_item(req);
    endtask

    // Helper task cho viec Doc RAM (Read)
    virtual task read_mem(logic [15:0] a);
        nes_ram_item req;
        req = nes_ram_item::type_id::create("req");
        start_item(req);
        if(!req.randomize()) `uvm_error("SEQ", "Randomize failed")
        req.r_nw = 1; // 1: Read
        req.addr = a;
        finish_item(req);
    endtask
endclass

// -------------------------------------------------------------------------
// 1. MIRRORING TEST SEQUENCE (Chi dung cho WRAM)
// Muc tieu: Ghi vao dia chi goc, doc thu tai cac dia chi Mirror xem co khop khong.
// -------------------------------------------------------------------------
class test_wram_mirror_seq extends nes_base_seq;
    `uvm_object_utils(test_wram_mirror_seq)
    function new(string name="test_wram_mirror_seq"); super.new(name); endfunction

    virtual task body();
        logic [7:0] test_data;
        logic [15:0] base_addr;
        
        `uvm_info("MIRROR_SEQ", "--- STARTING: WRAM Mirroring Test ---", UVM_LOW)

        for (int i=0; i<10; i++) begin
            base_addr = $urandom_range(0, 16'h07FF); // Dia chi goc 0-2KB
            test_data = $urandom();
            
            // Ghi vao dia chi goc
            write_mem(base_addr, test_data);
            
            // Doc thu tai 3 vung Mirror (0x0800, 0x1000, 0x1800)
            read_mem(base_addr + 16'h0800);
            read_mem(base_addr + 16'h1000);
            read_mem(base_addr + 16'h1800);
        end
    endtask
endclass

// -------------------------------------------------------------------------
// 2. DATA PATTERN SEQUENCE (Dung cho ca WRAM va VRAM)
// Muc tieu: Ghi cac mau (pattern) dac biet de do loi phan cung nhu dinh day Data.
// -------------------------------------------------------------------------
class test_ram_data_pattern_seq extends nes_base_seq;
    `uvm_object_utils(test_ram_data_pattern_seq)
    logic [15:0] start_addr = 0; // Dia chi bat dau test (tuy chinh cho WRAM/VRAM)
    
    function new(string name="test_ram_data_pattern_seq"); super.new(name); endfunction

    virtual task body();
        logic [7:0] patterns[] = '{8'h55, 8'hAA, 8'h00, 8'hFF}; // Cac mau soc van va cuc doan
        `uvm_info("PAT_SEQ", $sformatf("--- STARTING: Data Pattern Test at 0x%04h ---", start_addr), UVM_LOW)

        // Test Walking 1s (Do loi ho mach hoac dinh day)
        for (int i=0; i<8; i++) begin
            write_mem(start_addr + i, (1 << i));
            read_mem(start_addr + i);
        end

        // Test cac mau soc van (Crosstalk test)
        foreach (patterns[i]) begin
            write_mem(start_addr + 16'h0010 + i, patterns[i]);
            read_mem(start_addr + 16'h0010 + i);
        end
    endtask
endclass

// -------------------------------------------------------------------------
// 3. FULL CAPACITY SWEEP SEQUENCE (Dung cho ca WRAM va VRAM)
// Muc tieu: Ghi HET roi moi Doc HET de dam bao ghi o nay khong de o kia (Aliasing).
// -------------------------------------------------------------------------
class test_ram_full_sweep_seq extends nes_base_seq;
    `uvm_object_utils(test_ram_full_sweep_seq)
    logic [15:0] start_addr = 0;
    
    function new(string name="test_ram_full_sweep_seq"); super.new(name); endfunction

    virtual task body();
        `uvm_info("SWEEP_SEQ", $sformatf("--- STARTING: Full Sweep Test at 0x%04h ---", start_addr), UVM_LOW)

        // Buoc 1: Ghi day 2KB bang du lieu phan biet (addr + 1)
        for (int i=0; i<2048; i++) begin
            write_mem(start_addr + i, (i & 8'hFF) + 1);
        end

        // Buoc 2: Doc lai toan bo de kiem tra tinh toan ven dia chi
        for (int i=0; i<2048; i++) begin
            read_mem(start_addr + i);
        end
    endtask
endclass

// -------------------------------------------------------------------------
// 4. ZERO-PAGE & STACK STRESS SEQUENCE (Chi dung cho WRAM)
// Muc tieu: Doc ghi dan xen lien tuc vao vung quan trong cua CPU 6502.
// -------------------------------------------------------------------------
class test_wram_zero_page_stack_seq extends nes_base_seq;
    `uvm_object_utils(test_wram_zero_page_stack_seq)
    function new(string name="test_wram_zero_page_stack_seq"); super.new(name); endfunction

    virtual task body();
        `uvm_info("STRESS_SEQ", "--- STARTING: Stress Test (Zero-Page & Stack) ---", UVM_LOW)

        repeat(100) begin
            logic [15:0] addr = $urandom_range(0, 16'h01FF);
            logic [7:0] data = $urandom();
            write_mem(addr, data);
            read_mem(addr); // Read-Modify-Write style
        end
    endtask
endclass

// -------------------------------------------------------------------------
// 5. GENERIC MIRROR ALIAS SEQUENCE
// Muc tieu: Viet vao dia chi goc va doc lai tai cac alias 0x0800/0x1000/0x1800.
// Dung duoc cho ca WRAM va VRAM vi tb_top deu ep dia chi 11-bit vao block RAM.
// -------------------------------------------------------------------------
class test_ram_mirror_alias_seq extends nes_base_seq;
    `uvm_object_utils(test_ram_mirror_alias_seq)

    logic [15:0] base_start = 16'h0000;
    int unsigned samples = 12;

    function new(string name="test_ram_mirror_alias_seq"); super.new(name); endfunction

    virtual task body();
        logic [15:0] base_addr;
        logic [7:0]  test_data;

        `uvm_info("MIRROR_ALIAS_SEQ",
            $sformatf("--- STARTING: Generic Mirror Alias Test at base 0x%04h (%0d samples) ---",
                base_start, samples), UVM_LOW)

        // Hit edge aliases explicitly first.
        write_mem(base_start + 16'h0000, 8'hA1);
        read_mem (base_start + 16'h0800);
        read_mem (base_start + 16'h1000);
        read_mem (base_start + 16'h1800);

        write_mem(base_start + 16'h07FF, 8'h5E);
        read_mem (base_start + 16'h0FFF);
        read_mem (base_start + 16'h17FF);
        read_mem (base_start + 16'h1FFF);

        for (int i = 0; i < samples; i++) begin
            base_addr = base_start + $urandom_range(0, 16'h07FF);
            test_data = $urandom();
            write_mem(base_addr, test_data);
            read_mem(base_addr);
            read_mem(base_addr + 16'h0800);
            read_mem(base_addr + 16'h1000);
            read_mem(base_addr + 16'h1800);
        end
    endtask
endclass

// -------------------------------------------------------------------------
// 6. RAM BOUNDARY WALK SEQUENCE
// Muc tieu: Hit cac dia chi bien va mot so quadrant de tang coverage co y nghia.
// -------------------------------------------------------------------------
class test_ram_boundary_walk_seq extends nes_base_seq;
    `uvm_object_utils(test_ram_boundary_walk_seq)

    logic [15:0] addresses[$] = '{
        16'h0000, 16'h0001, 16'h00FF, 16'h0100, 16'h01FF,
        16'h0200, 16'h03FF, 16'h05FF, 16'h0600, 16'h07FE, 16'h07FF,
        16'h0800, 16'h0FFF, 16'h1000, 16'h17FF, 16'h1800, 16'h1FFF
    };

    function new(string name="test_ram_boundary_walk_seq"); super.new(name); endfunction

    virtual task body();
        `uvm_info("BOUNDARY_SEQ", "--- STARTING: RAM Boundary Walk Sequence ---", UVM_LOW)
        foreach (addresses[i]) begin
            write_mem(addresses[i], addresses[i][7:0] ^ 8'hC3);
            read_mem(addresses[i]);
        end
    endtask
endclass

`endif
