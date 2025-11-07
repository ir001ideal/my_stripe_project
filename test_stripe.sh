#!/bin/bash

# Exit on any error
set -e

echo "=== Step 1: Clean and compile the module ==="
make clean
make

echo ""
echo "=== Step 2: Remove old module if loaded ==="
sudo rmmod my_stripe_target 2>/dev/null || echo "Module not loaded, continuing..."

echo ""
echo "=== Step 3: Load device-mapper core module ==="
sudo modprobe dm-mod

echo ""
echo "=== Step 4: Insert the new kernel module ==="
sudo insmod my_stripe_target.ko
echo "Module loaded successfully!"

echo ""
echo "=== Step 5: Set up loop devices (if not already done) ==="
# Create backing files (100MB each)
if [ ! -f /tmp/disk0.img ]; then
    echo "Creating /tmp/disk0.img..."
    sudo dd if=/dev/zero of=/tmp/disk0.img bs=1M count=100
fi

if [ ! -f /tmp/disk1.img ]; then
    echo "Creating /tmp/disk1.img..."
    sudo dd if=/dev/zero of=/tmp/disk1.img bs=1M count=100
fi

# Set up loop devices
sudo losetup -d /dev/loop0 2>/dev/null || true
sudo losetup -d /dev/loop1 2>/dev/null || true
sudo losetup /dev/loop0 /tmp/disk0.img
sudo losetup /dev/loop1 /tmp/disk1.img

echo "Loop devices configured:"
ls -lh /dev/loop0 /dev/loop1

echo ""
echo "=== Step 6: Create the DM stripe device ==="
# Remove if it already exists
sudo dmsetup remove my-split-device 2>/dev/null || true

# Create with 409600 sectors (200MB total = 2 x 100MB)
sudo dmsetup create my-split-device --table "0 409600 my_stripe /dev/loop0 /dev/loop1"

echo ""
echo "=== Step 7: Verify the device was created ==="
sudo dmsetup ls
sudo dmsetup status my-split-device
sudo dmsetup table my-split-device

echo ""
echo "=== Step 8: Check kernel logs ==="
sudo dmesg | tail -10

echo ""
echo "=== Step 9: Create ext4 filesystem on the stripe device ==="
sudo mkfs.ext4 /dev/mapper/my-split-device

echo ""
echo "=== Step 10: Mount the filesystem ==="
sudo mkdir -p /mnt/my_stripe_test
sudo mount /dev/mapper/my-split-device /mnt/my_stripe_test

echo ""
echo "=== Step 11: Test write and read ==="
echo "Testing the stripe device..." | sudo tee /mnt/my_stripe_test/test.txt
sudo cat /mnt/my_stripe_test/test.txt

echo ""
echo "=== Step 12: Show filesystem info ==="
df -h /mnt/my_stripe_test

echo ""
echo "=== SUCCESS! Your odd/even stripe target is working! ==="
echo ""
echo "To clean up when done, run:"
echo "  sudo umount /mnt/my_stripe_test"
echo "  sudo dmsetup remove my-split-device"
echo "  sudo rmmod my_stripe_target"
echo "  sudo losetup -d /dev/loop0"
echo "  sudo losetup -d /dev/loop1"
