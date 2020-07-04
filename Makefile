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

xcode:
	swift package generate-xcodeproj
	sed -i .backup 's/PLATFORM_SUPPORTS_PONYRT/PLATFORM_SUPPORTS_PONYRT_DISABLED/g' jukebox2.xcodeproj/project.pbxproj
