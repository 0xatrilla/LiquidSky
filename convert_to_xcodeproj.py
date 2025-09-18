#!/usr/bin/env python3

import os
import subprocess
import json
from pathlib import Path

def find_swift_files(directory):
    """Find all Swift files in a directory"""
    swift_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.swift'):
                swift_files.append(os.path.join(root, file))
    return swift_files

def generate_uuid():
    """Generate a random UUID for Xcode project"""
    import uuid
    return str(uuid.uuid4()).upper().replace('-', '')

def create_project_structure():
    """Create the complete Xcode project structure"""

    # Base project info
    project_uuid = generate_uuid()
    main_target_uuid = generate_uuid()

    # Find all Swift files
    features_files = find_swift_files('/Users/callummatthews1/LiquidSky/Packages/Features/Sources')
    model_files = find_swift_files('/Users/callummatthews1/LiquidSky/Packages/Model/Sources')
    app_files = find_swift_files('/Users/callummatthews1/LiquidSky/App')

    all_files = app_files + features_files + model_files

    print(f"Found {len(all_files)} Swift files:")
    print(f"  App: {len(app_files)}")
    print(f"  Features: {len(features_files)}")
    print(f"  Model: {len(model_files)}")

    # Create PBXBuildFile section
    build_files = []
    file_refs = []

    for i, file_path in enumerate(all_files):
        file_uuid = generate_uuid()
        build_files.append(f'\t\t{file_uuid} /* {os.path.basename(file_path)} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {os.path.basename(file_path)} */; }};')
        file_refs.append(f'\t\t{file_uuid} /* {os.path.basename(file_path)} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{os.path.basename(file_path)}"; sourceTree = "<group>"; }};')

    # Create group structure
    groups = []

    # Main app group
    app_group_uuid = generate_uuid()
    groups.append(f'\t\t{app_group_uuid} /* LiquidSky */ = {{')
    groups.append(f'\t\t\tisa = PBXGroup;')
    groups.append(f'\t\t\tchildren = (')

    # Add subgroups
    features_group_uuid = generate_uuid()
    model_group_uuid = generate_uuid()
    app_source_group_uuid = generate_uuid()

    groups.append(f'\t\t\t\t{features_group_uuid} /* Features */,')
    groups.append(f'\t\t\t\t{model_group_uuid} /* Model */,')
    groups.append(f'\t\t\t\t{app_source_group_uuid} /* App Source */,')
    groups.append(f'\t\t\t);')
    groups.append(f'\t\t\tpath = LiquidSky;')
    groups.append(f'\t\t\tsourceTree = "<group>";')
    groups.append(f'\t\t}};')

    # Features group
    groups.append(f'\t\t{features_group_uuid} /* Features */ = {{')
    groups.append(f'\t\t\tisa = PBXGroup;')
    groups.append(f'\t\t\tchildren = (')

    # Add feature subgroups
    feature_dirs = ['AuthUI', 'ChatUI', 'ComposerUI', 'DesignSystem', 'FeedUI', 'MediaUI', 'NotificationsUI', 'PostUI', 'ProfileUI', 'SettingsUI']
    for dir_name in feature_dirs:
        dir_uuid = generate_uuid()
        groups.append(f'\t\t\t\t{dir_uuid} /* {dir_name} */,')

    groups.append(f'\t\t\t);')
    groups.append(f'\t\t\tpath = Features;')
    groups.append(f'\t\t\tsourceTree = "<group>";')
    groups.append(f'\t\t}};')

    # Model group
    groups.append(f'\t\t{model_group_uuid} /* Model */ = {{')
    groups.append(f'\t\t\tisa = PBXGroup;')
    groups.append(f'\t\t\tchildren = (')

    # Add model subgroups
    model_dirs = ['Auth', 'Client', 'Destinations', 'Models', 'User']
    for dir_name in model_dirs:
        dir_uuid = generate_uuid()
        groups.append(f'\t\t\t\t{dir_uuid} /* {dir_name} */,')

    groups.append(f'\t\t\t);')
    groups.append(f'\t\t\tpath = Model;')
    groups.append(f'\t\t\tsourceTree = "<group>";')
    groups.append(f'\t\t}};')

    # App source group
    groups.append(f'\t\t{app_source_group_uuid} /* App Source */ = {{')
    groups.append(f'\t\t\tisa = PBXGroup;')
    groups.append(f'\t\t\tchildren = (')

    for file_path in app_files:
        file_uuid = generate_uuid()
        groups.append(f'\t\t\t\t{file_uuid} /* {os.path.basename(file_path)} */,')

    groups.append(f'\t\t\t);')
    groups.append(f'\t\t\tpath = "App Source";')
    groups.append(f'\t\t\tsourceTree = "<group>";')
    groups.append(f'\t\t}};')

    # Create the complete project.pbxproj content
    nl = '\n'
    build_files_str = nl.join(build_files)
    file_refs_str = nl.join(file_refs)
    groups_str = nl.join(groups)
    sources_files_str = nl.join([f'\t\t\t\t{generate_uuid()} /* {os.path.basename(f)} in Sources */,' for f in all_files])

    pbxproj_content = f'''// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{


/* Begin PBXBuildFile section */
{build_files_str}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{file_refs_str}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{generate_uuid()} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{generate_uuid()} = {{
			isa = PBXGroup;
			children = (
				{app_group_uuid} /* LiquidSky */,
				{generate_uuid()} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{generate_uuid()} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{main_target_uuid} /* LiquidSky.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
{groups_str}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{main_target_uuid} /* LiquidSky */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {generate_uuid()} /* Build configuration list for PBXNativeTarget "LiquidSky" */;
			buildPhases = (
				{generate_uuid()} /* Sources */,
				{generate_uuid()} /* Frameworks */,
				{generate_uuid()} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = LiquidSky;
			productName = LiquidSky;
			productReference = {main_target_uuid} /* LiquidSky.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_uuid} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{main_target_uuid} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {generate_uuid()} /* Build configuration list for PBXProject "LiquidSky" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {generate_uuid()};
			productRefGroup = {generate_uuid()} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{main_target_uuid} /* LiquidSky */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{generate_uuid()} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{generate_uuid()} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{sources_files_str}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{generate_uuid()} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.6;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{generate_uuid()} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.6;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{generate_uuid()} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.acxtrilla.LiquidSky;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{generate_uuid()} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.acxtrilla.LiquidSky;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{generate_uuid()} /* Build configuration list for PBXProject "LiquidSky" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{generate_uuid()} /* Debug */,
				{generate_uuid()} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{generate_uuid()} /* Build configuration list for PBXNativeTarget "LiquidSky" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{generate_uuid()} /* Debug */,
				{generate_uuid()} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_uuid} /* Project object */;
}}'''

    return pbxproj_content

