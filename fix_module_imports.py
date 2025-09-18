#!/usr/bin/env python3

import os
import re
from pathlib import Path

def fix_module_imports():
    """Remove internal module imports that are no longer needed"""
    horizon_dir = Path("/Users/callummatthews1/Horizon/Horizon")

    # Internal modules that need to be removed from imports
    internal_modules = {
        'AuthUI',
        'ChatUI',
        'ComposerUI',
        'DesignSystem',
        'FeedUI',
        'MediaUI',
        'NotificationsUI',
        'PostUI',
        'ProfileUI',
        'SettingsUI',
        'Client',
        'Models',
        'User',
        'Destinations'
    }

    # External modules that should be kept
    external_modules = {
        'SwiftUI',
        'SwiftData',
        'AppRouter',
        'ATProtoKit',
        'KeychainSwift',
        'Nuke',
        'NukeUI',
        'ViewInspector',
        'AcknowList'
    }

    files_processed = 0
    imports_removed = 0

    for swift_file in horizon_dir.rglob("*.swift"):
        if swift_file.is_file():
            files_processed += 1
            with open(swift_file, 'r', encoding='utf-8') as f:
                content = f.read()

            original_content = content

            # Remove import lines for internal modules
            lines = content.split('\n')
            filtered_lines = []

            for line in lines:
                stripped = line.strip()
                # Check if this is an import line for an internal module
                if stripped.startswith('import '):
                    module_name = stripped[7:].strip()  # Remove 'import '

                    # Remove if it's an internal module
                    if module_name in internal_modules:
                        imports_removed += 1
                        continue

                filtered_lines.append(line)

            # Write back if changed
            new_content = '\n'.join(filtered_lines)
            if new_content != original_content:
                with open(swift_file, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed imports in: {swift_file}")

    print(f"\nProcessed {files_processed} Swift files")
    print(f"Removed {imports_removed} internal module imports")
    print("Module import fix complete!")

if __name__ == "__main__":
    fix_module_imports()