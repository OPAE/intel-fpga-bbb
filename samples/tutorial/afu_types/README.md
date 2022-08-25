# AFU Design Patterns

OFS supports multiple PCIe virtual functions. When more than one PCIe virtual function (VF) is available, a FIM may host multiple accelerator functional units (AFUs) simultaneously. In the tutorial, we assume that each VF is exposed as a separate interface and that there is an AFU connected to each interface. PCIe depends on devices responding to CSR reads, so it is illegal to leave a VF port unresponsive. PAC cards and OFS Early Access (EA) expose only a single PCIe function.

We classify collections of AFU instances into three major design patterns:

1. Designs in which all AFUs use the Platform Interface Manager (PIM) to map host channels and local memory to the PIM's versions of memory mapped interfaces. The PIM is an abstraction layer, enabling AFU portability across hardware despite variations in native interfaces. The PIM implementation is documented both for platform developers and for AFU developers in its [source repository](https://github.com/OPAE/ofs-platform-afu-bbb/) and the tutorial here begins with coding examples. This is the most portable design pattern. It is also the simplest for building AFUs that communicate with a host using memory mapped interfaces. __This is the only design pattern in the tutorial that compiles on PAC cards, Xeon+FPGA and OFS EA. Patterns 2 and 3 work only on OFS releases.__
2. A mixture of AFUs, some using the PIM and some connecting directly to FIM device-specific interfaces. The PIM mapping modules from pattern \(1\) are used without the PIM's top-level interface wrapper. In this style, PIM-provided modules can guarantee cross-platform support details such as the maximum burst count of a memory interface independent of the FIM's limits. Unlike pattern \(1\), tying off unused devices is the responsibility of user AFU logic. This pattern can also be used to add a PIM-based module to a FIM's static region outside the port gasket.
3. AFUs with only platform-specific top-level module interface and platform-specific device interfaces. All AFU logic uses the FIM's device protocols directly.

## Structure

The tutorial implements a collection of AFUs in the three design patterns. When possible, AFUs are functionally equivalent despite being coded in different patterns. The intent is to help you choose the best pattern for your application.

- [Section 1](01_pim_ifc/): AFUs that use the PIM for both the top-level interface and device mapping. One of the PIM's key features is the ability to transform a host channel, such as PCIe Transaction Layer Protocol \(TLP\), into a generic AXI memory mapped interface. AFUs can access host memory and manage CSRs with AXI-MM interfaces, leaving TLP encoding to the PIM.
- [Section 2](02_hybrid/): Hybrid designs using a mixture of PIM and native AFUs. The top-level interface is the platform-specific afu\_main\(\).
- [Section 3](03_afu_main/): Platform-specific logic, instantiated from afu\_main\(\).

__The mechanics of simulating, synthesizing and running all of the examples are covered in the [hello world](01_pim_ifc/hello_world/) tutorial in [Section 1](01_pim_ifc/). We strongly encourage you to start with that example even if you have no plans to use the PIM.__

All of the tutorials have two components: CPU-side software in the sw tree and FPGA-side RTL in the hw tree.

AFU sources are stored in directories named hw/rtl, which contain:

- A file specifying the set of sources to compile, named some variation of sources.txt.
- A JSON file containing meta-data that describes the AFU.
- RTL sources.

Each example also includes software to drive the AFUs. While in a sw directory, run "make".
