#!/usr/bin/env python3

import re
from pathlib import Path

def add_framework_dependencies():
    """Add missing framework dependencies to the Xcode project"""

    project_path = Path("/Users/callummatthews1/Horizon/Horizon.xcodeproj/project.pbxproj")

    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the Horizon target's Frameworks build phase
    frameworks_pattern = r'(1D1A9BBB2E761986002B8F85 /\* Frameworks \*/ = \{[\s\S]*?files = \()(\s*\);[\s\S]*?\};)'

    # Framework files to add (these are standard iOS frameworks)
    framework_files = [
        '				1D60000F22D4FAF6008BF43F /* UIKit.framework in Frameworks */,',
        '				1D60001022D4FAF6008BF43F /* Foundation.framework in Frameworks */,',
        '				1D60001122D4FAF6008BF43F /* SwiftUI.framework in Frameworks */,',
        '				1D60001222D4FAF6008BF43F /* Combine.framework in Frameworks */,',
        '				1D60001322D4FAF6008BF43F /* CoreData.framework in Frameworks */,',
    ]

    # Package product dependencies to add
    package_products = [
        '				1D60001422D4FAF6008BF43F /* ATProtoKit in Frameworks */,',
        '				1D60001522D4FAF6008BF43F /* KeychainSwift in Frameworks */,',
        '				1D60001622D4FAF6008BF43F /* AppRouter in Frameworks */,',
        '				1D60001722D4FAF6008BF43F /* Nuke in Frameworks */,',
        '				1D60001822D4FAF6008BF43F /* NukeUI in Frameworks */,',
        '				1D60001922D4FAF6008BF43F /* ViewInspector in Frameworks */,',
        '				1D60001A22D4FAF6008BF43F /* AcknowList in Frameworks */,',
    ]

    def replace_frameworks(match):
        prefix = match.group(1)
        suffix = match.group(2)

        # Add framework files
        framework_section = '\n'.join(framework_files)

        # Add package products
        package_section = '\n'.join(package_products)

        return f"{prefix}{framework_section}\n{package_section}{suffix}"

    # Replace the empty frameworks section
    new_content = re.sub(frameworks_pattern, replace_frameworks, content)

    # Add the framework references to the project if they don't exist
    if '1D60000F22D4FAF6008BF43F' not in new_content:
        # Add PBXBuildFile section entries
        pbxbuildfile_pattern = r'(/\* Begin PBXBuildFile section \*/\n)'

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
        new_content = re.sub(pbxbuildfile_pattern, f'\\1{buildfile_entries}', new_content)

    # Write the updated content
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print("Added framework dependencies to project file")

if __name__ == "__main__":
    add_framework_dependencies()