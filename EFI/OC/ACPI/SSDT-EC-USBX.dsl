/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20260408 (32-bit version)
 * Copyright (c) 2000 - 2026 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of EFI-OpCore-Tahoe/OC/ACPI/SSDT-EC-USBX.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000108 (264)
 *     Revision         0x02
 *     Checksum         0x80
 *     OEM ID           "HACK"
 *     OEM Table ID     "ECUSBX"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20260408 (539362312)
 */
DefinitionBlock ("", "SSDT", 2, "HACK", "ECUSBX", 0x00000000)
{
    Scope (\_SB)
    {
        Device (EC)
        {
            Name (_HID, EisaId ("PNP0C09") /* Embedded Controller Device */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }

                Return (Zero)
            }
        }

        Device (USBX)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Name (_HID, EisaId ("PNP0A03") /* PCI Bus */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }

                Return (Zero)
            }

            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                If ((Arg2 == Zero))
                {
                    Return (Buffer (One)
                    {
                         0x03                                             // .
                    })
                }

                Return (Package (0x08)
                {
                    0x0A, 
                    Package (0x18)
                    {
                        One, 
                        Zero, 
                        Zero, 
                        Zero, 
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero, 
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero, 
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero
                    }, 

                    Package (0x20)
                    {
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero, 
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero, 
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero, 
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero, 
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero, 
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero, 
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero, 
                        0xF0, 
                        0x0F, 
                        Zero, 
                        Zero
                    }, 

                    0x08, 
                    0x0B, 
                    Zero, 
                    Zero
                })
            }
        }
    }
}

