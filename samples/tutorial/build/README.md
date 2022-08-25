# Test Build Manager

This directory exists mainly for testing, though you might find it useful when synthesizing tutorial examples for execution on FPGA hardware. On a large machine the Makefile can build all examples in parallel. The Makefile searches for sources text files in the ../afu_types tree and constructs rules for building all available hardware PR images. It also ensures that the software required to run each example is compiled.

Set the PLATFORM argument to make. The variable's only function is to insert a component into the generated build directories so that multiple targets can be compiled in the same tree. Generated build directories are named with the value of PLATFORM along with a flattend version of the path to a sources text file.

After setting OPAE\_PLATFORM\_ROOT to a release tree, compile all software and synthesize all examples with:

```bash
make -j10 PLATFORM=ofs
```

Set the number of parallel jobs (argument to -j) to a value appropriate for your system and PLATFORM to a sensible name.

Clean all software and targets for a PLATFORM with:

```bash
make PLATFORM=ofs clean
```

To build all targets for simulation with ASE:

```bash
make -j10 PLATFORM=sim ase_all
```

Once again, PLATFORM is merely a tag. The above command compiles but does not run the simulator. Run the simulator within a particular build directory with:

```bash
make sim
```

During the build a link named "sw\_image" is added to each build directory, pointing to the compiled software that matches the build. Once all GBS files are compiled, the following loop would load and execute each image sequentially in bash. Change build\_ofs* to match your value of PLATFORM:

```bash
for d in build_ofs*; do
   printf "\n$d/*.gbs\n"
   fpgaconf $d/*.gbs
   $d/sw_image
done
```

Depending on your FPGA setup, sudo might be required to load GBS files or run sw\_image.
