`ifndef PPU_BG_RI_UPDATE_TEST_SV
`define PPU_BG_RI_UPDATE_TEST_SV

class ppu_bg_ri_update_test extends ppu_bg_base_test;
  `uvm_component_utils(ppu_bg_ri_update_test)

  function new(string name = "ppu_bg_ri_update_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_bg_ri_update_seq seq;
    phase.raise_objection(this);
    
    // Luon cho doi het Reset de dam bao mach on dinh
    // Doi cho den khi tin hieu Reset tu Testbench Top nha ra (rst_req = 0)
    // Viec nay dam bao cac counter ben trong PPU BG da duoc xoa sach ve 0 truoc khi nap data
    wait(tb_ctrl_vif.rst_req == 1'b0);
    #100ns;

    `uvm_info("TEST", "Bat dau Sequence kiem tra cap nhat thanh ghi (RI Update)", UVM_LOW)
    seq = ppu_bg_ri_update_seq::type_id::create("seq");
    seq.start(env.master_agent.sequencer);
    
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

`endif
