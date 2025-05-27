#!/bin/bash
set -e

echo "Updating system packages..."
sudo pacman -Syu --noconfirm

echo "Installing OpenCL loader and clinfo..."
sudo pacman -S --noconfirm opencl-icd-loader clinfo tbb base-devel git

if ! command -v yay &> /dev/null
then
    echo "Installing yay AUR helper..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
fi

echo "Installing Intel OpenCL runtime from AUR..."
yay -S --noconfirm intel-opencl-runtime

echo "Checking ICD file..."
ICD_FILE="/etc/OpenCL/vendors/intelocl.icd"
if [ ! -f "$ICD_FILE" ]; then
    echo "ERROR: ICD file $ICD_FILE not found!"
    exit 1
fi

echo "Checking OpenCL library path inside ICD file:"
cat "$ICD_FILE"

echo "Verifying OpenCL library file exists..."
LIB_PATH=$(cat "$ICD_FILE")
if [ ! -f "$LIB_PATH" ]; then
    echo "ERROR: OpenCL library $LIB_PATH not found!"
    exit 1
fi

echo "Setting LD_LIBRARY_PATH to include Intel OpenCL libs..."
export LD_LIBRARY_PATH=/opt/intel/oneapi/compiler/latest/lib:$LD_LIBRARY_PATH

echo "Installation complete. Please logout/login or reboot for changes to take effect."

echo "Running clinfo to verify installation:"
clinfo | head -40

echo "Running hashcat benchmark to verify OpenCL functionality:"
hashcat -b || echo "Warning: hashcat benchmark failed."

exit 0
