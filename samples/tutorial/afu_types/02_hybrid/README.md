# Hybrid Designs

This tutorial section applies only to OFS systems. The RTL currently compiles on d5005 and n6000 reference platforms. The limited system support is a design choice: the *afu\_main\(\)* top-level module port list varies from platform to platform.

The examples are necessarily more complicated than in [Section 1](../01_pim_ifc):

- Device differences necessarily lead to differences in the *afu\_main\(\)* port list, though the examples here are somewhat more complicated than required by a single FIM because they use macros to compile on multiple platforms.
- AFUs that use the PIM require extra logic when mapping FIM ports to PIM equivalents. In [Section 1](../01_pim_ifc), the mapping was hidden inside the PIM's *ofs\_plat\_afu\(\)* wrapper.
- Tie-offs for all unused devices are handled explicitly.

It should become clear that the hybrid design pattern only makes sense when you are combining a mixture of PIM-based and native AFUs.

Two examples are reimplemented here, but in hybrid style:

- [hello\_world](hello_world) instantiates functionally equivalent versions of the previously discussed example. Within the same design, some AFUs are the PIM-based version and some are a TLP-based implementation, encoded directly for the PCIe subsystem.
- [local\_memory](local_memory) demonstrates mapping FIM local memory interfaces to PIM equivalents and then instantiates the example from the previous section.