# Hybrid Hello World

Two equivalent implementations of *hello\_world* are instantiated here. A TLP-based version is on port 0. As can be seen from the [sources.txt](hw/rtl/sources.txt) file, the TLP version is shared with the TLP-only example in the [next section](../../03_afu_main/hello_world/). The PIM-based version from the [previous section](../../01_pim_ifc/hello_world/) is instantiated on all remaining ports.

The [matching software](sw) is enhanced to detect all instances of the AFU. The TLP-based version writes "Hello world TLP!" instead of just "Hello world!". \(Note that ASE currently detects only the AFU connected to port 0 and will only show the TLP-based AFU. Others are present but not visible to ASE. The AFUs are visible on hardware when multiple VFs are available.\)

Details of the TLP implementation are in the [next section](../../03_afu_main/hello_world/). We will focus here on hybrid mapping to PIM interfaces in [afu\_main\(\)](hw/rtl/afu_main.sv). There are two extra blocks required. First, a PIM host channel must be declared. This is the same type as *plat\_ifc.host\_chan.ports\[p\]* in the PIM-only variant:

```SystemVerilog
ofs_plat_host_chan_axis_pcie_tlp_if
  #(
    .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
    )
  host_chan();
```

Then the TLP AXI streams must be mapped to *host\_chan:* 

```SystemVerilog
map_fim_pcie_ss_to_pim_host_chan
  #(
    .INSTANCE_NUMBER(p),

    .PF_NUM(PORT_PF_VF_INFO[p].pf_num),
    .VF_NUM(PORT_PF_VF_INFO[p].vf_num),
    .VF_ACTIVE(PORT_PF_VF_INFO[p].vf_active)
    )
map_host_chan
  (
   .clk(clk),
   .reset_n(port_rst_n_q2[p]),

   .pcie_ss_tx_a_st(afu_axi_tx_a_if[p]),
   .pcie_ss_tx_b_st(afu_axi_tx_b_if[p]),
   .pcie_ss_rx_a_st(afu_axi_rx_a_if[p]),
   .pcie_ss_rx_b_st(afu_axi_rx_b_if[p]),

   .port(host_chan)
   );
```

The value passed into *reset\_n* is the combination of hard and function-level soft resets. The two code blocks above match the PIM's implementation. The PIM's internal logic uses the same [map\_fim\_pcie\_ss\_to\_pim\_host\_chan\(\)](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/ifc_classes/host_chan/native_axis_pcie_tlp/prims/gasket_pcie_ss/map_fim_pcie_ss_to_GROUP_host_chan.sv).

Instead of the PIM's *ofs\_plat\_if\_tie\_off\_unused\(\)*, unused devices are tied off using the FIM's interfaces.