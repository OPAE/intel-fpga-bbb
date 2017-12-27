"""Build an ASE simulation environment.
"""

import sys, os
from os.path import dirname, realpath, sep

def setup_ase_sim(src_config, tgt_dir, default_sim='vcs'):
    # Check for some required environment variables
    src_basedir = os.environ.get('OPAE_BASEDIR')
    if not src_basedir:
        print 'The OPAE_BASEDIR environment variables must point to the root'
        print 'of the OPAE source tree.'
        sys.exit(1)

    if not os.environ.get('FPGA_BBB_CCI_SRC'):
        print 'The FPGA_BBB_CCI_SRC environment variables must point to the root'
        print 'of the Basic Building Blocks source tree.'
        sys.exit(1)

    # Find the ASE source
    ase_src = src_basedir + sep + 'ase'
    if not os.path.isfile(ase_src + '/scripts/generate_ase_environment.py'):
        print 'Failed to find setup script %s' % (ase_src + '/scripts/generate_ase_environment.py')
        sys.exit(1)

    # Find source configuration
    src_config = os.path.abspath(src_config)
    if os.path.isdir(src_config):
        src_config = src_config + sep + 'sources.txt'
    if not os.path.isfile(src_config):
        print 'Sources file ' + src_config + ' not found'
        sys.exit(1)

    # Make the target directory
    if tgt_dir == '':
        print 'Target directory not set'
        sys.exit(1)
    try:
        os.mkdir(tgt_dir)
    except:
        print 'Target directory (%s) already exists.' % tgt_dir
        sys.exit(1)

    # Copy ASE to target directory
    os.system('rsync -a ' + ase_src + '/ ' + tgt_dir + '/')
    os.chdir(tgt_dir)

    # Make a dummy Verilog file for setup purposes.  generate_ase_environment.py
    # wants to walk a directory and compile all the sources in it, so we have
    # to give it something.  We will replace this dummy with src_config.
    os.mkdir('dummy')
    os.close(os.open('dummy/null.sv', os.O_WRONLY | os.O_CREAT, 0644))

    # Configure both Questa and VCS.  Whichever is configured last becomes
    # the default.
    if default_sim == 'questa':
        os.system('./scripts/generate_ase_environment.py dummy -t VCS')
        os.system('./scripts/generate_ase_environment.py dummy -t QUESTA > /dev/null')
    else:
        os.system('./scripts/generate_ase_environment.py dummy -t QUESTA > /dev/null')
        os.system('./scripts/generate_ase_environment.py dummy -t VCS')

    # Clean up files no longer needed
    os.remove('dummy/null.sv')
    os.rmdir('dummy')
    os.remove('vlog_files.list')

    # Configure sources for the target workload
    os.rename('ase_sources.mk', 'ase_sources.mk.orig')
    os.system('sed ' +
              '-e \'s^DUT_VLOG_SRC_LIST =.*^DUT_VLOG_SRC_LIST = ' + src_config + '^\' ' +
              '-e \'s^DUT_INCDIR =.*^DUT_INCDIR =^\' ' +
              'ase_sources.mk.orig > ase_sources.mk')
    os.remove('ase_sources.mk.orig')

    # Update Makefile
    os.system('sed ' +
              '-i \'/^SNPS_VLOGAN_OPT.*ASE_PLATFORM.*/aSNPS_VLOGAN_OPT+= +define+MPF_PLATFORM_BDX +define+CCIP_IF_V0_1 +define+CCI_SIMULATION=1 +define+SIM_MODE=1\' ' +
              'Makefile')
    os.system('sed ' +
              '-i \'/^MENT_VLOG_OPT.*ASE_PLATFORM.*/aMENT_VLOG_OPT+= +define+MPF_PLATFORM_BDX +define+CCIP_IF_V0_1 +define+CCI_SIMULATION=1 +define+SIM_MODE=1\' ' +
              'Makefile')
    # Get rid of -novopt argument to QuestaSim
    os.system('sed -i ' +
              '-e \'s/ -novopt//\' ' +
              'Makefile')

    # Use ASE mode 3 (exit when workload finishes)
    os.system('sed -i \'s/ASE_MODE.*/ASE_MODE = 3/\' ase.cfg')
    # Don't print every transaction to the console
    os.system('sed -i \'s/ENABLE_CL_VIEW.*/ENABLE_CL_VIEW = 0/\' ase.cfg')


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Generate an ASE instance given a configuration file.')
    parser.add_argument('--src', required=1, help='Directory containing sources.txt or a simulator input file listing RTL sources.')
    parser.add_argument('--simulator', default='vcs', choices=['vcs', 'questa'], help='Default simulator.')
    parser.add_argument('dst', help='Target directory path (directory must not exist)')
    args = parser.parse_args()

    setup_ase_sim(args.src, args.dst, args.simulator)
