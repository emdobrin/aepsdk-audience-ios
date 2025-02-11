export EXTENSION_NAME = AEPAudience
PROJECT_NAME = $(EXTENSION_NAME)
SCHEME_NAME_XCFRAMEWORK = AEPAudience

CURR_DIR := ${CURDIR}
SIMULATOR_ARCHIVE_PATH = $(CURR_DIR)/build/ios_simulator.xcarchive/Products/Library/Frameworks/
SIMULATOR_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios_simulator.xcarchive/dSYMs/
IOS_ARCHIVE_PATH = $(CURR_DIR)/build/ios.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios.xcarchive/dSYMs/

TEST_APP_IOS_SCHEME = AudienceSampleApp

pod-repo-update:
	pod repo update

pod-install:
	pod install --repo-update

ci-pod-install:
	bundle exec pod install --repo-update

pod-update: pod-repo-update
	pod update

open:
	open $(PROJECT_NAME).xcworkspace

test-ios: clean-ios-test-files
	@echo "######################################################################"
	@echo "### Testing iOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(PROJECT_NAME) -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath build/out -resultBundlePath iosresults.xcresult -enableCodeCoverage YES

archive: clean pod-update
	@echo "######################################################################"
	@echo "### Generating iOS Frameworks for $(PROJECT_NAME)"
	@echo "######################################################################"
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(PROJECT_NAME) -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(PROJECT_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(EXTENSION_NAME).framework.dSYM -framework $(IOS_ARCHIVE_PATH)$(PROJECT_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(EXTENSION_NAME).framework.dSYM -output ./build/$(PROJECT_NAME).xcframework

zip:
	cd build && zip -r -X $(PROJECT_NAME).xcframework.zip $(PROJECT_NAME).xcframework/
	swift package compute-checksum build/$(PROJECT_NAME).xcframework.zip

build-app: pod-install
	@echo "######################################################################"
	@echo "### Building $(TEST_APP_IOS_SCHEME)"
	@echo "######################################################################"
	xcodebuild clean build -workspace $(PROJECT_NAME).xcworkspace -scheme $(TEST_APP_IOS_SCHEME) -destination 'generic/platform=iOS Simulator'

clean:
	rm -rf ./build

clean-ios-test-files:
	rm -rf iosresults.xcresult

lint:
	./Pods/SwiftLint/swiftlint lint AEPAudience/Sources

lint-autocorrect:
	./Pods/SwiftLint/swiftlint --fix

# release checks
# make check-version VERSION=4.0.0
check-version:
	sh ./Script/version.sh $(VERSION)

test-SPM-integration:
	sh ./Script/test-SPM.sh

test-podspec:
	sh ./Script/test-podspec.sh

# make bump-versions from='3\.1\.0' to=3.1.1
bump-versions:
	(LC_ALL=C find . -type f -name 'project.pbxproj' -exec sed -i '' 's/$(from)/$(to)/' {} +)
	(LC_ALL=C find . -type f -name '*.swift' -exec sed -i '' 's/$(from)/$(to)/' {} +)
	(LC_ALL=C find . -type f -name '*.podspec' -exec sed -i '' 's/$(from)/$(to)/' {} +)
