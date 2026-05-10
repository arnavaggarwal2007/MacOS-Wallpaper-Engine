Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild clean build -project "Personal Wallpaper Engine.xcodeproj" -scheme "Personal Wallpaper Engine"

2026-05-06 22:25:34.396 xcodebuild[86955:679496] [MT] IDERunDestination: Supported platforms for the buildables in the current scheme is empty.
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

Build description signature: 079d084cba214e225632e6b051611ae5
Build description path: /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/XCBuildData/079d084cba214e225632e6b051611ae5.xcbuilddata
ClangStatCache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk /Users/arnev/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -o /Users/arnev/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache

CreateBuildDirectory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products

CreateBuildDirectory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex

CreateBuildDirectory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules

CreateBuildDirectory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/ExplicitPrecompiledModules
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/ExplicitPrecompiledModules

CreateBuildDirectory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/EagerLinkingTBDs/Debug
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/EagerLinkingTBDs/Debug

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine-fa84f85574cad5040bb4c3dd096b0aa8-VFS/all-product-headers.yaml
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine-fa84f85574cad5040bb4c3dd096b0aa8-VFS/all-product-headers.yaml

CreateBuildDirectory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.xcodeproj
    builtin-create-build-directory /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.hmap

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyStaticMetadataFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyMetadataFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.DependencyMetadataFileList

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-non-framework-target-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-non-framework-target-headers.hmap

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibPath-normal-arm64.txt (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibPath-normal-arm64.txt

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibInstallName-normal-arm64.txt (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-DebugDylibInstallName-normal-arm64.txt

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftConstValuesFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftFileList

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.LinkFileList (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.LinkFileList

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine-OutputFileMap.json (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine-OutputFileMap.json

WriteAuxiliaryFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/Entitlements.plist (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    write-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/Entitlements.plist

MkDir /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources

MkDir /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS

MkDir /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents

MkDir /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app

ProcessProductPackaging /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.entitlements /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    
    Entitlements:
    
    {
    "com.apple.security.app-sandbox" = 1;
    "com.apple.security.files.bookmarks.app-scope" = 1;
    "com.apple.security.files.user-selected.read-only" = 1;
    "com.apple.security.get-task-allow" = 1;
}
    
    builtin-productPackagingUtility /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine.entitlements -entitlements -format xml -o /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent

ProcessProductPackagingDER /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent.der (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /usr/bin/derq query -f xml -i /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent -o /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine.app.xcent.der --raw

GenerateAssetSymbols /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /Applications/Xcode.app/Contents/Developer/usr/bin/actool /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets --compile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources --output-format human-readable-text --notices --warnings --export-dependency-info /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies --output-partial-info-plist /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist --app-icon AppIcon --accent-color AccentColor --enable-on-demand-resources NO --development-region en --target-device mac --minimum-deployment-target 26.2 --platform macosx --bundle-identifier Personal.Personal-Wallpaper-Engine --generate-swift-asset-symbols /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols.swift --generate-objc-asset-symbols /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols.h --generate-asset-symbol-index /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols-Index.plist
/* com.apple.actool.compilation-results */
/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/DerivedSources/GeneratedAssetSymbols-Index.plist
/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/DerivedSources/GeneratedAssetSymbols.h
/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/DerivedSources/GeneratedAssetSymbols.swift


Ld /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS/__preview.dylib normal (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-macos26.2 -dynamiclib -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -O0 -L/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug -F/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug -install_name @rpath/Personal\ Wallpaper\ Engine.debug.dylib -rdynamic -Xlinker -no_deduplicate -Xlinker -dependency_info -Xlinker /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_dependency_info.dat -Xlinker -no_adhoc_codesign -o /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/MacOS/__preview.dylib

MkDir /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned

CpResource /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources/Feature-Contract-Phase-6A.md /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Features/Feature-Contract-Phase-6A.md (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Features/Feature-Contract-Phase-6A.md /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources

MkDir /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/unthinned (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /bin/mkdir -p /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/unthinned

CompileAssetCatalogVariant thinned /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    /Applications/Xcode.app/Contents/Developer/usr/bin/actool /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets --compile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned --output-format human-readable-text --notices --warnings --export-dependency-info /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies_thinned --output-partial-info-plist /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist_thinned --app-icon AppIcon --accent-color AccentColor --enable-on-demand-resources NO --development-region en --target-device mac --minimum-deployment-target 26.2 --platform macosx
/* com.apple.actool.compilation-results */
/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal Wallpaper Engine.build/Debug/Personal Wallpaper Engine.build/assetcatalog_generated_info.plist_thinned


SwiftDriver Personal\ Wallpaper\ Engine normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name Personal_Wallpaper_Engine -Onone -enforce-exclusivity\=checked @/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftFileList -DDEBUG -default-isolation\=MainActor -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -target arm64-apple-macos26.2 -g -module-cache-path /Users/arnev/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -index-store-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug -F /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug -emit-localized-strings -emit-localized-strings-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64 -c -j12 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/arnev/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache -output-file-map /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/arnev/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -sdk-module-cache-path /Users/arnev/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/arnev/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json -Xcc -iquote -Xcc /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap -Xcc -iquote -Xcc /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/include -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources-normal/arm64 -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/arm64 -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine-Swift.h -working-directory /Users/arnev/Desktop/Personal\ Wallpaper\ Engine -experimental-emit-module-separately -disable-cmo

LinkAssetCatalog /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Assets.xcassets (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-linkAssetCatalog --thinned /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/thinned --thinned-dependencies /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies_thinned --thinned-info-plist-content /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist_thinned --unthinned /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_output/unthinned --unthinned-dependencies /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_dependencies_unthinned --unthinned-info-plist-content /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist_unthinned --output /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Resources --plist-output /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist

ProcessInfoPlistFile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Info.plist /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-infoPlistUtility /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/empty-Personal\ Wallpaper\ Engine.plist -producttype com.apple.product-type.application -genpkginfo /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/PkgInfo -expandbuildsettings -platform macosx -additionalcontentfile /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/assetcatalog_generated_info.plist -o /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal\ Wallpaper\ Engine.app/Contents/Info.plist

SwiftCompile normal arm64 Compiling\ DisplayController.swift,\ Errors.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/DisplayController.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Errors.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/DisplayController.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Errors.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftCompile normal arm64 Compiling\ AppViewModel.swift,\ ContentView.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/AppViewModel.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/ContentView.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/AppViewModel.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/AppViewModel.swift:270:9: warning: result of call to 'beginAccessingSelectedVideoURL' is unused
        beginAccessingSelectedVideoURL(url)
        ^                             ~~~~~
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/AppViewModel.swift:579:26: warning: no calls to throwing functions occur within 'try' expression
        let collection = try? await loadSelectedCollection()
                         ^
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/AppViewModel.swift:606:44: error: instance member 'displayControllers' cannot be used on type 'WallpaperManager'; did you mean to use a value of this type instead?
            for (displayID, controller) in WallpaperManager.displayControllers {
                                           ^~~~~~~~~~~~~~~~
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/AppViewModel.swift:608:48: warning: result of call to 'setWallpaper(url:)' is unused
                    try await wallpaperManager.setWallpaper(url: URL(string: firstSource.url)!)
                                               ^           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/AppViewModel.swift:617:34: error: instance member 'displayControllers' cannot be used on type 'WallpaperManager'; did you mean to use a value of this type instead?
            guard displayIndex < WallpaperManager.displayControllers.count else { break }
                                 ^~~~~~~~~~~~~~~~
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/AppViewModel.swift:621:40: warning: result of call to 'setWallpaper(url:)' is unused
                await wallpaperManager.setWallpaper(url: url)
                                       ^           ~~~~~~~~~~
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/AppViewModel.swift:641:44: warning: result of call to 'setPerDisplayWallpaper(displayID:url:rendererMode:scalingMode:)' is unused
                    await wallpaperManager.setPerDisplayWallpaper(
                                           ^                     ~
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/AppViewModel.swift:650:58: error: no exact matches in call to initializer 
                let displayInfo = source.displayLabel ?? String(source.displayIDFallback) ?? "?"
                                                         ^
Swift.String.init:2:19: note: found candidate with type 'Int?'
@inlinable public init<T>(_ value: T) where T : LosslessStringConvertible}
                  ^
Swift.String.init:2:8: note: found candidate with type 'Int?'
public init<T>(_ value: T, radix: Int = 10, uppercase: Bool = false) where T : BinaryInteger}
       ^
Swift.String.init:2:8: note: incorrect labels for candidate (have: '(_:)', expected: '(describing:)')
public init<Subject>(describing instance: Subject)}
       ^
Swift.String.init:2:8: note: incorrect labels for candidate (have: '(_:)', expected: '(reflecting:)')
public init<Subject>(reflecting subject: Subject)}
       ^
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/AppViewModel.swift:667:29: error: instance member 'displayControllers' cannot be used on type 'WallpaperManager'; did you mean to use a value of this type instead?
           let controller = WallpaperManager.displayControllers.values.first(where: { $0.displayID == displayIDFallback }) {
                            ^~~~~~~~~~~~~~~~
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/AppViewModel.swift:673:31: error: instance member 'displayControllers' cannot be used on type 'WallpaperManager'; did you mean to use a value of this type instead?
            for controller in WallpaperManager.displayControllers.values {
                              ^~~~~~~~~~~~~~~~

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/ContentView.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/ContentView.swift:510:51: warning: 'icon(forFileType:)' was deprecated in macOS 12.0: Use -[NSWorkspace iconForContentType:] instead.
        return fallbackIsWeb ? NSWorkspace.shared.icon(forFileType: "webloc") : NSWorkspace.shared.icon(forFileType: "public.movie")
                                                  ^
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/ContentView.swift:510:100: warning: 'icon(forFileType:)' was deprecated in macOS 12.0: Use -[NSWorkspace iconForContentType:] instead.
        return fallbackIsWeb ? NSWorkspace.shared.icon(forFileType: "webloc") : NSWorkspace.shared.icon(forFileType: "public.movie")
                                                                                                   ^
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/ContentView.swift:525:41: warning: 'copyCGImage(at:actualTime:)' was deprecated in macOS 15.0: Use generateCGImageAsynchronouslyForTime:completionHandler: instead
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
                                        ^

Failed frontend command:
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-frontend -frontend -c -primary-file /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/AppViewModel.swift -primary-file /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/ContentView.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/DisplayController.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Errors.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/LoginItemManager.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/MenuBarController.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Personal_Wallpaper_EngineApp.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Renderer.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/SettingsStore.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/VideoRenderer.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/WallpaperCollection.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/WallpaperManager.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/WebRenderer.swift /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols.swift -emit-dependencies-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/AppViewModel.d -emit-const-values-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/AppViewModel.swiftconstvalues -emit-reference-dependencies-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/AppViewModel.swiftdeps -serialize-diagnostics-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/AppViewModel.dia -emit-dependencies-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/ContentView.d -emit-const-values-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/ContentView.swiftconstvalues -emit-reference-dependencies-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/ContentView.swiftdeps -serialize-diagnostics-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/ContentView.dia -emit-localized-strings -emit-localized-strings-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64 -target arm64-apple-macos26.2 -module-can-import-version AppKit 2685.30.107 2685.30.107 -module-can-import-version DeveloperToolsSupport 23.0.4 23.0.4 -module-can-import-version SwiftUI 7.2.5.1 7.2.5 -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins/libFoundationMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/bin/swift-plugin-server\#FoundationMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins/libObservationMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/bin/swift-plugin-server\#ObservationMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins/libPreviewsMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/bin/swift-plugin-server\#PreviewsMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins/libSwiftMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/bin/swift-plugin-server\#SwiftMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins/libSwiftUIMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/bin/swift-plugin-server\#SwiftUIMacros -disable-implicit-swift-modules -Xcc -fno-implicit-modules -Xcc -fno-implicit-module-maps -explicit-swift-module-map-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine-dependencies-1.json -Xllvm -aarch64-use-tbi -enable-objc-interop -stack-check -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -I /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug -F /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug -no-color-diagnostics -Xcc -fno-color-diagnostics -enable-testing -g -debug-info-format\=dwarf -dwarf-version\=5 -module-cache-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -swift-version 5 -enforce-exclusivity\=checked -Onone -D DEBUG -serialize-debugging-options -const-gather-protocols-file /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -enable-bare-slash-regex -default-isolation\=MainActor -empty-abi-descriptor -validate-clang-modules-once -clang-build-session-file /Users/arnev/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -working-directory -Xcc /Users/arnev/Desktop/Personal\ Wallpaper\ Engine -enable-anonymous-context-mangled-names -file-compilation-dir /Users/arnev/Desktop/Personal\ Wallpaper\ Engine -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -Xcc -ivfsstatcache -Xcc /Users/arnev/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/swift-overrides.hmap -Xcc -iquote -Xcc /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap -Xcc -iquote -Xcc /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/include -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources-normal/arm64 -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/arm64 -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources -Xcc -DDEBUG\=1 -no-auto-bridging-header-chaining -module-name Personal_Wallpaper_Engine -frontend-parseable-output -disable-clang-spi -target-sdk-version 26.2 -target-sdk-name macosx26.2 -clang-target arm64-apple-macos26.2 -in-process-plugin-server-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/libSwiftInProcPluginServer.dylib -o /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/AppViewModel.o -o /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/ContentView.o -index-unit-output-path /Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/AppViewModel.o -index-unit-output-path /Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/ContentView.o -index-store-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Index.noindex/DataStore -index-system-modules
SwiftCompile normal arm64 Compiling\ MenuBarController.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/MenuBarController.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/MenuBarController.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/MenuBarController.swift:18:19: warning: value 'button' was defined but never used; consider replacing with boolean test
        guard let button = statusItem?.button else {
              ~~~~^~~~~~~~~
              (                              ) != nil

SwiftEmitModule normal arm64 Emitting\ module\ for\ Personal_Wallpaper_Engine (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

EmitSwiftModule normal arm64 (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftCompile normal arm64 Compiling\ VideoRenderer.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/VideoRenderer.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/VideoRenderer.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftCompile normal arm64 Compiling\ Renderer.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Renderer.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Renderer.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftCompile normal arm64 Compiling\ WebRenderer.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/WebRenderer.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/WebRenderer.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/WebRenderer.swift:23:17: warning: variable 'pagePrefs' was never mutated; consider changing to 'let' constant
            var pagePrefs = WKWebpagePreferences()
            ~~~ ^
            let
/Users/arnev/Desktop/Personal Wallpaper Engine/Personal Wallpaper Engine/WebRenderer.swift:99:25: warning: result of call to 'run(resultType:body:)' is unused
        await MainActor.run {
                        ^   ~

SwiftCompile normal arm64 Compiling\ LoginItemManager.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/LoginItemManager.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/LoginItemManager.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftCompile normal arm64 Compiling\ WallpaperManager.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/WallpaperManager.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/WallpaperManager.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftCompile normal arm64 Compiling\ GeneratedAssetSymbols.swift /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/GeneratedAssetSymbols.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftCompile normal arm64 Compiling\ WallpaperCollection.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/WallpaperCollection.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/WallpaperCollection.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftCompile normal arm64 Compiling\ Personal_Wallpaper_EngineApp.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Personal_Wallpaper_EngineApp.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/Personal_Wallpaper_EngineApp.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftCompile normal arm64 Compiling\ SettingsStore.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/SettingsStore.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/SettingsStore.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    

SwiftDriverJobDiscovery normal arm64 Compiling Renderer.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriverJobDiscovery normal arm64 Compiling Personal_Wallpaper_EngineApp.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriverJobDiscovery normal arm64 Compiling GeneratedAssetSymbols.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriverJobDiscovery normal arm64 Compiling LoginItemManager.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriverJobDiscovery normal arm64 Compiling WallpaperCollection.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriverJobDiscovery normal arm64 Compiling MenuBarController.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriverJobDiscovery normal arm64 Emitting module for Personal_Wallpaper_Engine (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriver\ Compilation\ Requirements Personal\ Wallpaper\ Engine normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name Personal_Wallpaper_Engine -Onone -enforce-exclusivity\=checked @/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine.SwiftFileList -DDEBUG -default-isolation\=MainActor -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk -target arm64-apple-macos26.2 -g -module-cache-path /Users/arnev/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -index-store-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug -F /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug -emit-localized-strings -emit-localized-strings-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64 -c -j12 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/arnev/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.2-25C58-00fa09913b459cbbc988d1f6730289ae.sdkstatcache -output-file-map /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/arnev/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -sdk-module-cache-path /Users/arnev/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/arnev/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal\ Wallpaper\ Engine_const_extract_protocols.json -Xcc -iquote -Xcc /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-generated-files.hmap -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-own-target-headers.hmap -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-all-target-headers.hmap -Xcc -iquote -Xcc /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Personal\ Wallpaper\ Engine-project-headers.hmap -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/include -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources-normal/arm64 -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/arm64 -Xcc -I/Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine-Swift.h -working-directory /Users/arnev/Desktop/Personal\ Wallpaper\ Engine -experimental-emit-module-separately -disable-cmo

SwiftMergeGeneratedHeaders /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/Personal_Wallpaper_Engine-Swift.h /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine-Swift.h (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-swiftHeaderTool -arch arm64 /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine-Swift.h -o /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/DerivedSources/Personal_Wallpaper_Engine-Swift.h

Copy /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal_Wallpaper_Engine.swiftmodule/arm64-apple-macos.swiftdoc /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.swiftdoc (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.swiftdoc /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal_Wallpaper_Engine.swiftmodule/arm64-apple-macos.swiftdoc

Copy /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal_Wallpaper_Engine.swiftmodule/arm64-apple-macos.abi.json /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.abi.json (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.abi.json /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal_Wallpaper_Engine.swiftmodule/arm64-apple-macos.abi.json

Copy /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal_Wallpaper_Engine.swiftmodule/Project/arm64-apple-macos.swiftsourceinfo /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.swiftsourceinfo (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.swiftsourceinfo /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal_Wallpaper_Engine.swiftmodule/Project/arm64-apple-macos.swiftsourceinfo

Copy /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal_Wallpaper_Engine.swiftmodule/arm64-apple-macos.swiftmodule /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.swiftmodule (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
    cd /Users/arnev/Desktop/Personal\ Wallpaper\ Engine
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Intermediates.noindex/Personal\ Wallpaper\ Engine.build/Debug/Personal\ Wallpaper\ Engine.build/Objects-normal/arm64/Personal_Wallpaper_Engine.swiftmodule /Users/arnev/Library/Developer/Xcode/DerivedData/Personal_Wallpaper_Engine-gzbxdezevvxnvqejfhihxkiwuxdb/Build/Products/Debug/Personal_Wallpaper_Engine.swiftmodule/arm64-apple-macos.swiftmodule

SwiftDriverJobDiscovery normal arm64 Compiling WebRenderer.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriverJobDiscovery normal arm64 Compiling SettingsStore.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriverJobDiscovery normal arm64 Compiling VideoRenderer.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriverJobDiscovery normal arm64 Compiling WallpaperManager.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

SwiftDriverJobDiscovery normal arm64 Compiling DisplayController.swift, Errors.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')

** BUILD FAILED **


The following build commands failed:
	SwiftCompile normal arm64 /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/AppViewModel.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
	SwiftCompile normal arm64 Compiling\ AppViewModel.swift,\ ContentView.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/AppViewModel.swift /Users/arnev/Desktop/Personal\ Wallpaper\ Engine/Personal\ Wallpaper\ Engine/ContentView.swift (in target 'Personal Wallpaper Engine' from project 'Personal Wallpaper Engine')
	Building project Personal Wallpaper Engine with scheme Personal Wallpaper Engine
(3 failures)