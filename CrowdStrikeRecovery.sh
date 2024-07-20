#!/bin/bash

# Function to unmount drives before exit
cleanup() {
    echo "Cleaning up and unmounting drives..."
    for mount_point in "${mount_points[@]}"; do
        umount "$mount_point" 2>/dev/null
    done
}

# Function to check for BitLocker or other encryption
is_encrypted() {
    local device=$1
    cryptsetup isLuks "$device" &>/dev/null
    return $?
}

# Function to search and delete specific files on a Windows partition
search_and_delete_files() {
    local mount_point=$1
    local file_path="$mount_point/Windows/System32/drivers/CrowdStrike"
    
    if [ -d "$file_path" ]; then
        echo "Searching for C-00000291*.sys files in $file_path"
        find "$file_path" -name "C-00000291*.sys" -exec rm -f {} \;
    fi
}

# Trap any script exit to ensure cleanup is done
trap cleanup EXIT

# Array to hold mount points
mount_points=()

# Detect all block devices and try to mount them
for device in $(lsblk -nr -o NAME,TYPE | grep 'part' | awk '{print $1}'); do
    full_device="/dev/$device"
    
    if is_encrypted "$full_device"; then
        echo "The device $full_device is encrypted with BitLocker or another encryption method. You may need to recover it using a key."
        continue
    fi
    
    mount_point=$(mktemp -d)
    
    mount -t ntfs-3g "$full_device" "$mount_point" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Mounted $full_device at $mount_point"
        mount_points+=("$mount_point")
        search_and_delete_files "$mount_point"
    else
        rmdir "$mount_point"
    fi
done

# Ensure the script waits before the cleanup function is triggered
sleep 5

echo "Operation completed. Rebooting the system."
reboot

exit 0
