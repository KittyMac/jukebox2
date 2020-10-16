SWIFT_BUILD_FLAGS=--configuration release

.PHONY: all build clean xcode

all: build

build:
	swift build $(SWIFT_BUILD_FLAGS)

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
	meta/addBuildPhase jukebox2.xcodeproj/project.pbxproj "jukebox2::jukebox2" 'cd $${SRCROOT}; ./meta/CombinedBuildPhases.sh'
	

install: build
	
	sudo systemctl stop jukebox
	
	sudo cp .build/release/jukebox2 /usr/local/bin
	sudo cp meta/jukebox.service /etc/systemd/system/jukebox.service
		
	sudo systemctl start jukebox
	sudo systemctl enable jukebox