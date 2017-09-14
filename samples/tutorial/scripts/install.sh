#!/bin/sh

echo "This script is interactive for teaching purposes.  No user input is"
echo "actually required.  Hit ENTER at the [enter] prompts.  If you want to"
echo "run without stopping then pipe yes into the script: \"yes | install.sh\"."
echo "Read the script to see the detailed steps."
read -p "[enter] " x

##
## Install required tools
##
did_update=0
for tool in git cmake; do
  if ! [ -x "$(command -v ${tool})" ]; then
    echo ""
    echo "Intalling ${tool}"
    read -p "[enter] " x
    if [ $did_update -eq 0 ]; then
      sudo apt update
      did_update=1
    fi
    sudo apt-get install -y ${tool}
  fi
done

echo ""
echo "git clone https://github.com/OPAE/opae-sdk to ~/src/opae-sdk."
read -p "[enter] " x
mkdir -p ~/src
cd ~/src
rm -rf opae-sdk
git clone https://github.com/OPAE/opae-sdk
if [ $? -ne 0 ]; then
  echo "git clone failed!"
  exit 1
fi
cd opae-sdk

echo ""
echo "Constructing build directory in ~/src/opae-sdk/build using"
echo "  cmake -DBUILD_ASE=ON -DCMAKE_INSTALL_PREFIX=/usr/local .."
read -p "[enter] " x
mkdir build
cd build
cmake -DBUILD_ASE=ON -DCMAKE_INSTALL_PREFIX=/usr/local ..

echo ""
echo "Building OPAE"
read -p "[enter] " x
make

echo ""
echo "Installing OPAE to /usr/local as root (using sudo)"
read -p "[enter] " x
sudo make install



echo ""
echo "git clone https://github.com/OPAE/intel-fpga-bbb to ~/src/intel-fpga-bbb."
read -p "[enter] " x
cd ~/src
rm -rf intel-fpga-bbb
git clone https://github.com/OPAE/intel-fpga-bbb
if [ $? -ne 0 ]; then
  echo "git clone failed!"
  exit 1
fi

echo ""
echo "Constructing build directory in ~/src/intel-fpga-bbb/BBB_cci_mpf/sw/build using"
echo "  cmake -DCMAKE_INSTALL_PREFIX=/usr/local .."
read -p "[enter] " x
cd intel-fpga-bbb/BBB_cci_mpf/sw
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..

echo ""
echo "Building MPF"
read -p "[enter] " x
make

echo ""
echo "Installing MPF to /usr/local as root (using sudo)"
read -p "[enter] " x
sudo make install



echo ""
echo "Updating shared library database with ldconfig"
read -p "[enter] " x
sudo ldconfig



echo ""
echo "Adding environment variable setup to ~/.bash_opae_env and sourcing it"
echo "from ~/.bashrc."
read -p "[enter] " x

## Set environment variables
grep -q bash_opae_env ~/.bashrc
if [ $? -ne 0 ]; then
  cat <<- EOF >> ~/.bashrc

## Configure OPAE environment
. ~/.bash_opae_env
EOF
fi

cat << EOF > ~/.bash_opae_env
# OPAE sources
export OPAE_BASEDIR=~/src/opae-sdk

# CCI BBB (basic building blocks)
export FPGA_BBB_CCI_SRC=~/src/intel-fpga-bbb
EOF


echo ""
echo "Installation complete!  Start the tutorial with the README file in"
echo "~/src/intel-fpga-bbb/samples/tutorial."
echo ""
echo "The tutorial depends on some environment variables.  Either source"
echo "~/.bash_opae_env or exit this shell and start a new one."
