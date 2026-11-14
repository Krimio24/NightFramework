# Night roadmap

## Graphics and assets
- [x] Parse Sparrow XML TextureAtlas metadata.
- [x] Provide a frame-based animation clock with loop and non-loop playback.
- [x] Add Windows Direct2D source-rectangle drawing to Renderer.
- [x] Connect Animation frames to Sprite rendering on Windows.
- [x] Load atlas images through the existing Graphics texture lifecycle on Windows.
- [ ] Add backend-neutral source-rectangle drawing to GraphicsContext and other platform renderers.
- [ ] Connect Sprite animation rendering to Android and future backends.
- [ ] Add cross-platform atlas image decoding and validation fixtures.
- [ ] Add TexturePacker/Sparrow export compatibility tests.

## Module system
- [x] Define the initial versioned C-compatible native module ABI header.
- [ ] Implement native module loading, lifecycle management, and ABI validation.
- [ ] Build the Night runtime as `night.ndll` / `night.dll`.
- [ ] Emit game modules as `game.ndll` / `game.dll` / `game.hdll`.
- [ ] Emit application modules as `app.ndll` / `app.dll` / `app.hdll`.
- [ ] Build native app/game modules as `.ndll` or `.dll` according to target.
- [ ] Define the `.hdll` Haxe module container, runtime versioning, and loader.
- [ ] Add module manifest with OS, architecture, binary format, ABI, and dependencies.
- [ ] Add safe load, compatibility checks, unload, and resource shutdown.
- [ ] Validate iOS packaging/signing restrictions; no arbitrary downloaded native modules.

## Platform backends
- [ ] Extract a platform-neutral renderer contract from the Windows Renderer.
- [ ] Complete Android Sprite/Texture/Text rendering and Sparrow atlas support on OpenGL ES 2.
- [ ] Android ABI-specific builds for arm64-v8a and x86_64.
- [ ] Linux host, window, input, audio, and packaging backend (X11/Wayland).
- [ ] Linux Vulkan renderer and OpenGL fallback.
- [ ] macOS host, input, audio, packaging, and Metal renderer.
- [ ] iOS UIKit host, touch lifecycle, Metal renderer, and Xcode project generation.
- [ ] Vulkan renderer abstraction and device/surface selection.
- [ ] MoltenVK validation for optional Vulkan-on-macOS and iOS portability.

## Build system and toolchain
- [ ] Structured target parser and toolchain discovery.
- [ ] CMake-based native build orchestration.
- [ ] Selectable native module output: `.ndll`, `.dll`, or `.hdll`.
- [ ] Optimized desktop and mobile builds (LTO where supported, symbols, strip, debug info).
- [ ] Incremental builds, dependency caching, and reproducible artifacts.
- [ ] Apple signing/archive workflow on macOS with Xcode.
- [ ] Linux, Windows, and Android CI build matrix.
- [ ] Device validation for iOS and Android graphics paths.
