.PHONY: build test install icon dist clean

build:
	./scripts/build.sh

test:
	swift run RouterTests

dist:
	./scripts/dist.sh

icon:
	./scripts/make_icon.sh

install:
	./scripts/install.sh

clean:
	swift package clean
	rm -rf .build/LinkRouter.app