if __name__ == "__main__":
    pbxproj_content = create_project_structure()

    with open('/Users/callummatthews1/LiquidSky/Horizon.xcodeproj/project.pbxproj', 'w') as f:
        f.write(pbxproj_content)

    print("Generated project.pbxproj successfully!")

    # Copy source files to project structure
    import shutil

    # Create directory structure
    os.makedirs('/Users/callummatthews1/LiquidSky/LiquidSky/Features', exist_ok=True)
    os.makedirs('/Users/callummatthews1/LiquidSky/LiquidSky/Model', exist_ok=True)

    # Copy Features
    feature_dirs = ['AuthUI', 'ChatUI', 'ComposerUI', 'DesignSystem', 'FeedUI', 'MediaUI', 'NotificationsUI', 'PostUI', 'ProfileUI', 'SettingsUI']
    for dir_name in feature_dirs:
        src_dir = f'/Users/callummatthews1/LiquidSky/Packages/Features/Sources/{dir_name}'
        dst_dir = f'/Users/callummatthews1/LiquidSky/LiquidSky/Features/{dir_name}'
        if os.path.exists(src_dir):
            shutil.copytree(src_dir, dst_dir)

    # Copy Model
    model_dirs = ['Auth', 'Client', 'Destinations', 'Models', 'User']
    for dir_name in model_dirs:
        src_dir = f'/Users/callummatthews1/LiquidSky/Packages/Model/Sources/{dir_name}'
        dst_dir = f'/Users/callummatthews1/LiquidSky/LiquidSky/Model/{dir_name}'
        if os.path.exists(src_dir):
            shutil.copytree(src_dir, dst_dir)

    # Copy App files
    app_files = ['LiquidSkyApp.swift']
    for file_name in app_files:
        src_file = f'/Users/callummatthews1/LiquidSky/App/{file_name}'
        dst_file = f'/Users/callummatthews1/LiquidSky/LiquidSky/{file_name}'
        if os.path.exists(src_file):
            shutil.copy2(src_file, dst_file)

    print("Copied all source files successfully!")