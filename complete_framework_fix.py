#!/usr/bin/env python3

import re
from pathlib import Path

def complete_framework_fix():
    """Add all missing framework references and build file entries"""

    project_path = Path("/Users/callummatthews1/Horizon/Horizon.xcodeproj/project.pbxproj")

    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # PBXBuildFile entries to add
    buildfile_entries = '''/* UIKit.framework */
		1D60000F22D4FAF6008BF43F /* UIKit.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 1D60000E22D4FAF6008BF43F /* UIKit.framework */; };
/* Foundation.framework */
		1D60001022D4FAF6008BF43F /* Foundation.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 1D60000D22D4FAF6008BF43F /* Foundation.framework */; };
/* SwiftUI.framework */
		1D60001122D4FAF6008BF43F /* SwiftUI.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 1D60000C22D4FAF6008BF43F /* SwiftUI.framework */; };
/* Combine.framework */
		1D60001222D4FAF6008BF43F /* Combine.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 1D60000B22D4FAF6008BF43F /* Combine.framework */; };
/* CoreData.framework */
		1D60001322D4FAF6008BF43F /* CoreData.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 1D60000A22D4FAF6008BF43F /* CoreData.framework */; };
/* ATProtoKit */
		1D60001422D4FAF6008BF43F /* ATProtoKit in Frameworks */ = {isa = PBXBuildFile; productRef = 1D60002022D4FAF6008BF43F /* ATProtoKit */; };
/* KeychainSwift */
		1D60001522D4FAF6008BF43F /* KeychainSwift in Frameworks */ = {isa = PBXBuildFile; productRef = 1D60002122D4FAF6008BF43F /* KeychainSwift */; };
/* AppRouter */
		1D60001622D4FAF6008BF43F /* AppRouter in Frameworks */ = {isa = PBXBuildFile; productRef = 1D60002222D4FAF6008BF43F /* AppRouter */; };
/* Nuke */
		1D60001722D4FAF6008BF43F /* Nuke in Frameworks */ = {isa = PBXBuildFile; productRef = 1D60002322D4FAF6008BF43F /* Nuke */; };
/* NukeUI */
		1D60001822D4FAF6008BF43F /* NukeUI in Frameworks */ = {isa = PBXBuildFile; productRef = 1D60002422D4FAF6008BF43F /* NukeUI */; };
/* ViewInspector */
		1D60001922D4FAF6008BF43F /* ViewInspector in Frameworks */ = {isa = PBXBuildFile; productRef = 1D60002522D4FAF6008BF43F /* ViewInspector */; };
/* AcknowList */
		1D60001A22D4FAF6008BF43F /* AcknowList in Frameworks */ = {isa = PBXBuildFile; productRef = 1D60002622D4FAF6008BF43F /* AcknowList */; };

'''

    # PBXFileReference entries for system frameworks
    fileref_entries = '''/* UIKit.framework */
		1D60000E22D4FAF6008BF43F /* UIKit.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = UIKit.framework; path = Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.6.sdk/System/Library/Frameworks/UIKit.framework; sourceTree = DEVELOPER_DIR; };
/* Foundation.framework */
		1D60000D22D4FAF6008BF43F /* Foundation.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = Foundation.framework; path = Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.6.sdk/System/Library/Frameworks/Foundation.framework; sourceTree = DEVELOPER_DIR; };
/* SwiftUI.framework */
		1D60000C22D4FAF6008BF43F /* SwiftUI.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = SwiftUI.framework; path = Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.6.sdk/System/Library/Frameworks/SwiftUI.framework; sourceTree = DEVELOPER_DIR; };
/* Combine.framework */
		1D60000B22D4FAF6008BF43F /* Combine.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = Combine.framework; path = Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.6.sdk/System/Library/Frameworks/Combine.framework; sourceTree = DEVELOPER_DIR; };
/* CoreData.framework */
		1D60000A22D4FAF6008BF43F /* CoreData.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = CoreData.framework; path = Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS18.6.sdk/System/Library/Frameworks/CoreData.framework; sourceTree = DEVELOPER_DIR; };

'''

    # XCRemoteSwiftPackageReference entries for packages
    package_refs = '''/* ATProtoKit */
		1D60001B22D4FAF6008BF43F /* XCRemoteSwiftPackageReference "ATProtoKit" */ = {isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/MasterJ93/ATProtoKit"; requirement = {kind = upToNextMajorVersion; minimumVersion = "0.31.2";}; };
/* KeychainSwift */
		1D60001C22D4FAF6008BF43F /* XCRemoteSwiftPackageReference "KeychainSwift" */ = {isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/evgenyneu/keychain-swift"; requirement = {kind = upToNextMajorVersion; minimumVersion = "24.0.0";}; };
/* AppRouter */
		1D60001D22D4FAF6008BF43F /* XCRemoteSwiftPackageReference "AppRouter" */ = {isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/Dimillian/AppRouter.git"; requirement = {kind = upToNextMajorVersion; minimumVersion = "1.0.2";}; };
/* Nuke */
		1D60001E22D4FAF6008BF43F /* XCRemoteSwiftPackageReference "Nuke" */ = {isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/kean/Nuke"; requirement = {kind = upToNextMajorVersion; minimumVersion = "12.8.0";}; };
/* NukeUI */
		1D60001F22D4FAF6008BF43F /* XCRemoteSwiftPackageReference "NukeUI" */ = {isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/kean/Nuke"; requirement = {kind = upToNextMajorVersion; minimumVersion = "12.8.0";}; };
/* ViewInspector */
		1D60002022D4FAF6008BF43F /* XCRemoteSwiftPackageReference "ViewInspector" */ = {isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/nalexn/ViewInspector"; requirement = {kind = upToNextMajorVersion; minimumVersion = "0.10.1";}; };
/* AcknowList */
		1D60002122D4FAF6008BF43F /* XCRemoteSwiftPackageReference "AcknowList" */ = {isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/vtourraine/AcknowList"; requirement = {kind = upToNextMajorVersion; minimumVersion = "3.3.0";}; };

'''

    # Product references for packages
    product_refs = '''/* ATProtoKit */
		1D60002222D4FAF6008BF43F /* ATProtoKit */ = {isa = XCRemoteSwiftPackageProduct; productName = ATProtoKit; };
/* KeychainSwift */
		1D60002322D4FAF6008BF43F /* KeychainSwift */ = {isa = XCRemoteSwiftPackageProduct; productName = KeychainSwift; };
/* AppRouter */
		1D60002422D4FAF6008BF43F /* AppRouter */ = {isa = XCRemoteSwiftPackageProduct; productName = AppRouter; };
/* Nuke */
		1D60002522D4FAF6008BF43F /* Nuke */ = {isa = XCRemoteSwiftPackageProduct; productName = Nuke; };
/* NukeUI */
		1D60002622D4FAF6008BF43F /* NukeUI */ = {isa = XCRemoteSwiftPackageProduct; productName = NukeUI; };
/* ViewInspector */
		1D60002722D4FAF6008BF43F /* ViewInspector */ = {isa = XCRemoteSwiftPackageProduct; productName = ViewInspector; };
/* AcknowList */
		1D60002822D4FAF6008BF43F /* AcknowList */ = {isa = XCRemoteSwiftPackageProduct; productName = AcknowList; };

'''

    # Add PBXBuildFile entries if missing
    if "1D60000F22D4FAF6008BF43F" not in content:
        buildfile_pattern = r'(/\* Begin PBXBuildFile section \*/\n)'
        content = re.sub(buildfile_pattern, f'\\1{buildfile_entries}', content)

    # Add PBXFileReference entries if missing
    if "1D60000E22D4FAF6008BF43F /* UIKit.framework */" not in content:
        fileref_pattern = r'(/\* Begin PBXFileReference section \*/\n)'
        content = re.sub(fileref_pattern, f'\\1{fileref_entries}', content)

    # Add package references if missing
    if "XCRemoteSwiftPackageReference" not in content:
        # Find project object and add package references before it
        project_pattern = r'(rootObject = 1D1A9BB62E761986002B8F85 /\* Project object \*/;[\s\S]*?)\}'

        def add_packages(match):
            project_content = match.group(1)
            return f'{project_content}packageReferences = (\n{package_refs});\n\t}}'

        content = re.sub(project_pattern, add_packages, content)

    # Add product references if missing
    if "XCRemoteSwiftPackageProduct" not in content:
        # Find a good place to add product references
        group_pattern = r'(1D1A9BB52E761986002B8F85 = \{[\s\S]*?children = \()(\s*\);)'

        def add_products(match):
            prefix = match.group(1)
            suffix = match.group(2)
            return f'{prefix}1D60002922D4FAF6008BF43F /* Products */,\n{suffix}'

        content = re.sub(group_pattern, add_products, content)

        # Also add the Products group
        if "1D60002922D4FAF6008BF43F /* Products */" not in content:
            products_group = '''/* Products */
		1D60002922D4FAF6008BF43F /* Products */ = {
			isa = PBXGroup;
			children = (
{product_refs}
			);
			name = Products;
			sourceTree = "<group>";
		};
'''
            # Add after the main group
            main_group_pattern = r'(sourceTree = "<group>";\n\t\};\n)'
            content = re.sub(main_group_pattern, f'\\1{products_group}', content)

    # Write the updated content
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("Added complete framework and package dependencies to project")

if __name__ == "__main__":
    complete_framework_fix()