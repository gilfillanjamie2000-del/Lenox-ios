#!/usr/bin/env python3
"""Generate the small dependency-free Xcode project deterministically."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
project = root / 'ios/LENOX.xcodeproj'
project.mkdir(parents=True, exist_ok=True)
ids = {name: f'{i:024X}' for i, name in enumerate(['project','root','sources','products','target','product','sourcephase','frameworkphase','resourcephase','projconfigs','targetconfigs','projdebug','projrelease','targetdebug','targetrelease'], 1)}
files = ['LenoxApp.swift', 'AudioModel.swift', 'MixPolicy.swift']
entries = []
for i, filename in enumerate(files, 100):
    ref, build = f'{i:024X}', f'{i+100:024X}'
    entries += [f'{ref} = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};',
                f'{build} = {{isa = PBXBuildFile; fileRef = {ref}; }};']
refs = ','.join(f'{i:024X}' for i in range(100, 103))
builds = ','.join(f'{i:024X}' for i in range(200, 203))
f = lambda name: ids[name]
entries += [
    f'{f("root")} = {{isa = PBXGroup; children = ({f("sources")},{f("products")}); sourceTree = "<group>"; }};',
    f'{f("sources")} = {{isa = PBXGroup; path = LENOX; children = ({refs}); sourceTree = "<group>"; }};',
    f'{f("products")} = {{isa = PBXGroup; name = Products; children = ({f("product")}); sourceTree = "<group>"; }};',
    f'{f("product")} = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = LENOX.app; sourceTree = BUILT_PRODUCTS_DIR; }};',
    f'{f("sourcephase")} = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({builds}); runOnlyForDeploymentPostprocessing = 0; }};',
    f'{f("frameworkphase")} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};',
    f'{f("resourcephase")} = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};',
    f'{f("target")} = {{isa = PBXNativeTarget; buildConfigurationList = {f("targetconfigs")}; buildPhases = ({f("sourcephase")},{f("frameworkphase")},{f("resourcephase")}); buildRules = (); dependencies = (); name = LENOX; productName = LENOX; productReference = {f("product")}; productType = "com.apple.product-type.application"; }};',
    f'{f("project")} = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; }}; buildConfigurationList = {f("projconfigs")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en,Base); mainGroup = {f("root")}; productRefGroup = {f("products")}; projectDirPath = ""; projectRoot = ""; targets = ({f("target")}); }};',
]
common = 'CLANG_ENABLE_MODULES = YES; IPHONEOS_DEPLOYMENT_TARGET = 16.0; SDKROOT = iphoneos; SWIFT_VERSION = 5.0; ENABLE_USER_SCRIPT_SANDBOXING = YES;'
target = 'CODE_SIGNING_ALLOWED = NO; CODE_SIGNING_REQUIRED = NO; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = LENOX/Info.plist; PRODUCT_BUNDLE_IDENTIFIER = app.lenox.ios.test; PRODUCT_NAME = "$(TARGET_NAME)"; CURRENT_PROJECT_VERSION = 1; MARKETING_VERSION = 0.1.0; TARGETED_DEVICE_FAMILY = "1,2"; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SUPPORTS_MACCATALYST = NO; LENOX_SOURCE_SHA = local-unrecorded;'
for level in ['proj', 'target']:
    for config in ['Debug', 'Release']:
        key = level + config.lower()
        settings = common if level == 'proj' else target
        settings += ' SWIFT_OPTIMIZATION_LEVEL = "-Onone";' if config == 'Debug' else ' SWIFT_OPTIMIZATION_LEVEL = "-O";'
        entries.append(f'{f(key)} = {{isa = XCBuildConfiguration; buildSettings = {{{settings}}}; name = {config}; }};')
    entries.append(f'{f(level+"configs")} = {{isa = XCConfigurationList; buildConfigurations = ({f(level+"debug")},{f(level+"release")}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug; }};')
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n' + '\n'.join(entries) + f'\n}}; rootObject = {f("project")}; }}\n')
schemes = project / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)
ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{f("target")}" BuildableName="LENOX.app" BlueprintName="LENOX" ReferencedContainer="container:LENOX.xcodeproj"/>'
(schemes / 'LENOX.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/>
<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print('Generated ios/LENOX.xcodeproj; no third-party generator required.')
