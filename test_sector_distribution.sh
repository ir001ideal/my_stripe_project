#!/bin/bash

echo "=== Testing Sector Distribution (Even/Odd Striping) ==="
echo ""

if [ ! -b /dev/mapper/my-split-device ]; then
    echo "Error: my-split-device not found. Run ./test_stripe.sh first!"
    exit 1
fi

echo "Step 1: Writing test patterns to specific sectors"
echo "------------------------------------------------"

for i in {0..7}; do
    printf "SECTOR-%d-DATA" $i | sudo dd of=/dev/mapper/my-split-device bs=512 seek=$i count=1 conv=notrunc 2>/dev/null
    echo "  Wrote 'SECTOR-$i-DATA' to virtual sector $i"
done

echo ""
echo "Step 2: Sync to ensure data is written"
echo "---------------------------------------"
sudo sync
sleep 1

echo ""
echo "Step 3: Reading from the VIRTUAL device (dm-0)"
echo "-----------------------------------------------"
echo "Virtual sectors 0-7:"
for i in {0..7}; do
    data=$(sudo dd if=/dev/mapper/my-split-device bs=512 skip=$i count=1 2>/dev/null | strings | head -1)
    echo "  Virtual sector $i: $data"
done

echo ""
echo "Step 4: Reading from EVEN device (loop0)"
echo "-----------------------------------------"
echo "Physical sectors on loop0 (should have virtual sectors 0,2,4,6):"
for i in {0..3}; do
    data=$(sudo dd if=/dev/loop0 bs=512 skip=$i count=1 2>/dev/null | strings | head -1)
    virtual_sector=$((i * 2))
    echo "  loop0 physical sector $i (= virtual sector $virtual_sector): $data"
done

echo ""
echo "Step 5: Reading from ODD device (loop1)"
echo "----------------------------------------"
echo "Physical sectors on loop1 (should have virtual sectors 1,3,5,7):"
for i in {0..3}; do
    data=$(sudo dd if=/dev/loop1 bs=512 skip=$i count=1 2>/dev/null | strings | head -1)
    virtual_sector=$((i * 2 + 1))
    echo "  loop1 physical sector $i (= virtual sector $virtual_sector): $data"
done

echo ""
echo "Step 6: Visual Summary"
echo "----------------------"
echo "Virtual Device Layout:"
echo "  Sector 0 (even) -> loop0 sector 0 : SECTOR-0-DATA"
echo "  Sector 1 (odd)  -> loop1 sector 0 : SECTOR-1-DATA"
echo "  Sector 2 (even) -> loop0 sector 1 : SECTOR-2-DATA"
echo "  Sector 3 (odd)  -> loop1 sector 1 : SECTOR-3-DATA"
echo "  Sector 4 (even) -> loop0 sector 2 : SECTOR-4-DATA"
echo "  Sector 5 (odd)  -> loop1 sector 2 : SECTOR-5-DATA"
echo "  Sector 6 (even) -> loop0 sector 3 : SECTOR-6-DATA"
echo "  Sector 7 (odd)  -> loop1 sector 3 : SECTOR-7-DATA"

echo ""
echo "=== Verification Complete! ==="
echo "If the data matches above, your odd/even striping is working correctly!"
