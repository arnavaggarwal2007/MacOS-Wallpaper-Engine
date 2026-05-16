arnev@Arnavs-MacBook-Pro Personal Wallpaper Engine % TMPDIR="/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1" ./scripts/chunk7_smoke.sh
DerivedData: /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369
Building project...
Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild clean build -project "/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine.xcodeproj" -scheme "Personal Wallpaper Engine" -configuration Debug -derivedDataPath /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369

2026-05-15 13:54:03.117 xcodebuild[56375:241103] [MT] IDERunDestination: Supported platforms for the buildables in the current scheme is empty.
--- xcodebuild: WARNING: Using the first of multiple matching destinations:
{ platform:macOS, arch:arm64, id:00006040-0002713E1460801C, name:My Mac }
{ platform:macOS, arch:x86_64, id:00006040-0002713E1460801C, name:My Mac }
{ platform:macOS, name:Any Mac }
CreateBuildRequest

SendProjectDescription

CreateBuildOperation

** CLEAN SUCCEEDED **

--- xcodebuild: WARNING: Using the first of multiple matching destinations:
{ platform:macOS, arch:arm64, id:00006040-0002713E1460801C, name:My Mac }
{ platform:macOS, arch:x86_64, id:00006040-0002713E1460801C, name:My Mac }
{ platform:macOS, name:Any Mac }
ComputePackagePrebuildTargetDependencyGraph

Prepare packages

CreateBuildRequest

SendProjectDescription

CreateBuildOperation

ComputeTargetDependencyGraph
note: Building targets in dependency order
note: Target dependency graph (1 target)
    Target 'Personal Wallpaper Engine' in project 'Personal Wallpaper Engine' (no dependencies)

GatherProvisioningInputs

CreateBuildDescription

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -v -E -dM -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -x c -c /dev/null

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/actool --version --output-format xml1

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc --version

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld -version_details

