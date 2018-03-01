all: build/boot.img

build/boot.img: empty
	RUST_TARGET_PATH=$(shell pwd) RUSTFLAGS='-Z external-macro-backtrace' xargo build --target x86_64-unknown-efi
	(cd target/x86_64-unknown-efi/debug && x86_64-efi-pe-ar x *.a)
	mkdir -p build
	x86_64-efi-pe-ld --gc-sections --oformat pei-x86-64 --subsystem 10 -pie -e efi_main -o build/bootx64.efi target/x86_64-unknown-efi/debug/*.o
	dd if=/dev/zero of=fat.img bs=1k count=1440
	mformat -i fat.img -f 1440 ::
	mmd -i fat.img ::/EFI
	mmd -i fat.img ::/EFI/BOOT
	mcopy -i fat.img build/bootx64.efi ::/EFI/BOOT
	mv fat.img build/boot.img

clean:
	@rm -rf build target fat.img

.PHONY:
empty: