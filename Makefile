SWIFT_BUILD_FLAGS=--configuration release

.PHONY: all build clean xcode

all: build

build:
	swift build $(SWIFT_BUILD_FLAGS)

install: build
	echo "TBD"

clean:
	rm -rf .build

update:
	swift package update

run:
	swift run $(SWIFT_BUILD_FLAGS)
	
test:
	swift test --configuration debug

xcode:
	swift package generate-xcodeproj
