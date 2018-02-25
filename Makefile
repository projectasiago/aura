all: build/boot.img

build/boot.img: empty
	# run the build
	docker build -t projectasiago/aura .
	
	# copy the build result out
	mkdir -p build/
	docker run --rm --entrypoint cat projectasiago/aura build/boot.img > build/boot.img

clean:
	@rm -rf build

.PHONY:
empty: