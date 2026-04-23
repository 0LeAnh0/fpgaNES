`ifndef PPU_SPR_BASE_TEST_SV
`define PPU_SPR_BASE_TEST_SV

class ppu_spr_base_test extends uvm_test;
  `uvm_component_utils(ppu_spr_base_test)

  ppu_spr_env env;
  virtual tb_ctrl_if ctrl_vif;

  function new(string name = "ppu_spr_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ppu_spr_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual tb_ctrl_if)::get(this, "", "tb_ctrl_vif", ctrl_vif)) begin
      `uvm_fatal("NOVIF", "tb_ctrl_vif must be set for base_test")
    end
  endfunction

  // Helper task for Reset
  virtual task reset_dut();
    `uvm_info("RESET", "Applying Reset...", UVM_LOW)
    ctrl_vif.rst_req = 1;
    repeat(5) @(posedge env.master_agent.monitor.vif.mon_cb);
    ctrl_vif.rst_req = 0;
    `uvm_info("RESET", "Reset Deasserted", UVM_LOW)
  endtask

  virtual task random_reset_stress(int unsigned pulses = 5, int unsigned min_delay_ns = 100, int unsigned max_delay_ns = 1000);
    `uvm_info("RESET_TEST",
      $sformatf("Starting Random Reset Stress: pulses=%0d delay=[%0d,%0d]ns",
        pulses, min_delay_ns, max_delay_ns),
      UVM_LOW)
    repeat(pulses) begin
      int delay_ns;
      delay_ns = $urandom_range(min_delay_ns, max_delay_ns);
      #(delay_ns * 1ns);
      reset_dut();
    end
    `uvm_info("RESET_TEST", "Random Reset Stress Completed", UVM_LOW)
  endtask

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

endclass

`endif
