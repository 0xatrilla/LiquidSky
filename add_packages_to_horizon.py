#!/usr/bin/env python3

import subprocess
import sys
from pathlib import Path

def add_package_dependencies():
    """Add all required Swift package dependencies to the Horizon project"""

    project_path = "/Users/callummatthews1/Horizon/Horizon.xcodeproj"

    # Define the packages to add
    packages = [
        {
            "url": "https://github.com/MasterJ93/ATProtoKit",
            "version": "from: 0.31.2"
        },
        {
            "url": "https://github.com/evgenyneu/keychain-swift",
            "version": "from: 24.0.0"
        },
        {
            "url": "https://github.com/Dimillian/AppRouter.git",
            "version": "from: 1.0.2"
        },
        {
            "url": "https://github.com/kean/Nuke",
            "version": "from: 12.8.0"
        },
        {
            "url": "https://github.com/nalexn/ViewInspector",
            "version": "from: 0.10.1"
        },
        {
            "url": "https://github.com/vtourraine/AcknowList",
            "version": "from: 3.3.0"
        }
    ]

    print("Adding Swift package dependencies to Horizon project...")

    for package in packages:
        try:
            cmd = [
                "xcodebuild",
                "-project", project_path,
                "-scheme", "Horizon",
                "-add-package",
                package["url"]
            ]

            print(f"Adding {package['url']}...")
            result = subprocess.run(cmd, capture_output=True, text=True)

            if result.returncode == 0:
                print(f"✅ Successfully added {package['url']}")
            else:
                print(f"⚠️  Warning adding {package['url']}: {result.stderr}")

        except Exception as e:
            print(f"❌ Error adding {package['url']}: {e}")

    print("\nPackage dependency addition completed!")
    print("Note: You may need to manually verify packages were added correctly in Xcode.")

if __name__ == "__main__":
    add_package_dependencies()