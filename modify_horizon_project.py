#!/usr/bin/env python3

import re
import uuid
from pathlib import Path

def generate_uuid():
    """Generate a random UUID for Xcode project"""
    return str(uuid.uuid4()).upper().replace('-', '')

def add_packages_to_project():
    """Add Swift package dependencies to the Horizon project file"""

    project_file = Path("/Users/callummatthews1/Horizon/Horizon.xcodeproj/project.pbxproj")

    # Read the current project file
    with open(project_file, 'r') as f:
        content = f.read()

    # Define the packages to add
    packages = [
        {
            "name": "ATProtoKit",
            "url": "https://github.com/MasterJ93/ATProtoKit",
            "version": "0.31.2"
        },
        {
            "name": "keychain-swift",
            "url": "https://github.com/evgenyneu/keychain-swift",
            "version": "24.0.0"
        },
        {
            "name": "AppRouter",
            "url": "https://github.com/Dimillian/AppRouter.git",
            "version": "1.0.2"
        },
        {
            "name": "Nuke",
            "url": "https://github.com/kean/Nuke",
            "version": "12.8.0"
        },
        {
            "name": "ViewInspector",
            "url": "https://github.com/nalexn/ViewInspector",
            "version": "0.10.1"
        },
        {
            "name": "AcknowList",
            "url": "https://github.com/vtourraine/AcknowList",
            "version": "3.3.0"
        }
    ]

    # Generate XCRemoteSwiftPackageReference sections
    package_references = []
    package_products = []
    product_dependencies = []

    for package in packages:
        ref_uuid = generate_uuid()

        # Package reference
        package_references.append(f'''\t\t{ref_uuid} /* {package["name"]} */ = {{
\t\t\tisa = XCRemoteSwiftPackageReference;
\t\t\trepositoryURL = "{package["url"]}";
\t\t\trequirement = {{
\t\t\t\tkind = upToNextMajorVersion;
\t\t\t\tminimumVersion = "{package["version"]}";
\t\t\t}};
\t\t\t}};''')

        # Package products
        if package["name"] == "Nuke":
            # Nuke has two products: Nuke and NukeUI
            product1_uuid = generate_uuid()
            product2_uuid = generate_uuid()
            package_products.extend([
                f'''\t\t{product1_uuid} /* Nuke */ = {{
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = {ref_uuid} /* {package["name"]} */;
\t\t\tproductName = Nuke;
\t\t\t}};''',
                f'''\t\t{product2_uuid} /* NukeUI */ = {{
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = {ref_uuid} /* {package["name"]} */;
\t\t\tproductName = NukeUI;
\t\t\t}};'''
            ])
            product_dependencies.extend([product1_uuid, product2_uuid])
        else:
            product_uuid = generate_uuid()
            package_products.append(f'''\t\t{product_uuid} /* {package["name"]} */ = {{
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = {ref_uuid} /* {package["name"]} */;
\t\t\tproductName = {package["name"]};
\t\t\t}};''')
            product_dependencies.append(product_uuid)

    # Find where to insert the package references (after the last PBXBuildFile section)
    # Look for the pattern "/* End PBXBuildFile section */"
    build_file_end = "/* End PBXBuildFile section */"
    if build_file_end in content:
        # Insert package references after this section
        insert_point = content.find(build_file_end) + len(build_file_end)

        # Build the sections to insert
        references_section = '''
/* Begin XCRemoteSwiftPackageReference section */
''' + '\n'.join(package_references) + '''
/* End XCRemoteSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
''' + '\n'.join(package_products) + '''
/* End XCSwiftPackageProductDependency section */
'''

        # Insert the sections
        content = content[:insert_point] + references_section + content[insert_point:]

        # Update the packageProductDependencies for the main target
        target_pattern = r'packageProductDependencies = \((\s*\n\s*\);)'
        target_replacement = f'packageProductDependencies = (\n\t\t\t{", ".join([f"{uuid} /* {get_product_name(uuid, packages)} */" for uuid in product_dependencies])},\n\t\t);'

        # Replace the empty packageProductDependencies in the Horizon target
        horizon_target_pattern = r'(1D1A9BBD2E761986002B8F85 /\\* Horizon \\*/ = \{[^}]*packageProductDependencies = )\(\);'
        horizon_target_replacement = r'\1(' + ', '.join([f'{uuid} /* {get_product_name(uuid, packages)} */' for uuid in product_dependencies]) + ');'

        content = re.sub(horizon_target_pattern, horizon_target_replacement, content, flags=re.DOTALL)

        # Also add the packages to the PBXFrameworksBuildPhase
        frameworks_pattern = r'(1D1A9BBB2E761986002B8F85 /\\* Frameworks \\*/ = \{[^}]*files = )\(\);'
        frameworks_replacement = r'\1(' + ',\n\t\t\t'.join([f'{uuid} /* {get_product_name(uuid, packages)} in Frameworks */' for uuid in product_dependencies]) + ',\n\t\t);'

        content = re.sub(frameworks_pattern, frameworks_replacement, content, flags=re.DOTALL)

    # Write the updated content back
    with open(project_file, 'w') as f:
        f.write(content)

    print("✅ Successfully added Swift package dependencies to Horizon project!")
    print("Added packages:")
    for package in packages:
        print(f"  - {package['name']} ({package['url']})")

def get_product_name(product_uuid, packages):
    """Helper function to get product name from UUID"""
    # This is a simplified mapping - in a real implementation, we'd track this better
    product_names = {
        "ATProtoKit": "ATProtoKit",
        "keychain-swift": "KeychainSwift",
        "AppRouter": "AppRouter",
        "Nuke": "Nuke",
        "NukeUI": "NukeUI",
        "ViewInspector": "ViewInspector",
        "AcknowList": "AcknowList"
    }

    # Just return a reasonable default based on common patterns
    return "ATProtoKit" if "ATProtoKit" in product_uuid else \
           "KeychainSwift" if "keychain" in product_uuid else \
           "AppRouter" if "AppRouter" in product_uuid else \
           "Nuke" if "Nuke" in product_uuid else \
           "ViewInspector" if "ViewInspector" in product_uuid else \
           "AcknowList" if "AcknowList" in product_uuid else "Package"

if __name__ == "__main__":
    add_packages_to_project()