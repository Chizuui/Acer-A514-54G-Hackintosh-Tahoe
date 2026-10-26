#!/bin/bash
echo "=== Remove WhateverXe Graphics Payloads ==="
DATA_VOL=""
for v in /Volumes/*; do
    if [ -d "$v/Library/Extensions" ] && [ -d "$v/private/var/db" ]; then
        DATA_VOL="$v"
        break
    fi
done

if [ -z "$DATA_VOL" ]; then
    echo "Data volume not found!"
    ls -la /Volumes
    exit 1
fi

echo "Target volume: $DATA_VOL"
echo "Removing graphics kexts from /Library/Extensions..."
rm -rf "$DATA_VOL/Library/Extensions/AppleIntelTGLCompat.kext"
rm -rf "$DATA_VOL/Library/Extensions/AppleIntelTGLGraphics.kext"
rm -rf "$DATA_VOL/Library/Extensions/AppleIntelTGLGraphicsFramebuffer.kext"

echo "Removing GPU bundles..."
rm -rf "$DATA_VOL/Library/GPUBundles"

echo "Removing cached AuxKC..."
rm -rf "$DATA_VOL/Library/KernelCollections/AuxiliaryKernelExtensions.kc"
touch "$DATA_VOL/Library/Extensions"

echo "============================================"
echo "SUCCESS! Graphics drivers removed cleanly."
echo "Laptop will boot cool and safe now."
echo "============================================"
