#!/bin/bash
echo "=================================================="
echo "  Bypass Post-Login Setup & Install GPU Drivers   "
echo "=================================================="

# 1. Find Data volume
DATA_VOL=""
for v in /Volumes/*; do
    if [ -d "$v/private/var/db/dslocal/nodes/Default" ]; then
        DATA_VOL="$v"
        break
    elif [ -d "$v/var/db/dslocal/nodes/Default" ]; then
        DATA_VOL="$v"
        break
    fi
done

if [ -z "$DATA_VOL" ]; then
    echo "ERROR: Data volume not found!"
    ls -la /Volumes
    exit 1
fi
echo "[1] Target volume: $DATA_VOL"

# 2. Skip post-login buddy (Theme, Siri, Analytics, Touch ID)
echo "[2] Skipping all post-login setup screens (Theme, Siri, etc.)..."
PREF_DIR="$DATA_VOL/Users/admin/Library/Preferences"
mkdir -p "$PREF_DIR"

cat << 'EOF' > "$PREF_DIR/com.apple.SetupAssistant.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>DidSeeAppearanceSetup</key>
	<true/>
	<key>DidSeeApplePaySetup</key>
	<true/>
	<key>DidSeeAvatarSetup</key>
	<true/>
	<key>DidSeeCloudDiagnostics</key>
	<true/>
	<key>DidSeeCloudSetup</key>
	<true/>
	<key>DidSeePrivacy</key>
	<true/>
	<key>DidSeeScreenTime</key>
	<true/>
	<key>DidSeeSiriSetup</key>
	<true/>
	<key>DidSeeSyncSetup</key>
	<true/>
	<key>DidSeeTouchIDSetup</key>
	<true/>
	<key>DidSeeTrueTonePrivacy</key>
	<true/>
	<key>DidSeeWallpaperSetup</key>
	<true/>
	<key>LastSeenBuddyBuildVersion</key>
	<string>99Z999</string>
	<key>LastSeenCloudProductVersion</key>
	<string>99.9.9</string>
	<key>RunNonInteractive</key>
	<true/>
</dict>
</plist>
EOF

cp "$PREF_DIR/com.apple.SetupAssistant.plist" "$DATA_VOL/Library/Preferences/" 2>/dev/null
chown -R 501:20 "$DATA_VOL/Users/admin/Library" 2>/dev/null
touch "$DATA_VOL/private/var/db/.AppleSetupDone"
touch "$DATA_VOL/var/db/.AppleSetupDone" 2>/dev/null
touch "$PREF_DIR/.skipbuddy"
touch "$DATA_VOL/private/var/db/.skipbuddy"

# 3. Copy Intel Xe Graphics drivers directly into system
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/xe_drivers/Library" ]; then
    echo "[3] Installing Intel Xe Metal drivers from $SCRIPT_DIR/xe_drivers ..."
    mkdir -p "$DATA_VOL/Library/Extensions"
    mkdir -p "$DATA_VOL/Library/GPUBundles"
    cp -R "$SCRIPT_DIR/xe_drivers/Library/Extensions/"* "$DATA_VOL/Library/Extensions/"
    cp -R "$SCRIPT_DIR/xe_drivers/Library/GPUBundles/"* "$DATA_VOL/Library/GPUBundles/"
    
    # Permissions
    chown -R root:wheel "$DATA_VOL/Library/Extensions"
    chmod -R 755 "$DATA_VOL/Library/Extensions"
    chown -R root:wheel "$DATA_VOL/Library/GPUBundles"
    chmod -R 755 "$DATA_VOL/Library/GPUBundles"
    
    # FeatureFlags CoreMedia AllowOnePassMetalScaling
    FF_DIR="$DATA_VOL/Library/Preferences/FeatureFlags/Domain"
    mkdir -p "$FF_DIR"
    cat << 'EOF' > "$FF_DIR/CoreMedia.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AllowOnePassMetalScaling</key>
	<dict>
		<key>Enabled</key>
		<false/>
	</dict>
</dict>
</plist>
EOF
    touch "$DATA_VOL/Library/Extensions"
    echo "[3] Drivers copied successfully to $DATA_VOL/Library!"
fi

echo "=================================================="
echo "  DONE! Semua setup tema & siri sudah dimatikan.  "
echo "  Driver grafis Intel Xe sudah disalin ke sistem. "
echo "  Silakan Reboot -> Pilih SSD macOS kamu!         "
echo "=================================================="
