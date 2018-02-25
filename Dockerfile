FROM ubuntu:artful

ENV RUSTUP_HOME=/usr/local/rustup \
	CARGO_HOME=/usr/local/cargo \
	TOOLCHAIN_HOME=/usr/local/toolchain \
	PATH=/usr/local/cargo/bin:/usr/local/toolchain/usr/bin/:$PATH

RUN apt-get update && apt-get -y install curl gcc make xz-utils mtools gosu
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain none -y --no-modify-path
RUN rustup toolchain install stable
RUN rustup toolchain install nightly
RUN rustup default nightly
RUN rustup component add rust-src
RUN cargo install xargo
RUN mkdir -p $TOOLCHAIN_HOME
RUN curl https://orum.in/distfiles/x86_64-efi-pe-binutils.tar.xz | tar xfJ - -C $TOOLCHAIN_HOME

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