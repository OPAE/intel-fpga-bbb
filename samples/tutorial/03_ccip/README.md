# CCI-P

The Core Cache Interface (CCI-P) is the interface between an AFU and the
host. CCI-P defines an interface for accessing system memory as well as a
memory mapped I/O (MMIO) space that is typically used for CSRs. A [CCI-P
reference manual](https://www.altera.com/documentation/buf1506187769663.html)
is available on-line.

The examples here are not a full introduction to CCI-P. Instead, the examples
are intended to:

- Demonstrate methods for organizing AFUs and software, including C++ wrapper
  classes and RTL wrappers for simple CSR structures.

- Introduce [Basic Building
  Blocks](https://github.com/OPAE/intel-fpga-bbb/wiki). The base FIU logic in
  the FPGA is deliberately simple. Every feature added to the FIU consumes
  FPGA area at the expense of resources available to AFUs. BBBs, such as MPF,
  allow AFU-specific transformation of CCI-P semantics.

[03a_hello_world_mpf](03a_hello_world_mpf) re-implements the original hello
world example using the structured software and hardware modules.

[03b_linked_list](03b_linked_list) and
[03c_linked_list_cci](03c_linked_list_cci) introduce MPF building blocks using
two different RTL representations of CCI-P. Both transform CCI-P to use
virtual addresses corresponding to address mapping on the host.
