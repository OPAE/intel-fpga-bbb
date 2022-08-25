# Tutorial

This tree contains [sample workloads](afu_types/), typically written as small examples of specific concepts. The tutorial progresses through defining RTL sources, configuring for simulation or synthesis, and connecting to device interfaces. The designs are deliberately simple, intended to demonstrate simulation, synthesis and the Platform Interface Manager without the details of an actual accelerator getting in the way.

All the designs may either be simulated with ASE or synthesized for FPGA hardware.

The tutorial documentation is written in Markdown. We suggest you pull a local copy of the tutorial in order to compile the examples and that you read the tutorial's documentation with a browser.

## Requirements

All samples depend on proper configuration of OPAE and the hardware build environments.

### Partial Reconfiguration Build Template \(__OPAE\_PLATFORM\_ROOT__\)

The tutorial examples depend on an out-of-tree partial reconfiguration \(PR\) build environment for simulation with ASE and synthesis with Quartus. The tutorial remains relevant even if your target FIM does not use PR. The module hierarchy and ports passed to AFUs are independent of whether there also happens to be a PR boundary around the OFS afu\_top\(\). All of the AFU RTL examples here can be built into OFS FIMs without partial reconfiguration. We use PR in order to simplify the build environment and to focus the tutorial on AFU development without the complication of configuring a full FIM. In addition, ASE configuration scripts currently depend on the PR flow. If you are developing a FIM without PR, we suggest that you pick a different base FIM for working through the tutorial and then switch to your non-PR FIM.

Older OPAE-based releases for PAC cards and the Broadwell integrated Xeon+FPGA that predate OFS may also be used. However, they must be upgraded to a new version of the PIM. A set of update scripts is provided in the [ofs-platform-afu-bbb](https://github.com/OPAE/ofs-platform-afu-bbb) repository. The one-time script, [plat\_if\_release/update\_release.sh](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_release/update_release.sh), must be run in order to configure both simulation and Quartus environments with the PIM. PAC card releases are equivalent to OFS out-of-tree PR build environments.

In OFS, the out-of-tree build environment can be generated automatically at the end of a FIM compilation by passing the "&#8209;p" switch to ./syn/build_top. With "&#8209;p" set, the tree is stored in \<work dir\>/pr\_build\_template. The pr\_build\_template tree is relocatable and may be moved anywhere in the filesystem. Setting "&#8209;p" runs ./syn/common/scripts/generate\_pr\_release.sh at the end of the FIM build. This script may also be invoked by hand on a completed FIM build's work tree.

__Set the OPAE\_PLATFORM\_ROOT environment variable to the path of an OFS pr\_build\_template tree or to the root of an updated PAC or Xeon+FPGA release.__ You can determine whether OPAE\_PLATFORM\_ROOT points to a valid release tree by confirming that ${OPAE\_PLATFORM\_ROOT}/hw/lib/build/platform/ofs\_plat\_if exists.

### OPAE Software Environment

1. Install the OPAE SDK from packages shipped with a board release or from source, by following the [standard instructions](https://opae.github.io/).

2. If OPAE is installed to standard system directories it may already be found on C and C++ header and library search paths. If not, the installation directories must be added explicitly:

   - Header files from OPAE must either be on the default compiler search paths or on both __C\_INCLUDE\_PATH__ and __CPLUS\_INCLUDE\_PATH__.

   - OPAE libraries must either be on the default linker search paths or on both __LIBRARY\_PATH__ and __LD\_LIBRARY\_PATH__.

3. Install [ASE, the OPAE RTL simulator](https://github.com/OPAE/opae-sim). With the OPAE SDK already installed, build and add ASE to the OPAE tree with:

    ```sh
    cd opae-sim
    mkdir build
    cd build
    # Set -DCMAKE_INSTALL_PREFIX=<dir> if OPAE is installed in a non-standard location
    cmake ..

    # This might need to be run as root if OPAE was installed as root
    make install
    ```

The tutorial begins with a discussion of [AFU design pattern choices](afu_types).
