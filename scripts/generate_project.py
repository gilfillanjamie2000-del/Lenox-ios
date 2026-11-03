#!/usr/bin/env python3
"""Generate the small dependency-free Xcode project deterministically."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
project = root / 'ios/LENOX.xcodeproj'
project.mkdir(parents=True, exist_ok=True)
ids = {name: f'{i:024X}' for i, name in enumerate(['project','root','sources','products','target','product','sourcephase','frameworkphase','resourcephase','projconfigs','targetconfigs','projdebug','projrelease','targetdebug','targetrelease'], 1)}
files = ['LenoxApp.swift', 'AudioModel.swift', 'MixPolicy.swift', 'PlaylistStore.swift', 'PlaylistViews.swift', 'PerformancePolicy.swift', 'MixerScreen.swift', 'LaunchExperience.swift', 'AudioDocumentPicker.swift']
entries = []
for i, filename in enumerate(files, 100):
    ref, build = f'{i:024X}', f'{i+100:024X}'
    entries += [f'{ref} = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};',
                f'{build} = {{isa = PBXBuildFile; fileRef = {ref}; }};']
entries += [
    '0000000000000000000001F4 = {isa = PBXFileReference; lastKnownFileType = folder; path = ApprovedAssets; sourceTree = "<group>"; };',
    '0000000000000000000001F5 = {isa = PBXBuildFile; fileRef = 0000000000000000000001F4; };',
]
refs = ','.join(f'{i:024X}' for i in range(100, 100 + len(files)))
builds = ','.join(f'{i:024X}' for i in range(200, 200 + len(files)))
f = lambda name: ids[name]
entries += [
    f'{f("root")} = {{isa = PBXGroup; children = ({f("sources")},{f("products")},000000000000000000000262); sourceTree = "<group>"; }};',
    f'{f("sources")} = {{isa = PBXGroup; path = LENOX; children = ({refs},0000000000000000000001F4); sourceTree = "<group>"; }};',
    f'{f("products")} = {{isa = PBXGroup; name = Products; children = ({f("product")},000000000000000000000259); sourceTree = "<group>"; }};',
    f'{f("product")} = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = LENOX.app; sourceTree = BUILT_PRODUCTS_DIR; }};',
    f'{f("sourcephase")} = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({builds}); runOnlyForDeploymentPostprocessing = 0; }};',
    f'{f("frameworkphase")} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};',
    f'{f("resourcephase")} = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (0000000000000000000001F5); runOnlyForDeploymentPostprocessing = 0; }};',
    f'{f("target")} = {{isa = PBXNativeTarget; buildConfigurationList = {f("targetconfigs")}; buildPhases = ({f("sourcephase")},{f("frameworkphase")},{f("resourcephase")}); buildRules = (); dependencies = (); name = LENOX; productName = LENOX; productReference = {f("product")}; productType = "com.apple.product-type.application"; }};',
    f'{f("project")} = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; }}; buildConfigurationList = {f("projconfigs")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en,Base); mainGroup = {f("root")}; productRefGroup = {f("products")}; projectDirPath = ""; projectRoot = ""; targets = ({f("target")},000000000000000000000258); }};',
]
common = 'CLANG_ENABLE_MODULES = YES; IPHONEOS_DEPLOYMENT_TARGET = 16.0; SDKROOT = iphoneos; SWIFT_VERSION = 5.0; ENABLE_USER_SCRIPT_SANDBOXING = YES;'
target = 'CODE_SIGNING_ALLOWED = NO; CODE_SIGNING_REQUIRED = NO; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = LENOX/Info.plist; PRODUCT_BUNDLE_IDENTIFIER = app.lenox.ios.test; PRODUCT_NAME = "$(TARGET_NAME)"; CURRENT_PROJECT_VERSION = 2; MARKETING_VERSION = 0.1.1; TARGETED_DEVICE_FAMILY = "1,2"; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SUPPORTS_MACCATALYST = NO; LENOX_SOURCE_SHA = local-unrecorded;'
for level in ['proj', 'target']:
    for config in ['Debug', 'Release']:
        key = level + config.lower()
        settings = common if level == 'proj' else target
        settings += ' SWIFT_OPTIMIZATION_LEVEL = "-Onone";' if config == 'Debug' else ' SWIFT_OPTIMIZATION_LEVEL = "-O";'
        entries.append(f'{f(key)} = {{isa = XCBuildConfiguration; buildSettings = {{{settings}}}; name = {config}; }};')
    entries.append(f'{f(level+"configs")} = {{isa = XCConfigurationList; buildConfigurations = ({f(level+"debug")},{f(level+"release")}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug; }};')

# Native UI regression target; fixture-only launch arguments are Simulator guarded.
entries += [
    '000000000000000000000262 = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ../Tests/UI/StudioUITests.swift; sourceTree = SOURCE_ROOT; };',
    '00000000000000000000025B = {isa = PBXBuildFile; fileRef = 000000000000000000000262; };',
    '000000000000000000000259 = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = LENOXUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };',
    '00000000000000000000025C = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (00000000000000000000025B); runOnlyForDeploymentPostprocessing = 0; };',
    '00000000000000000000025D = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };',
    '00000000000000000000025E = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };',
    f'000000000000000000000263 = {{isa = PBXContainerItemProxy; containerPortal = {f("project")}; proxyType = 1; remoteGlobalIDString = {f("target")}; remoteInfo = LENOX; }};',
    f'000000000000000000000264 = {{isa = PBXTargetDependency; target = {f("target")}; targetProxy = 000000000000000000000263; }};',
    '000000000000000000000258 = {isa = PBXNativeTarget; buildConfigurationList = 00000000000000000000025F; buildPhases = (00000000000000000000025C,00000000000000000000025D,00000000000000000000025E); buildRules = (); dependencies = (000000000000000000000264); name = LENOXUITests; productName = LENOXUITests; productReference = 000000000000000000000259; productType = "com.apple.product-type.bundle.ui-testing"; };',
    '00000000000000000000025F = {isa = XCConfigurationList; buildConfigurations = (000000000000000000000260,000000000000000000000261); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug; };',
]
for config, config_id in [('Debug', '260'), ('Release', '261')]:
    settings = common + ' CODE_SIGNING_ALLOWED = NO; CODE_SIGNING_REQUIRED = NO; GENERATE_INFOPLIST_FILE = YES; PRODUCT_BUNDLE_IDENTIFIER = app.lenox.ios.test.uitests; PRODUCT_NAME = "$(TARGET_NAME)"; TARGETED_DEVICE_FAMILY = "1,2"; TEST_TARGET_NAME = LENOX; SWIFT_OPTIMIZATION_LEVEL = "-Onone";'
    entries.append(f'000000000000000000000{config_id} = {{isa = XCBuildConfiguration; buildSettings = {{{settings}}}; name = {config}; }};')

(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n' + '\n'.join(entries) + f'\n}}; rootObject = {f("project")}; }}\n')
schemes = project / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)
ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{f("target")}" BuildableName="LENOX.app" BlueprintName="LENOX" ReferencedContainer="container:LENOX.xcodeproj"/>'
test_ref = '<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="000000000000000000000258" BuildableName="LENOXUITests.xctest" BlueprintName="LENOXUITests" ReferencedContainer="container:LENOX.xcodeproj"/>'
(schemes / 'LENOX.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test_ref}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/>
<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print('Generated ios/LENOX.xcodeproj; no third-party generator required.')
