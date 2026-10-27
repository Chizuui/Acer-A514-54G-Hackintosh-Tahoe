# Acer Aspire 5 A514-54G — macOS 26 Tahoe OpenCore EFI

**Bahasa Indonesia** | [English](README.md)

---

Konfigurasi OpenCore EFI untuk **Acer Aspire 5 (A514-54G)** yang menjalankan **macOS 26 Tahoe (Darwin 25.x)**.

> **Pemberitahuan Status:** macOS berhasil terinstall dan boot lancar sampai ke desktop, tetapi **akselerasi hardware grafis (Metal 3D) tidak berfungsi** pada prosesor Intel Generasi ke-11 Tiger Lake karena ketidakcocokan build macOS Tahoe (`25G325`). Silakan baca bagian [Batasan Hardware](#-batasan--kendala-kritis-hardware-limitations) di bawah untuk analisis teknis lengkap.

---

## 💻 Spesifikasi Hardware

| Komponen | Spesifikasi |
| :--- | :--- |
| **Model** | Acer Aspire 5 A514-54G |
| **CPU** | Intel Core 11th Gen Tiger Lake (e.g., i5-1135G7) |
| **iGPU** | Intel Iris Xe Graphics (PCI ID `0x9A78` / Gen12 Xe-LP) |
| **dGPU** | NVIDIA GeForce MX350 (2GB GDDR5) — *Dimatikan via DeviceProperties* |
| **Audio** | Realtek ALC255 (Layout ID: `23`) via AppleALC |
| **Ethernet** | Realtek RTL8168/8111 PCI-E Gigabit Ethernet |
| **Trackpad** | ELAN0522 (I2C HID Precision Touchpad) via VoodooI2C + VoodooI2CHID |
| **Keyboard** | Keyboard PS/2 Internal via VoodooPS2Controller |
| **Penyimpanan** | NVMe SSD (M.2 PCIe) + SATA AHCI |
| **OpenCore** | Versi 1.0.8 |
| **Target OS** | macOS 26 Tahoe (Build `25G325` / Darwin 25.6.0) |

---

## 📊 Status Komponen & Hasil Diagnosa

### ✅ Berfungsi Penuh (Working):
- **Bootloader & Boot Kernel:** OpenCore 1.0.8 berhasil menginisialisasi tabel kernel, patch ACPI, dan memory quirks (`RebuildAppleMemoryMap`, `DisableIoMapperMapping`).
- **Instalasi Sistem:** Berhasil partisi APFS, menyalin paket OS, dan menuntaskan 3 tahap reboot instalasi macOS Tahoe langsung ke NVMe SSD.
- **WindowServer & Framebuffer 2D:** Layar eDP laptop menyala pada resolusi native dan kursor mouse panah putih aktif serta responsif.
- **Sistem Input:** Keyboard internal (`VoodooPS2Keyboard`), USB Gaming Keyboard, Mouse Wireless 2.4G, dan Trackpad ELAN0522 (`VoodooI2CHID`).
- **Controller & Port USB:** Port XHCI terpetakan dan berjalan via `USBToolBox.kext` + `UTBDefault.kext`.
- **Audio:** Realtek ALC255 dengan `AppleALC.kext` (Layout ID: `23`).
- **Ethernet:** Realtek RTL8111 Gigabit Ethernet.
- **Subsistem Penyimpanan:** NVMe SSD stabil dengan `nand-io-timeoutms=60000`.

---

### ❌ Batasan & Kendala Kritis (Hardware Limitations):

#### 1. Intel Iris Xe Graphics (Gen12 Xe-LP) — Akselerasi Hardware (Metal 3D) GAGAL
- **Fakta Resmi Apple:** Apple **tidak pernah merilis komputer Mac berbasis prosesor Intel Generasi ke-11 (Tiger Lake)**. macOS tidak memiliki driver grafis native resmi untuk arsitektur Intel Xe-LP.
- **Eksperimen Driver WhateverXe:** Proyek Lilu plugin `WhateverXe.kext` (v0.5.0) dan paket driver `WhateverXe-Graphics` (v0.2.0) mencoba mengadaptasi sisa driver internal Apple (`AppleIntelTGLGraphics.kext`).
- **Penyebab Kernel Panic:**
  Pada macOS Tahoe build baru (**`25G325` / Darwin 25.6.0**), struktur tabel memori MMIO internal kernel berbeda dengan target build payload driver (`25G241`). Saat driver 3D diaktifkan (`-allow3d`), kernel mengalami **Page Fault Kernel Panic** (Tipe 14, Error code 2, Write violation pada register CR2 `0xfffffffeac732b005`) yang memicu perputaran kipas darurat dan panas berlebih.
- **Status Saat Ini:**
  Hanya bisa berjalan stabil dalam mode **Software Rendering / 2D Framebuffer dasar** menggunakan boot-arg **`-wex-noaccel`**.

#### 2. NVIDIA GeForce MX350 (dGPU)
- Kartu grafis diskrit NVIDIA berbasis arsitektur Pascal/Turing Optimus **tidak didukung macOS** (Apple menghentikan dukungan web driver sejak macOS Mojave).
- dGPU telah dimatikan secara permanen melalui `DeviceProperties` (`PciRoot(0x0)/Pci(0x6,0x0)/Pci(0x0,0x0)` -> `disable-gpu = 01000000`) agar hemat daya dan tidak memicu freeze PCIe bus.

---

## 🛠️ Catatan Konfigurasi EFI

### 1. Kexts yang Aktif (`Kernel -> Add`)
- `Lilu.kext` (v1.7.2)
- `AMFIPass.kext` (v1.4.1 Mod untuk signing chain WhateverXe)
- `AppleALC.kext` (Audio ALC255)
- `RealtekRTL8111.kext` (Ethernet)
- `RestrictEvents.kext` (dengan `revpatch=sbvmm`)
- `VirtualSMC.kext` + `SMCBatteryManager.kext` + `SMCProcessor.kext`
  *(Catatan: `SMCSuperIO.kext` DINONAKTIFKAN karena laptop Acer menggunakan Embedded Controller; probing port LPC desktop memicu hang).*
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

---

## 🙏 Credits & Acknowledgements

Ucapan terima kasih dan apresiasi sebesar-besarnya kepada seluruh pengembang open-source yang karyanya memungkinkan berjalannya macOS pada perangkat non-Apple:

- [**Acidanthera**](https://github.com/acidanthera):
  - [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg) — Bootloader UEFI modular yang tangguh.
  - [Lilu](https://github.com/acidanthera/Lilu) — Mesin patching kernel runtime serbaguna.
  - [VirtualSMC](https://github.com/acidanthera/VirtualSMC) — Emulasi chip Apple System Management Controller beserta plugin baterai dan prosesor.
  - [AppleALC](https://github.com/acidanthera/AppleALC) — Patcher audio HD Realtek native tanpa merusak kext sistem.
  - [VoodooPS2](https://github.com/acidanthera/VoodooPS2) — Driver antarmuka keyboard laptop internal.
  - [RestrictEvents](https://github.com/acidanthera/RestrictEvents) — Pengendali kompatibilitas model Mac dan pembaruan OTA.
- [**b00t0x**](https://github.com/b00t0x):
  - [WhateverXe](https://github.com/b00t0x/WhateverXe) — Lilu plugin inovatif untuk adaptasi iGPU Intel Xe-LP (Tiger Lake & Alder Lake).
  - [WhateverXe-Graphics](https://github.com/b00t0x/WhateverXe-Graphics) — Signed payload dan installer driver Metal untuk grafis Intel Xe.
- [**dhinakg**](https://github.com/dhinakg):
  - [USBToolBox](https://github.com/USBToolBox/kext) — Driver mapping port USB lintas platform.
  - [AMFIPass](https://github.com/dhinakg/AMFIPass) — Pengendali trust anchor AMFI untuk kext pihak ketiga.
- [**VoodooI2C Team**](https://github.com/VoodooI2C/VoodooI2C):
  - [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) & [VoodooI2CHID](https://github.com/VoodooI2C/VoodooI2CHID) — Driver bus I2C presisi untuk touchpad laptop modern.
- [**Mieze**](https://github.com/Mieze):
  - [RealtekRTL8111](https://github.com/Mieze/RTL8111_driver_for_OS_X) — Driver ethernet Realtek PCIe Gigabit.
- [**Dortania**](https://dortania.github.io/):
  - Panduan komprehensif *OpenCore Install Guide* dan *Getting Started with ACPI*.
- [**Assaf Dori**](https://github.com/assafdori/bypass-mdm):
  - Referensi teknik manipulasi direktori akun lokal dan bypass `.AppleSetupDone` via Recovery.
