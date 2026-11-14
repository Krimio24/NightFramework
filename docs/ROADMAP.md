# Lemon roadmap

## Graphics
- [x] Parse Sparrow XML TextureAtlas metadata.
- [x] Provide a frame-based animation clock with loop and non-loop playback.
- [x] Add Windows Direct2D source-rectangle drawing to Renderer.\n- [ ] Add backend-neutral source-rectangle drawing to GraphicsContext and other platform renderers.
- [x] Connect Animation frames to Sprite rendering on Windows.\n- [ ] Connect Sprite animation rendering to Android and future backends.
- [x] Load atlas images through the existing Graphics texture lifecycle on Windows.\n- [ ] Add cross-platform atlas image decoding and validation fixtures.
- [ ] Add TexturePacker/Sparrow export compatibility tests.

## Platform backends
- [ ] Extract a platform-neutral renderer contract from the Windows Renderer.
- [ ] Linux host, window, input, audio, and packaging backend.
- [ ] macOS host and Metal renderer.
- [ ] iOS UIKit host, touch lifecycle, Metal renderer, and Xcode project generation.
- [ ] Vulkan renderer abstraction and device/surface selection.
- [ ] MoltenVK validation for optional Vulkan-on-Apple support.

## Build system
- [ ] Structured target parser and toolchain discovery.
- [ ] CMake-based native build orchestration.
- [ ] Android ABI-specific packaging and optimized release builds.
- [ ] Apple signing/archive workflow on macOS with Xcode.
- [ ] Linux and Windows CI build matrix.
- [ ] Mobile and desktop profiling, incremental builds, and reproducible artifacts.
