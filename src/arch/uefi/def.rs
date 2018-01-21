type EFI_HANDLE = * ();

// http://www.uefi.org/sites/default/files/resources/UEFI%20Spec%202_7_A%20Sept%206.pdf#G8.1001729
struct EFI_TABLE_HEADER {
	Signature: u64,
	Revision: u32,
	HeaderSize: u32,
	CRC32: u32,
	Reserved: u32,
}

// http://www.uefi.org/sites/default/files/resources/UEFI%20Spec%202_7_A%20Sept%206.pdf#G8.1001773
struct EFI_SYSTEM_TABLE {
	Hdr: EFI_TABLE_HEADER,
	FirmwareVendor: * u16,
	FirmwareRevision: u32,
	ConsoleInHandle: EFI_HANDLE,
	ConIn: * EFI_SIMPLE_TEXT_INPUT_PROTOCOL,
	ConsoleOutHandle: EFI_HANDLE,
	ConOut: * EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL,
	StandardErrorHandle: EFI_HANDLE,
	StdErr: * EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL,
	RuntimeServices: *EFI_RUNTIME_SERVICES,
	BootServices: *EFI_BOOT_SERVICES,
	NumberOfTableEntries: usize,
	ConfigurationTable: *EFI_CONFIGURATION_TABLE
}

struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
	Reset : EFI_TEXT_RESET,
	OutputString : EFI_TEXT_STRING,
	// ... and more stuff that we're ignoring.
}

type EFI_TEXT_RESET = *();

type EFI_TEXT_STRING = extern fn(*EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL,
                                 *u16);