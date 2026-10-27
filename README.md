# Acer Aspire 5 A514-54G — macOS 26 Tahoe OpenCore EFI

[Bahasa Indonesia](README_id.md) | **English**

---

OpenCore EFI configuration for **Acer Aspire 5 (A514-54G)** running **macOS 26 Tahoe (Darwin 25.x)**.

> **Status Notice:** macOS installs and boots cleanly into the desktop environment, but **hardware graphics acceleration (Metal 3D) is non-functional** on Intel 11th Gen Tiger Lake due to macOS Tahoe build discrepancies (`25G325`). See the [Hardware Limitations](#-critical-hardware-limitations) section below for detailed technical analysis.

---

## 💻 Hardware Specifications

| Component | Specification |
| :--- | :--- |
| **Model** | Acer Aspire 5 A514-54G |
| **CPU** | Intel Core 11th Gen Tiger Lake (e.g., i5-1135G7) |
| **iGPU** | Intel Iris Xe Graphics (PCI ID `0x9A78` / Gen12 Xe-LP) |
| **dGPU** | NVIDIA GeForce MX350 (2GB GDDR5) — *Disabled via DeviceProperties* |
| **Audio** | Realtek ALC255 (Layout ID: `23`) via AppleALC |
| **Ethernet** | Realtek RTL8168/8111 PCI-E Gigabit Ethernet |
| **Trackpad** | ELAN0522 (I2C HID Precision Touchpad) via VoodooI2C + VoodooI2CHID |
| **Keyboard** | Internal PS/2 Keyboard via VoodooPS2Controller |
| **Storage** | NVMe SSD (M.2 PCIe) + SATA AHCI |
| **OpenCore** | Version 1.0.8 |
| **Target OS** | macOS 26 Tahoe (Build `25G325` / Darwin 25.6.0) |

---

## 📊 Component Status & Diagnostic Breakdown

### ✅ Working Out of the Box:
- **Bootloader & Kernel Boot:** OpenCore 1.0.8 successfully initializes kernel tables, ACPI patches, and booter/memory quirks (`RebuildAppleMemoryMap`, `DisableIoMapperMapping`).
- **System Installation:** Successfully partitions APFS, unpacks base images, and finishes all 3 reboot stages onto NVMe SSD.
- **WindowServer & 2D Framebuffer:** Internal laptop eDP display lights up at native resolution; hardware mouse cursor renders smoothly and responds to input.
- **Input System:** Internal PS/2 keyboard (`VoodooPS2Keyboard`), external USB Gaming Keyboard, 2.4G wireless mouse, and ELAN0522 I2C touchpad (`VoodooI2CHID`).
- **USB Controller & Ports:** XHCI controller correctly mapped via `USBToolBox.kext` + `UTBDefault.kext`.
- **Audio:** Realtek ALC255 driven by `AppleALC.kext` (Layout ID: `23`).
- **Ethernet:** Realtek RTL8111 Gigabit Ethernet.
- **Storage Subsystem:** Intel NVMe SSD stable under `nand-io-timeoutms=60000`.

---

### ❌ Critical Hardware Limitations:

#### 1. Intel Iris Xe Graphics (Gen12 Xe-LP) — Metal 3D Hardware Acceleration Fails
- **Official Apple Architecture Support:** Apple **never produced any Mac computer powered by 11th Gen Intel (Tiger Lake) processors**. macOS possesses no native driver stack for Gen12 Intel Xe-LP architecture.
- **WhateverXe Driver Adaptation:** The community project `WhateverXe.kext` (v0.5.0) paired with the `WhateverXe-Graphics` driver package (v0.2.0) injects adapted driver payloads (`AppleIntelTGLGraphics.kext`).
- **Cause of Kernel Panic:**
  On newer macOS Tahoe builds (**`25G325` / Darwin 25.6.0**), kernel MMIO page structures differ from the author's target payload build (`25G241`). When 3D acceleration is invoked (`-allow3d`), the kernel triggers a **Page Fault Kernel Panic** (Type 14, Error code 2, Write violation on CR2 register `0xfffffffeac732b005`), causing emergency thermal fan ramp-up.
- **Current Operational Mode:**
  The system runs stably only in **Software Rendering / 2D Framebuffer mode** with the boot argument **`-wex-noaccel`**.

#### 2. NVIDIA GeForce MX350 (dGPU)
- Dedicated NVIDIA mobile graphics based on Pascal/Turing Optimus are **unsupported in modern macOS** (Apple dropped NVIDIA web driver support since macOS Mojave).
- The dGPU is permanently turned off via OpenCore `DeviceProperties` (`PciRoot(0x0)/Pci(0x6,0x0)/Pci(0x0,0x0)` -> `disable-gpu = 01000000`) to eliminate PCIe bus stalls and save battery.

---

## 🛠️ EFI Configuration Notes

### 1. Active Kexts (`Kernel -> Add`)
- `Lilu.kext` (v1.7.2)
- `AMFIPass.kext` (v1.4.1 Mod for WhateverXe trust anchors)
- `AppleALC.kext` (Audio ALC255)
- `RealtekRTL8111.kext` (Ethernet)
- `RestrictEvents.kext` (with `revpatch=sbvmm`)
- `VirtualSMC.kext` + `SMCBatteryManager.kext` + `SMCProcessor.kext`
  *(Note: `SMCSuperIO.kext` is DISABLED; laptops utilize Embedded Controllers, probing desktop LPC ports causes hardware hangs).*
- `USBToolBox.kext` + `UTBDefault.kext`
- `VoodooI2C.kext` + `VoodooI2CHID.kext`
  *(Note: `VoodooI2CELAN.kext` is DISABLED to prevent dual satellite driver races).*
- `VoodooPS2Controller.kext` (`VoodooPS2Keyboard.kext` enabled)
- `WhateverXe.kext` (v0.5.0)

### 2. Boot Arguments (`NVRAM -> 7C436110-AB2A-4BBB-A880-FE41995C9F82`)
```text
-v debug=0x100 keepsyms=1 -lilubetaall -wexbeta -wexdbg -wex-noaccel -disablegfxfirmware -igfxdvmt -amfipassbeta amfi=0x80 ipc_control_port_options=0 -vi2c-force-polling revpatch=sbvmm nand-io-timeoutms=60000
```

### 3. SIP (System Integrity Protection)
- `csr-active-config`: `<03080000>` (`0x803`), required for AMFIPass Mod and third-party driver signing validation on macOS Tahoe.

---

## 📁 Recovery & Helper Scripts

Two automation shell scripts are included for execution within the macOS Recovery Terminal:

1. **`setup_user.sh`:**
   - Bypasses the unaccelerated "Liquid Glass" *Setup Assistant* hang on initial boot.
   - Automatically provisions a local administrator account (`admin` / password: `1234`) and creates `.AppleSetupDone` and `.skipbuddy`.
2. **`remove_gpu.sh`:**
   - Safely cleans `AppleIntelTGL*` graphics kexts from `/Library/Extensions/` and wipes corrupted `AuxiliaryKernelExtensions.kc` if the machine encounters a bootloop/kernel panic.

---

## ⚠️ Conclusion & Recommendations

For daily productivity use, **macOS Tahoe is not recommended on Tiger Lake laptops** due to the absence of hardware graphics acceleration (Metal). Software rendering forces the CPU to composite modern translucent UI elements, resulting in a 1–5 FPS user experience.

This repository is maintained as a technical baseline, proof of concept, and research reference for future kernel-level driver development on Darwin.

---

## 🙏 Credits & Acknowledgements

Tremendous gratitude and appreciation to the open-source Hackintosh community and developers:

- [**Acidanthera**](https://github.com/acidanthera):
  - [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg) — Modular, powerful UEFI bootloader.
  - [Lilu](https://github.com/acidanthera/Lilu) — Versatile kernel patching engine.
  - [VirtualSMC](https://github.com/acidanthera/VirtualSMC) — Apple SMC emulator, battery manager, and processor sensors.
  - [AppleALC](https://github.com/acidanthera/AppleALC) — Native Realtek HD audio patcher.
  - [VoodooPS2](https://github.com/acidanthera/VoodooPS2) — Laptop PS/2 keyboard controller.
  - [RestrictEvents](https://github.com/acidanthera/RestrictEvents) — System capability and OTA update management.
- [**b00t0x**](https://github.com/b00t0x):
  - [WhateverXe](https://github.com/b00t0x/WhateverXe) — Pioneering Lilu plugin for Intel Xe-LP (Tiger Lake & Alder Lake) iGPUs.
  - [WhateverXe-Graphics](https://github.com/b00t0x/WhateverXe-Graphics) — Signed graphics payloads and Metal installer.
- [**dhinakg**](https://github.com/dhinakg):
  - [USBToolBox](https://github.com/USBToolBox/kext) — Cross-platform USB port mapping kext.
  - [AMFIPass](https://github.com/dhinakg/AMFIPass) — Apple Mobile File Integrity trust anchor controller.
- [**VoodooI2C Team**](https://github.com/VoodooI2C/VoodooI2C):
  - [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) & [VoodooI2CHID](https://github.com/VoodooI2C/VoodooI2CHID) — Precision I2C bus trackpad drivers.
- [**Mieze**](https://github.com/Mieze):
  - [RealtekRTL8111](https://github.com/Mieze/RTL8111_driver_for_OS_X) — PCIe Gigabit Ethernet driver.
- [**Dortania**](https://dortania.github.io/):
  - Authoritative *OpenCore Install Guide* and *Getting Started with ACPI*.
- [**Assaf Dori**](https://github.com/assafdori/bypass-mdm):
  - Offline Directory Services manipulation and Setup Assistant bypass techniques.
