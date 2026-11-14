# Portability and graphics expansion

This document records the implementation boundary for the next Lemon development
milestone. A platform is not considered supported merely because its target name
is accepted by the command-line tool: it needs a native host, renderer, input and
lifecycle integration, build packaging, and a CI/device validation path.

## Existing baseline

- Windows: Win32 + Direct2D/DirectWrite renderer and native desktop services.
- Android: Java Activity host, OpenGL ES 2.0 shape renderer, touch and MediaPlayer.
- The current desktop Renderer is coupled to the Windows NativePlace bridge.
- The current Android renderer is a separate GraphicsContext implementation;
  it does not yet implement the full Sprite/Texture/Text API.
- Sparrow XML metadata, frame timing, Sprite animation selection, and Windows
  Direct2D source-rectangle drawing are present on the development branch.
  Android atlas rendering and the other platform backends are not implemented.

## Target architecture

Keep the public Haxe API platform-neutral and select a backend at compile time.
Native implementation files should live under `src/lemon/platform/<platform>`.
Avoid leaking Win32, UIKit, Cocoa, X11/Wayland, Vulkan, or JNI types into shared
Haxe packages.

| Target | Host and packaging | Renderer direction |
| --- | --- | --- |
| Windows | Win32; hxcpp; MSVC or MinGW | Direct2D baseline; Vulkan optional |
| Android | Gradle + hxjava host; arm64-v8a and x86_64 | OpenGL ES 2 baseline; Vulkan capability path |
| iOS | UIKit + Xcode project, signing and archive | Metal baseline; Vulkan only through a portability layer |
| macOS | Cocoa + Xcode or CMake; x64 and arm64 | Metal baseline; Vulkan optional through MoltenVK |
| Linux | X11/Wayland host; CMake and native packages | Vulkan with OpenGL fallback |

Vulkan is not a universal replacement for platform APIs. iOS does not expose
native Vulkan; a Vulkan renderer there requires a translation layer such as
MoltenVK and must be validated against Apple's graphics and App Store rules.
Metal should remain the native Apple rendering path. Linux should not assume
that X11 is installed: the host layer should isolate window-system integration
so Wayland and X11 can be selected independently.

## Module and binary artifact model

Lemon separates the framework runtime from the application/game module:

- The Lemon framework library is distributed as `.ndll` or `.dll`.
- An application or game module may be emitted as `.ndll`, `.hdll`, or
  `.dll`, selected by the target and requested module kind.
- `.ndll` is the native dynamic-module form. It contains native machine code
  and exports the versioned Lemon module entry points.
- `.dll` is the Windows PE native-library form and remains a supported
  compatibility output. It is not a portable executable format on its own.
- `.hdll` is reserved for a Haxe module form. It must carry a declared Haxe
  runtime/ABI version and must be loaded by a compatible Lemon/Haxe runtime;
  it must not be treated as a native DLL by the operating-system loader.

The extension is a logical artifact contract, not permission to ignore the
operating system's binary format. The build manifest must record target OS,
CPU architecture, binary format, ABI version, module kind, and dependencies.
A native module must match the host process architecture and ABI.

On Windows, native `.ndll` and `.dll` modules use PE/COFF and the Windows
loader. On Linux they use ELF and `dlopen`; on macOS they use Mach-O and
`dlopen`. The build may retain the requested logical extension, but the
payload must be the correct platform binary. Apple platforms require additional
care: macOS can load signed Mach-O dynamic libraries, while iOS generally
requires code to be included in the signed app bundle and obeys Apple's
dynamic-code and signing restrictions. iOS must not promise arbitrary runtime
loading of downloaded native modules.

The public module ABI should be C-compatible, versioned, and independent of
C++ name mangling. Each native module should expose a single stable descriptor
or entry point that reports its ABI version and required Lemon runtime version.
The loader must reject incompatible architecture, ABI, or runtime versions
before invoking module code. No C++ standard-library objects may cross the
module boundary. Resource ownership and shutdown must be explicit.

The exact export names, descriptor layout, `.hdll` bytecode/container format,
and loader implementation are a follow-up implementation task. The extensions
are specified here; the runtime does not yet load these module types.

## Compiler and project generation

The C++ CLI should become a thin, deterministic project orchestrator:

1. Parse a target into platform, architecture, configuration, renderer, and
   output module kind.
2. Validate required SDKs and toolchains before starting a build.
3. Generate or select a platform project (Gradle, Xcode, CMake, or MSBuild).
4. Pass arguments without shell interpolation and preserve exit codes.
5. Support debug/release, clean, package, and verbose modes.
6. Keep host-specific tool detection isolated; do not claim cross-compilation
   when the required Apple SDK/Xcode host is unavailable.
7. Produce a machine-readable build manifest describing the artifact and ABI.

Proposed target identifiers:

- `windows.x64`, `windows.arm64`
- `linux.x64`, `linux.arm64`
- `macos.x64`, `macos.arm64`
- `ios.arm64`
- `android.arm64`, `android.x86_64`

The current `android.arm.x64` selector is historical and should remain as a
compatibility alias until a migration release.

## Sparrow atlas support

The `lemon.graphics.atlas` package contains a Sparrow XML metadata reader,
ordered prefix lookup, and a time-based animation controller. It reads
`TextureAtlas` and `SubTexture` elements, including trimmed-frame offsets.
`Animation.fromPrefix` builds an animation from a frame-name prefix.

The Windows Direct2D backend exposes source-rectangle texture drawing.
`Sprite.playAnimation(atlas, animation)` loads the atlas image and connects
the animation; call `Sprite.update(elapsedSeconds)` each frame. The Windows
renderer draws the selected atlas rectangle and applies Sparrow trim offsets.
The Android prototype still has only its shape-oriented `GraphicsContext`;
it does not yet render Sprite textures or Sparrow atlases. A backend-neutral
texture API and source-rectangle operation remain required for Android, Linux,
macOS, iOS, and Vulkan backends.

## Validation gates

A platform can be marked supported only after its native host, renderer,
input/lifecycle integration, texture decoding, audio path, packaging, and
automated build checks work. Device-specific features such as Metal, Vulkan,
touch, and iOS signing additionally require validation on real devices or
official platform runners. Documentation and target aliases alone do not count
as compatibility.
