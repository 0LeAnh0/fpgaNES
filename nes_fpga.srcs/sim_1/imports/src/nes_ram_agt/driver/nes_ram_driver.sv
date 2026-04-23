`ifndef NES_RAM_DRIVER_SV
`define NES_RAM_DRIVER_SV

// Tham so hoa VIF_TYPE de cung 1 driver co the dieu khien ca wram_if va vram_if
class nes_ram_driver #(type VIF_TYPE = virtual wram_if) extends uvm_driver #(nes_ram_item);
    `uvm_component_param_utils(nes_ram_driver#(VIF_TYPE))

    VIF_TYPE vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(VIF_TYPE)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", $sformatf("Virtual Interface not found for driver %s", get_full_name()))
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Reset bus values
        vif.en_in   <= 0;
        vif.r_nw_in <= 1; // Default to read
        vif.a_in    <= '0;
        vif.d_in    <= '0;

        forever begin
            seq_item_port.get_next_item(req);
            
            // Doi clock tiep theo de dong bo
            @(vif.drv_cb);
            
            // Ap dung transaction len bus
            vif.drv_cb.en_in   <= 1;
            vif.drv_cb.r_nw_in <= req.r_nw;
            vif.drv_cb.a_in    <= req.addr;
            if (req.r_nw == 0) begin // WRITE
                vif.drv_cb.d_in <= req.data;
            end else begin           // READ
                // Neu doc, khong lai d_in de tranh xung dot
                vif.drv_cb.d_in <= 8'hZ;
            end
            
            // Doi mot chu ky de WRITE hoan tat viec nap du lieu/dia chi vao RAM
            @(vif.drv_cb);
            
            // Neu la READ, chu ky truoc moi nhan dia chi, nen phai doi them 1 chu ky nua 
            // de block RAM xa du lieu d_out ra bus roi moi lay ket qua!
            if (req.r_nw == 1) begin
                @(vif.drv_cb);
                req.data = vif.drv_cb.d_out;
            end

            // Ket thuc transaction, tha bus
            vif.drv_cb.en_in <= 0;
            
            seq_item_port.item_done();
        end
    endtask
endclass

`endif
