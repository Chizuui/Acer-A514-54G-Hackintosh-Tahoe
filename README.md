# Acer Aspire 5 A514-54G — macOS 26 Tahoe OpenCore EFI

OpenCore EFI configuration for **Acer Aspire 5 (A514-54G)** running **macOS 26 Tahoe (Darwin 25.x)**.

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

## 📊 Status Komponen & Kesimpulan Hardware

### ✅ Yang Berfungsi Penuh (Working):
- **Bootloader & Kernel Boot:** OpenCore 1.0.8 lolos inisialisasi kernel, ACPI patch, dan memory quirks (`RebuildAppleMemoryMap`, `DisableIoMapperMapping`).
- **Instalasi Sistem:** Berhasil partisi APFS, menyalin paket OS, dan menuntaskan 3 tahap reboot instalasi macOS Tahoe langsung ke NVMe SSD.
- **WindowServer & 2D Framebuffer:** Layar eDP laptop menyala pada resolusi native dan kursor mouse panah putih aktif serta responsif.
- **Input System:** Keyboard internal (`VoodooPS2Keyboard`), USB Gaming Keyboard, Mouse Wireless 2.4G, dan Trackpad (`VoodooI2CHID`).
- **USB Controller & Ports:** Port XHCI terpetakan dan berjalan via `USBToolBox.kext` + `UTBDefault.kext`.
- **Audio:** Realtek ALC255 dengan `AppleALC.kext` (Layout ID: `23`).
- **Ethernet:** Realtek RTL8111 Gigabit Ethernet.
- **Disk I/O:** NVMe SSD Intel 660p terdeteksi dan stabil dengan `nand-io-timeoutms=60000`.

---

### ❌ Batasan & Kendala Kritis (Hardware Limitations):

### 1. Intel Iris Xe Graphics (Gen12 Xe-LP) — Akselerasi Hardware (Metal 3D) GAGAL
- **Fakta Resmi Apple:** Apple **tidak pernah merilis komputer Mac berbasis prosesor Intel Generasi ke-11 (Tiger Lake)**. macOS tidak memiliki driver grafis native resmi untuk arsitektur Intel Xe-LP.
- **Eksperimen Driver WhateverXe:** Proyek Lilu plugin `WhateverXe.kext` (v0.5.0) dan paket driver `WhateverXe-Graphics` (v0.2.0) mencoba mengadaptasi sisa driver internal Apple (`AppleIntelTGLGraphics.kext`).
- **Penyebab Kernel Panic:**
  Pada macOS Tahoe build baru (**`25G325` / Darwin 25.6.0**), struktur tabel memori MMIO internal kernel berbeda dengan target build payload driver (`25G241`). Saat driver 3D diaktifkan (`-allow3d`), kernel mengalami **Page Fault Kernel Panic** (Error code 2, Write violation pada register CR2) yang memicu perputaran kipas darurat dan panas berlebih.
- **Status Saat Ini:**
  Hanya bisa berjalan stabil dalam mode **Software Rendering / 2D Framebuffer dasar** menggunakan boot-arg **`-wex-noaccel`**.

### 2. NVIDIA GeForce MX350 (dGPU)
- Kartu grafis diskrit NVIDIA berbasis arsitektur Pascal/Turing Optimus **tidak didukung macOS** (Apple menghentikan dukungan web driver sejak macOS Mojave).
- dGPU telah dimatikan secara permanen melalui `DeviceProperties` (`PciRoot(0x0)/Pci(0x6,0x0)/Pci(0x0,0x0)` -> `disable-gpu = 01000000`) agar hemat daya dan tidak memicu freeze PCIe bus.

---

## 🛠️ Catatan Konfigurasi EFI

### 1. Kexts yang Diterapkan (`Kernel -> Add`)
- `Lilu.kext` (v1.7.2)
- `AMFIPass.kext` (v1.4.1 Mod untuk signing chain WhateverXe)
- `AppleALC.kext` (Audio ALC255)
- `RealtekRTL8111.kext` (Ethernet)
- `RestrictEvents.kext` (dengan `revpatch=sbvmm`)
- `VirtualSMC.kext` + `SMCBatteryManager.kext` + `SMCProcessor.kext`
  *(Catatan: `SMCSuperIO.kext` DINONAKTIFKAN karena laptop Acer tidak memiliki chip SuperIO desktop; probing port LPC-nya memicu freeze).*
- `USBToolBox.kext` + `UTBDefault.kext`
- `VoodooI2C.kext` + `VoodooI2CHID.kext`
  *(Catatan: `VoodooI2CELAN.kext` DINONAKTIFKAN untuk menghindari deadlock bus I2C ganda).*
- `VoodooPS2Controller.kext` (`VoodooPS2Keyboard.kext` aktif)
- `WhateverXe.kext` (v0.5.0)

### 2. Boot Arguments (`NVRAM -> 7C436110-AB2A-4BBB-A880-FE41995C9F82`)
```text
-v debug=0x100 keepsyms=1 -lilubetaall -wexbeta -wexdbg -wex-noaccel -disablegfxfirmware -igfxdvmt -amfipassbeta amfi=0x80 ipc_control_port_options=0 -vi2c-force-polling revpatch=sbvmm nand-io-timeoutms=60000
```

### 3. SIP (System Integrity Protection)
- Nilai `csr-active-config`: `<03080000>` (`0x803`), syarat wajib lingkungan AMFIPass Mod & instalasi driver eksternal di Tahoe.

---

## 📁 Skrip Utilitas Pembantu (Recovery Tools)

Repo ini menyertakan 2 skrip bash darurat yang bisa dijalankan dari macOS Recovery Terminal:

1. **`setup_user.sh`:**
   - Mem-bypass antarmuka *Setup Assistant* ("Liquid Glass") yang macet saat pertama kali boot tanpa akselerasi Metal.
   - Otomatis membuat akun admin lokal (`admin` / password: `1234`) dan menyuntikkan `.AppleSetupDone` serta `.skipbuddy`.
2. **`remove_gpu.sh`:**
   - Membersihkan kext grafis `AppleIntelTGL*` dari `/Library/Extensions/` dan menghapus `AuxiliaryKernelExtensions.kc` jika sistem mengalami bootloop/kernel panic.

---

## ⚠️ Kesimpulan & Saran

Jika tujuan instalasi adalah untuk penggunaan harian (Daily Driver), **macOS Tahoe belum layak digunakan pada laptop Tiger Lake** karena ketiadaan akselerasi hardware grafis (Metal). Menjalankan antarmuka modern macOS murni berbasis software rendering CPU menghasilkan performa tampilan yang sangat lambat (1–5 FPS).

Gunakan EFI ini sebagai bahan riset, dokumentasi eksperimen, atau basis pengembangan lanjutan driver WhateverXe pada kernel Darwin generasi mendatang.
