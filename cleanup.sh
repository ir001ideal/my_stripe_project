#!/bin/bash

echo "=== Cleaning up the stripe device setup ==="

echo "Unmounting filesystem..."
sudo umount /mnt/my_stripe_test 2>/dev/null || echo "Already unmounted"

echo "Removing DM device..."
sudo dmsetup remove my-split-device 2>/dev/null || echo "Device already removed"

echo "Removing kernel module..."
sudo rmmod my_stripe_target 2>/dev/null || echo "Module already removed"

echo "Detaching loop devices..."
sudo losetup -d /dev/loop0 2>/dev/null || echo "loop0 already detached"
sudo losetup -d /dev/loop1 2>/dev/null || echo "loop1 already detached"

echo "Removing backing files (optional)..."
# Uncomment if you want to delete the disk images too:
# sudo rm -f /tmp/disk0.img /tmp/disk1.img

echo ""
echo "=== Cleanup complete! ==="
