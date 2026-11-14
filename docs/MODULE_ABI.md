# Night native module ABI

## Scope

The native module ABI separates the Night runtime library from a game or
application module. This specification defines the first C-compatible ABI
contract for native modules. It does not define the `.hdll` container.

## Artifact rules

- Runtime library: `night.ndll` or `night.dll` (Windows PE/COFF).
- Game module: `game.ndll` or `game.dll`.
- Application module: `app.ndll` or `app.dll`.
- Haxe game/application module: `game.hdll` or `app.hdll`, reserved for a
  separately specified Haxe runtime container. It is not a native shared library.

The payload must match the target's actual binary format and architecture:
PE/COFF on Windows, ELF on Linux, and Mach-O on macOS. A suffix does not alter
the binary format.

## C ABI

Native modules include `include/night/module.h` and export
`night_module_query`. The function returns a descriptor only when the
requested host ABI is compatible. The descriptor contains its own size,
ABI version, minimum runtime version, module name, and lifecycle callbacks.

The boundary uses fixed-width integers, C strings, opaque pointers, and
function pointers. C++ classes, exceptions, STL containers, and ownership of
C++ memory must not cross the ABI. Strings and resources remain owned by the
side that created them unless a future ABI explicitly defines transfer rules.

The host validates the descriptor pointer, structure size, ABI major/minor,
runtime version, and required callbacks before calling initialize. A major
version mismatch is incompatible. A host may accept a module with a lower
minor version only when the required structure prefix and callbacks are
available. The host calls shutdown before unloading an initialized module.

## Platform loading

- Windows: `LoadLibraryW` and `GetProcAddress`.
- Linux: `dlopen` and `dlsym`; ELF module.
- macOS: `dlopen` and `dlsym`; Mach-O module.
- Android: package native modules for each supported ABI and load from the
  application package using the Android linker. Android app-store and package
  policy still apply.
- iOS: compile/link native modules into the signed application bundle. Do not
  promise arbitrary downloaded native code or unrestricted runtime loading.
- Web: this native ABI does not apply; a future WebAssembly module target needs
  a separate ABI and sandbox model.

## Compatibility and security

The loader must reject a module before initialization when its OS, architecture,
binary format, ABI, or runtime requirements do not match. Modules execute with
the permissions of the host process; ABI validation is not a sandbox. Only
load trusted modules, and do not load untrusted downloaded native code.

## Status

The header establishes the initial ABI shape. Platform loaders, build outputs,
ABI conformance tests, the build manifest, and the `.hdll` format are not yet
implemented. Do not describe native module loading as available until those
items are implemented and tested on each platform.
