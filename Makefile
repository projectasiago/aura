ARCH		= x86_64
TARGET_ARCH		= $(ARCH)-unknown-efi
BUILD_ROOT	= build
LOADER		= bootx64.efi
HD_IMG		= boot.img

OBJS	    = target/$(TARGET_ARCH)/debug/libuefi-sample.a

FORMAT		= efi-app-$(ARCH)
LDFLAGS		= --gc-sections --oformat pei-x86-64 --subsystem 10 -pie -e efi_main

prefix		= x86_64-efi-pe-
CC			= gcc
CXX			= g++
#CC			= $(prefix)gcc
#CXX			= $(prefix)g++
LD			= $(prefix)ld
AS			= $(prefix)as
AR			= $(prefix)ar
OBJCOPY		= $(prefix)objcopy
MFORMAT		= mformat
MMD			= mmd
MCOPY		= mcopy
RUSTC		= rustc
CARGO		= xargo

SRC	= $(wildcard src/*.rs)

TARGET = $(BUILD_ROOT)/$(LOADER)

.PHONY: all clean iso cargo

all: $(TARGET)

$(OBJS): $(SRC)
	RUST_TARGET_PATH=$(shell pwd) $(CARGO) build --target $(TARGET_ARCH)
	cd target/$(TARGET_ARCH)/debug && $(AR) x *.a

$(TARGET): $(OBJS)
	@mkdir -p $(BUILD_ROOT)
	$(LD) $(LDFLAGS) -o $@ $(dir $(OBJS))*.o

img: build/boot.img
build/boot.img: $(TARGET)
	@dd if=/dev/zero of=fat.img bs=1k count=1440
	@$(MFORMAT) -i fat.img -f 1440 ::
	@$(MMD) -i fat.img ::/EFI
	@$(MMD) -i fat.img ::/EFI/BOOT
	@$(MCOPY) -i fat.img $(TARGET) ::/EFI/BOOT
	@mv fat.img $(BUILD_ROOT)/$(HD_IMG)
	
img-docker: clean # clean is necessary, see https://github.com/japaric/xargo/issues/189
	docker build -t projectasiago/aura.build .
	docker run -it --rm \
		-e LOCAL_UID="$(shell id -u)" -e LOCAL_GID="$(shell id -g)" \
		-v aura-"$(id -u)-$(id -g)"-cargo:/usr/local/cargo \
		-v "$(shell pwd)":/usr/src/aura \
		-w /usr/src/aura projectasiago/aura.build \
		make img

clean:
	@$(CARGO) clean
	@rm -rf build fat.img