Build description signature: 99c250ebc5a7e0230e91281120557d7e
Build description path: /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/XCBuildData/99c250ebc5a7e0230e91281120557d7e.xcbuilddata
ClangStatCache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -o /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/ExplicitPrecompiledModules
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/ExplicitPrecompiledModules

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/EagerLinkingTBDs/Debug
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/EagerLinkingTBDs/Debug

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine-fa84f85574cad5040bb4c3dd096b0aa8-VFS/all-product-headers.yaml
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine-fa84f85574cad5040bb4c3dd096b0aa8-VFS/all-product-headers.yaml

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyStaticMetadataFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyMetadataFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyMetadataFileList

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibPath-normal-arm64.txt (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibPath-normal-arm64.txt

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-non-framework-target-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-non-framework-target-headers.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibInstallName-normal-arm64.txt (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibInstallName-normal-arm64.txt

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftFileList

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine-OutputFileMap.json (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine-OutputFileMap.json

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.LinkFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.LinkFileList

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftConstValuesFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/Entitlements.plist (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/Entitlements.plist

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app

ProcessProductPackaging /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.entitlements /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    
    Entitlements:
    
    {
    "com.apple.security.app-sandbox" = 1;
    "com.apple.security.files.bookmarks.app-scope" = 1;
    "com.apple.security.files.user-selected.read-only" = 1;
    "com.apple.security.get-task-allow" = 1;
}
    
    builtin-productPackagingUtility /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.entitlements -entitlements -format xml -o /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent

ProcessProductPackagingDER /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent.der (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /usr/bin/derq query -f xml -i /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent -o /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent.der --raw

Ld /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS/__preview.dylib normal (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-macos26.2 -dynamiclib -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -O0 -L/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug -F/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug -install_name @rpath/Personal\ Wallpaper\ Engine.debug.dylib -rdynamic -Xlinker -no_deduplicate -Xlinker -dependency_info -Xlinker /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_dependency_info.dat -Xlinker -no_adhoc_codesign -o /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS/__preview.dylib

GenerateAssetSymbols /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /Applications/Xcode.app/Contents/Developer/usr/bin/actool /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets --compile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources --output-format human-readable-text --notices --warnings --export-dependency-info /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies --output-partial-info-plist /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist --app-icon AppIcon --accent-color AccentColor --enable-on-demand-resources NO --development-region en --target-device mac --minimum-deployment-target 26.2 --platform macosx --bundle-identifier Personal.Personal-Wallpaper-Engine --generate-swift-asset-symbols /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols.swift --generate-objc-asset-symbols /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols.h --generate-asset-symbol-index /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols-Index.plist
/* com.apple.actool.compilation-results */
/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/DerivedSources/GeneratedAssetSymbols-Index.plist
/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/DerivedSources/GeneratedAssetSymbols.h
/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/DerivedSources/GeneratedAssetSymbols.swift


CpResource /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources/Feature-Contract-Phase-6A.md /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Features/Feature-Contract-Phase-6A.md (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Features/Feature-Contract-Phase-6A.md /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/unthinned (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/unthinned

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned

CompileAssetCatalogVariant thinned /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /Applications/Xcode.app/Contents/Developer/usr/bin/actool /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets --compile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned --output-format human-readable-text --notices --warnings --export-dependency-info /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies_thinned --output-partial-info-plist /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist_thinned --app-icon AppIcon --accent-color AccentColor --enable-on-demand-resources NO --development-region en --target-device mac --minimum-deployment-target 26.2 --platform macosx
/* com.apple.actool.compilation-results */
/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/assetcatalog_generated_info.plist_thinned


LinkAssetCatalog /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-linkAssetCatalog --thinned /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned --thinned-dependencies /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies_thinned --thinned-info-plist-content /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist_thinned --unthinned /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/unthinned --unthinned-dependencies /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies_unthinned --unthinned-info-plist-content /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist_unthinned --output /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources --plist-output /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist

ProcessInfoPlistFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Info.plist /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-infoPlistUtility /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist -producttype com.apple.product-type.application -genpkginfo /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/PkgInfo -expandbuildsettings -platform macosx -additionalcontentfile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist -o /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Info.plist

SwiftDriver Personal\ Wallpaper\ Engine normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name Personal_Wallpaper_Engine -Onone -enforce-exclusivity\=checked @/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftFileList -DDEBUG -default-isolation\=MainActor -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -target arm64-apple-macos26.2 -g -module-cache-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -index-store-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug -F /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug -emit-localized-strings -emit-localized-strings-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64 -c -j12 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache -output-file-map /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/ModuleCache.noindex -sdk-module-cache-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json -Xcc -iquote -Xcc /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap -Xcc -iquote -Xcc /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Products/Debug/include -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources-normal/arm64 -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/arm64 -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_56369/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine-Swift.h -working-directory /Users/arnev/Desktop/Personal\ Wallpaper\ Engine -experimental-emit-module-separately -disable-cmo
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/UI/DesignTokens.swift:54:1: error: extraneous '}' at top level
}
^
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/UI/DesignTokens.swift:56:16: error: static properties may only be declared on a type
        static let cardBackdropOpacity: Double = 0.04
        ~~~~~~~^
        
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/UI/DesignTokens.swift:54:1: error: Extraneous '}' at top level
}
^ (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/UI/DesignTokens.swift:56:16: error: Static properties may only be declared on a type
        static let cardBackdropOpacity: Double = 0.04
        ~~~~~~~^
         (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

** BUILD FAILED **


The following build commands failed:
	SwiftDriver Personal\ Wallpaper\ Engine normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
	Building project Personal Wallpaper Engine with scheme Personal Wallpaper Engine and configuration Debug
(2 failures)
arnev@Arnavs-MacBook-Pro Personal Wallpaper Engine % TMPDIR="/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1" ./scripts/chunk7_regression.sh
Regression run started: 20260515-135421
DerivedData: /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421

--- Building configuration: Debug ---
Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild clean build -project "Personal Wallpaper Engine.xcodeproj" -scheme "Personal Wallpaper Engine" -configuration Debug -derivedDataPath /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421

2026-05-15 13:54:21.925 xcodebuild[56405:241779] [MT] IDERunDestination: Supported platforms for the buildables in the current scheme is empty.
--- xcodebuild: WARNING: Using the first of multiple matching destinations:
{ platform:macOS, arch:arm64, id:00006040-0002713E1460801C, name:My Mac }
{ platform:macOS, arch:x86_64, id:00006040-0002713E1460801C, name:My Mac }
{ platform:macOS, name:Any Mac }
CreateBuildRequest

SendProjectDescription

CreateBuildOperation

** CLEAN SUCCEEDED **

--- xcodebuild: WARNING: Using the first of multiple matching destinations:
{ platform:macOS, arch:arm64, id:00006040-0002713E1460801C, name:My Mac }
{ platform:macOS, arch:x86_64, id:00006040-0002713E1460801C, name:My Mac }
{ platform:macOS, name:Any Mac }
ComputePackagePrebuildTargetDependencyGraph

Prepare packages

CreateBuildRequest

SendProjectDescription

CreateBuildOperation

ComputeTargetDependencyGraph
note: Building targets in dependency order
note: Target dependency graph (1 target)
    Target 'Personal Wallpaper Engine' in project 'Personal Wallpaper Engine' (no dependencies)

GatherProvisioningInputs

CreateBuildDescription

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -v -E -dM -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -x c -c /dev/null

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/actool --version --output-format xml1

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc --version

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld -version_details

Build description signature: d10e7c23f12bef5f1076269a7dab8653
Build description path: /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/XCBuildData/d10e7c23f12bef5f1076269a7dab8653.xcbuilddata
ClangStatCache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -o /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/ExplicitPrecompiledModules
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/ExplicitPrecompiledModules

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug

CreateBuildDirectory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/EagerLinkingTBDs/Debug
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/EagerLinkingTBDs/Debug

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine-fa84f85574cad5040bb4c3dd096b0aa8-VFS/all-product-headers.yaml
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine-fa84f85574cad5040bb4c3dd096b0aa8-VFS/all-product-headers.yaml

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyStaticMetadataFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyMetadataFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyMetadataFileList

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-non-framework-target-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-non-framework-target-headers.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibPath-normal-arm64.txt (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibPath-normal-arm64.txt

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibInstallName-normal-arm64.txt (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibInstallName-normal-arm64.txt

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftConstValuesFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftFileList

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.LinkFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.LinkFileList

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine-OutputFileMap.json (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine-OutputFileMap.json

WriteAuxiliaryFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/Entitlements.plist (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/Entitlements.plist

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app

ProcessProductPackaging /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.entitlements /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    
    Entitlements:
    
    {
    "com.apple.security.app-sandbox" = 1;
    "com.apple.security.files.bookmarks.app-scope" = 1;
    "com.apple.security.files.user-selected.read-only" = 1;
    "com.apple.security.get-task-allow" = 1;
}
    
    builtin-productPackagingUtility /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.entitlements -entitlements -format xml -o /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent

ProcessProductPackagingDER /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent.der (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /usr/bin/derq query -f xml -i /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent -o /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent.der --raw

Ld /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS/__preview.dylib normal (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-macos26.2 -dynamiclib -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -O0 -L/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug -F/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug -install_name @rpath/Personal\ Wallpaper\ Engine.debug.dylib -rdynamic -Xlinker -no_deduplicate -Xlinker -dependency_info -Xlinker /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_dependency_info.dat -Xlinker -no_adhoc_codesign -o /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS/__preview.dylib

GenerateAssetSymbols /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /Applications/Xcode.app/Contents/Developer/usr/bin/actool /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets --compile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources --output-format human-readable-text --notices --warnings --export-dependency-info /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies --output-partial-info-plist /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist --app-icon AppIcon --accent-color AccentColor --enable-on-demand-resources NO --development-region en --target-device mac --minimum-deployment-target 26.2 --platform macosx --bundle-identifier Personal.Personal-Wallpaper-Engine --generate-swift-asset-symbols /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols.swift --generate-objc-asset-symbols /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols.h --generate-asset-symbol-index /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols-Index.plist
/* com.apple.actool.compilation-results */
/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/DerivedSources/GeneratedAssetSymbols-Index.plist
/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/DerivedSources/GeneratedAssetSymbols.h
/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/DerivedSources/GeneratedAssetSymbols.swift


MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned

CpResource /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources/Feature-Contract-Phase-6A.md /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Features/Feature-Contract-Phase-6A.md (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Features/Feature-Contract-Phase-6A.md /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources

MkDir /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/unthinned (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/unthinned

CompileAssetCatalogVariant thinned /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /Applications/Xcode.app/Contents/Developer/usr/bin/actool /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets --compile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned --output-format human-readable-text --notices --warnings --export-dependency-info /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies_thinned --output-partial-info-plist /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist_thinned --app-icon AppIcon --accent-color AccentColor --enable-on-demand-resources NO --development-region en --target-device mac --minimum-deployment-target 26.2 --platform macosx
/* com.apple.actool.compilation-results */
/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/assetcatalog_generated_info.plist_thinned


LinkAssetCatalog /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-linkAssetCatalog --thinned /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned --thinned-dependencies /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies_thinned --thinned-info-plist-content /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist_thinned --unthinned /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/unthinned --unthinned-dependencies /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies_unthinned --unthinned-info-plist-content /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist_unthinned --output /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources --plist-output /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist

ProcessInfoPlistFile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Info.plist /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-infoPlistUtility /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist -producttype com.apple.product-type.application -genpkginfo /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/PkgInfo -expandbuildsettings -platform macosx -additionalcontentfile /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist -o /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Info.plist

SwiftDriver Personal\ Wallpaper\ Engine normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name Personal_Wallpaper_Engine -Onone -enforce-exclusivity\=checked @/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftFileList -DDEBUG -default-isolation\=MainActor -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -target arm64-apple-macos26.2 -g -module-cache-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -index-store-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug -F /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug -emit-localized-strings -emit-localized-strings-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64 -c -j12 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache -output-file-map /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/ModuleCache.noindex -sdk-module-cache-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json -Xcc -iquote -Xcc /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap -Xcc -iquote -Xcc /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Products/Debug/include -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources-normal/arm64 -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/arm64 -Xcc -I/Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/arnev/.vscode-insiders/tmp/tmp_vscode_1/DerivedData_regression_20260515-135421/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine-Swift.h -working-directory /Users/arnev/Desktop/Personal\ Wallpaper\ Engine -experimental-emit-module-separately -disable-cmo
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/UI/DesignTokens.swift:54:1: error: extraneous '}' at top level
}
^
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/UI/DesignTokens.swift:56:16: error: static properties may only be declared on a type
        static let cardBackdropOpacity: Double = 0.04
        ~~~~~~~^
        
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/UI/DesignTokens.swift:54:1: error: Extraneous '}' at top level
}
^ (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/UI/DesignTokens.swift:56:16: error: Static properties may only be declared on a type
        static let cardBackdropOpacity: Double = 0.04
        ~~~~~~~^
         (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

** BUILD FAILED **


The following build commands failed:
	SwiftDriver Personal\ Wallpaper\ Engine normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
	Building project Personal Wallpaper Engine with scheme Personal Wallpaper Engine and configuration Debug
(2 failures)
