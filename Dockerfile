FROM projectasiago/rustbuildenv:latest

# TODO build dependencies in separate step so they can be cached
# https://github.com/rust-lang/cargo/issues/2644

WORKDIR /usr/src/aura/
# copy our sources
COPY Cargo.toml Cargo.lock x86_64-unknown-efi.json /usr/src/aura/
COPY src /usr/src/aura/src

# build
RUN RUST_TARGET_PATH=/usr/src/aura/ xargo build --target x86_64-unknown-efi

# do some ARing n' shit
RUN cd target/x86_64-unknown-efi/debug && x86_64-efi-pe-ar x *.a

# link and build image
RUN mkdir -p build && \
	x86_64-efi-pe-ld --gc-sections --oformat pei-x86-64 --subsystem 10 -pie -e efi_main -o build/bootx64.efi target/x86_64-unknown-efi/debug/*.o && \
	dd if=/dev/zero of=fat.img bs=1k count=1440 && \
	mformat -i fat.img -f 1440 :: && \
	mmd -i fat.img ::/EFI && \
	mmd -i fat.img ::/EFI/BOOT && \
	mcopy -i fat.img build/bootx64.efi ::/EFI/BOOT && \
	mv fat.img build/boot.img