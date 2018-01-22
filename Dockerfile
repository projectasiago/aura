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

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
