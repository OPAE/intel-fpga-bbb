This example demonstrates an AFU that is written using plain CCI-P request and
response structures, yet still employs MPF to transform the platform memory
semantics. The example is nearly identical to the [previous linked list
example](../03b_linked_list). The only file that is different is
[hw/rtl/linked_list_afu.sv](hw/rtl/linked_list_afu.sv).

The app_afu() module is replaced with a module that maps the incoming MPF
SystemVerilog interface (named fiu) back to CCI-P request and response
structures (cp2af_sTx and af2cp_sTx). There is a 1:1 mapping of all CCI-P
wires to the MPF interface. app_afu() instantiates the linked list
implementation module, app_afu_cci(). The RTL in app_afu_cci() is nearly
identical to the MPF version in the previous example, differing only in the
use of the CCI-P structures and the lack of MPF request header initialization
functions.

RTL coders are free to choose either the MPF or the CCI-P representation,
even in designs that use MPF to transform the memory semantics.

Please refer to the previous linked list example for a description of the
algorithm and compilation and execution instructions.


## Advanced experiment

Change the assignment setting afu.c0Tx.hdr.ext.addrIsVirtual in
[hw/rtl/linked_list_afu.sv](hw/rtl/linked_list_afu.sv) to 0 instead of 1.
Compile the simulator again and re-run the example. ASE will abort,
reporting a read request to an unallocated address. Clearing addrIsVirtual
disables VTP address translation and virtual addresses are passed all the way
to the platform. This is one consequence of choosing to write an AFU using
CCI-P structures instead of MPF interfaces. Control of MPF extension request
headers, such as addrIsVirtual, is necessarily global when using CCI-P
structures.
