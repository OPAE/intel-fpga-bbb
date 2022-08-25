##
## This Makefile synthesizes all examples in the tutorial. It can also
## configure and build ASE instances of every example with the target
## "ase_all". The Makefile only builds .gbs or simulation. It does not run
## them.
##
## Parallel builds work correctly. On a large enough machine you can build
## all targets in parallel.
##

##
## Run make with a PLATFORM=<name> argument, which tags build directories with
## a target platform name.
##

SHELL=bash

ifndef PLATFORM
$(error PLATFORM not set! Use "make PLATFORM=name_you_choose" to name build directories)
endif

# Discover all the sources text files that configure builds in the tutorial.
SOURCES_FILES=$(shell find ../afu_types -path '*/hw/rtl/*' -name '*sources*.txt' | grep -v common)

# Discover all sw directories.
SW_DIRS=$(shell ls -1d ../afu_types/*/*/sw | grep -v common)


#
# Figure out the build directory path in order to find timing results. When
# $OPAE_PLATFORM_ROOT/bin/build_env_config is present, use it.
#
BUILD_DIR=$(shell if [ ! -f "$$OPAE_PLATFORM_ROOT"/bin/build_env_config ]; then echo build; \
              else . "$$OPAE_PLATFORM_ROOT"/bin/build_env_config; echo $$QUARTUS_BUILD_DIR; fi)
TIMING_SUMMARY_FILE=$(BUILD_DIR)/output_files/timing_report/clocks.sta.fail.summary

TGT_GBS_LIST=

# Macro for creating a .gbs in a subdirectory given a sources text file
define BUILD_GBS
# Build all AFUs within a group, e.g. gbs_01 or gbs_02.
gbs_$(1): $(2)
# Synthesize every AFU
gbs_all: $(2)

# Directory of one AFU
$(patsubst %/,%,$(dir $(2))): $(2)

$(2): $(3) $(SW_DIRS)
	afu_synth_setup -f -s "$$<" "$$(@D)"
	@# Make a link to the sw directory (there is a pointer in the sources.txt file)
	rm -f "$$(@D)"/sw_image
	ln -s $$$$(realpath --relative-to="$$(@D)" $$$$(dirname "$$<")/$$$$(grep '^#.*sw:' "$$<" | sed -e 's/.*://')) "$$(@D)"/sw_image
	(cd "$$(@D)"; $$$$OPAE_PLATFORM_ROOT/bin/run.sh 2>&1 > build.log)
	@if [ ! -f "$$(@D)/$$(TIMING_SUMMARY_FILE)" ]; then result="failed"; elif [ -s "$$(@D)/$$(TIMING_SUMMARY_FILE)" ]; then result="DOES NOT meet timing"; else result="meets timing"; fi; \
	echo "Finished $$(@D): $$$${result}"

TGT_GBS_LIST+=$(2)
endef

# Macro for creating and building an ASE simulation given a sources text file.
# It does not run ASE -- just the initial build.
define BUILD_ASE
# Build all AFUs within a group, e.g. ase_01 or ase_02.
ase_$(1): $(2)
# Build simulator for every AFU
ase_all: $(2)
.PHONY: $(2)

$(2): $(3) $(SW_DIRS)
	afu_sim_setup -f -s "$$<" "$$@"
	@# Make a link to the sw directory (there is a pointer in the sources.txt file)
	rm -f "$$(@D)"/sw_image
	ln -s $$$$(realpath --relative-to="$$@" $$$$(dirname "$$<")/$$$$(grep '^#.*sw:' "$$<" | sed -e 's/.*://')) "$$@"/sw_image
	(cd "$$@"; $$(MAKE) 2>&1 > build.log)
	@echo "Finished building $$@"
endef

all: gbs_all

#
# Build software. We simply have HW tests depend on all SW instead of matching
# them together.
#
.PHONY: clean $(SW_DIRS)
$(SW_DIRS):
	(cd "$@"; $(MAKE))

# Clean each SW directory and delete build directories matching $(PLATFORM)
clean:
	@for d in $(SW_DIRS); do (cd $${d}; $(MAKE) clean); done
	@for g in $(TGT_GBS_LIST); do echo rm -rf $$(dirname $${g}); rm -rf $$(dirname $${g}); done


#
# Create a build rule (added to all) for each sources txt file
# The expansion of S as the first argument to BUILD_GBS is pretty wild.
# It maps the path to the .txt file to a group (01, 02, etc.) in the
# first shell call. It maps the path to a single directory name in the
# second shell call. It maps the json name from the .txt file to the
# .gbs name inside the target directory in the third shell call.
#
# Use
#   make PLATFORM=adp gbs_01
# to synthesize all group 01 targets.
#
$(foreach S,$(SOURCES_FILES), \
  $(eval $(call BUILD_GBS,$(shell echo $S | sed -e 'sx.*afu_types/xx' -e 'sx_.*xx'), \
                synth_$(PLATFORM)_$(shell echo $S | sed -e 'sx.*afu_types/xx' -e 'sxhw/rtl/xx' -e 'sx/sourcesxx' -e 's/.txt$$//' -e 'sx^./xx' -e 'sx/x_xg')/$(shell basename -s .json $$(rtl_src_config --json $S)).gbs, \
                $(S)) \
   ))


#
# Create build rules for ASE. These will not be compiled by default. Use
#   make PLATFORM=sim ase_all
# to build ASE targets. Of course you can change the PLATFORM name as desired.
# 
$(foreach S,$(SOURCES_FILES), \
  $(eval $(call BUILD_ASE,$(shell echo $S | sed -e 'sx.*afu_types/xx' -e 'sx_.*xx'), \
                sim_$(PLATFORM)_$(shell echo $S | sed -e 'sx.*afu_types/xx' -e 'sxhw/rtl/xx' -e 'sx/sourcesxx' -e 's/.txt$$//' -e 'sx^./xx' -e 'sx/x_xg'), \
                $(S)) \
   ))
