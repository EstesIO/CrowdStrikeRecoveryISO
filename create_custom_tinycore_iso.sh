#!/bin/bash

# Variables
TINY_CORE_ISO_URL="http://tinycorelinux.net/11.x/x86/release/CorePlus-current.iso"
WORK_DIR="/tmp/tinycore_custom"
ISO_DIR="$WORK_DIR/iso"
EXTRACT_DIR="$WORK_DIR/extract"
NEW_ISO_DIR="$WORK_DIR/new_iso"
SCRIPT_NAME="CrowdStrikeFixerBoot.sh"
SCRIPT_URL="https://github.com/EstesIO/CrowdStrikeRecoveryISO/blob/main/CrowdStrikeFixerBoot.sh" # Replace with your actual script URL
NTFS_3G_URL="http://tinycorelinux.net/11.x/x86/tcz/ntfs-3g.tcz"
ISO_OUTPUT_NAME="FalconBoot-Reboot.ISO"

# Ensure required tools are installed
sudo apt update
sudo apt install -y curl rsync genisoimage syslinux-utils

# Cleanup
rm -rf $WORK_DIR
mkdir -p $ISO_DIR $EXTRACT_DIR $NEW_ISO_DIR $EXTRACT_DIR/tce/optional

# Download Tiny Core Linux ISO
curl -o $WORK_DIR/CorePlus-current.iso $TINY_CORE_ISO_URL

# Mount the Tiny Core ISO
sudo mount -o loop $WORK_DIR/CorePlus-current.iso $ISO_DIR

# Extract the contents of the ISO
rsync -a $ISO_DIR/ $EXTRACT_DIR/

# Unmount the ISO
sudo umount $ISO_DIR

# Download the custom script
curl -o $EXTRACT_DIR/$SCRIPT_NAME $SCRIPT_URL
chmod +x $EXTRACT_DIR/$SCRIPT_NAME

# Download ntfs-3g and add it to the ISO
curl -o $EXTRACT_DIR/tce/optional/ntfs-3g.tcz $NTFS_3G_URL
echo "ntfs-3g.tcz" >> $EXTRACT_DIR/tce/onboot.lst

# Create bootlocal.sh if it doesn't exist and add the script execution
cat <<EOF > $EXTRACT_DIR/tce/bootlocal.sh
#!/bin/sh
/mnt/sda1/$SCRIPT_NAME
EOF
chmod +x $EXTRACT_DIR/tce/bootlocal.sh

# Recreate the ISO
cd $EXTRACT_DIR
sudo genisoimage -l -J -R -V "CustomTinyCore" -no-emul-boot -boot-load-size 4 -boot-info-table \
-b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -o $NEW_ISO_DIR/$ISO_OUTPUT_NAME .

# Make the ISO bootable
sudo isohybrid $NEW_ISO_DIR/$ISO_OUTPUT_NAME

# Cleanup
rm -rf $WORK_DIR/CorePlus-current.iso

echo "Custom Tiny Core ISO created at $NEW_ISO_DIR/$ISO_OUTPUT_NAME"
