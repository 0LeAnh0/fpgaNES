`ifndef PPU_VGA_MASTER_MONITOR_SV
`define PPU_VGA_MASTER_MONITOR_SV

class ppu_vga_master_monitor extends uvm_monitor;
  `uvm_component_utils(ppu_vga_master_monitor)

  virtual ppu_vga_if.MONITOR vif;
  uvm_analysis_port #(ppu_vga_sequence_item) item_collected_port;

  function new(string name = "ppu_vga_master_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ppu_vga_if.MONITOR)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_vga_sequence_item item;

    forever begin
      @(vif.mon_cb);
      item = ppu_vga_sequence_item::type_id::create("item");
      item.sys_palette_idx_in = vif.mon_cb.sys_palette_idx_in;
      item.rst_in             = vif.mon_cb.rst_in;
      item.hsync_out          = vif.mon_cb.hsync_out;
      item.vsync_out          = vif.mon_cb.vsync_out;
      item.r_out              = vif.mon_cb.r_out;
      item.g_out              = vif.mon_cb.g_out;
      item.b_out              = vif.mon_cb.b_out;
      item.nes_x_out          = vif.mon_cb.nes_x_out;
      item.nes_y_out          = vif.mon_cb.nes_y_out;
      item.nes_y_next_out     = vif.mon_cb.nes_y_next_out;
      item.pix_pulse_out      = vif.mon_cb.pix_pulse_out;
      item.vblank_out         = vif.mon_cb.vblank_out;
      item.sync_en            = vif.mon_cb.sync_en;
      item.sync_x             = vif.mon_cb.sync_x;
      item.sync_y             = vif.mon_cb.sync_y;
      item.sync_x_next        = vif.mon_cb.sync_x_next;
      item.sync_y_next        = vif.mon_cb.sync_y_next;
      item_collected_port.write(item);
    end
  endtask

endclass

`endif
