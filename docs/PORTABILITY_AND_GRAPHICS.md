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

## Target architecture

Keep the public Haxe API platform-neutral and select a backend at compile time.
Native implementation files should live under `src/lemon/platform/<platform>`.
Avoid leaking Win32, UIKit, Cocoa, X11/Wayland, Vulkan, or JNI types into shared
Haxe packages.

| Target | Host and packaging | Renderer direction |
| --- | --- | --- |
| Windows | Win32; existing hxcpp build | Direct2D first; Vulkan optional |
| Android | Android Gradle + hxjava host | OpenGL ES baseline; Vulkan capability path |
| iOS | UIKit + Xcode project and signing | Metal baseline; Vulkan only through a portability layer |
| macOS | Cocoa + Xcode or CMake | Metal baseline; Vulkan optional through MoltenVK |
| Linux | X11/Wayland host and native packages | Vulkan with OpenGL fallback |

Vulkan is not a universal replacement for platform APIs. iOS does not expose
native Vulkan; a Vulkan renderer there requires a translation layer such as
MoltenVK and must be validated against Apple's graphics and App Store rules.
Metal should remain the native Apple rendering path.

## Compiler and project generation

The C++ CLI should become a thin, deterministic project orchestrator:

1. Parse a target into platform, architecture, configuration, and renderer.
2. Validate required SDKs and toolchains before starting a build.
3. Generate or select a platform project (Gradle, Xcode, CMake, or MSBuild).
4. Pass arguments without shell interpolation and preserve exit codes.
5. Support debug/release, clean, package, and verbose modes.
6. Keep host-specific tool detection isolated; do not claim cross-compilation
   when the required Apple SDK/Xcode host is unavailable.

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

The Windows Direct2D backend now exposes source-rectangle texture drawing.
`Sprite.playAnimation(atlas, animation)` loads the atlas image and connects
the animation; call `Sprite.update(elapsedSeconds)` each frame. The Windows
renderer draws only the selected atlas rectangle and applies Sparrow trim
offsets. The Android prototype still has only its shape-oriented
`GraphicsContext`; it does not yet render Sprite textures or Sparrow atlases.
A backend-neutral texture API and source-rectangle operation remain required
for Android, Linux, macOS, iOS, and Vulkan backends.
