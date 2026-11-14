# Night Framework

Lemon is a Haxe framework for building 2D applications and games. It provides
scene lifecycle helpers, graphics, input, audio, tweens, and platform services.

The current desktop backend targets Windows with Win32, Direct2D, and
DirectWrite. The Android prototype uses Haxe's Java target, OpenGL ES, touch
input, and Android's `MediaPlayer`.

## Requirements

- Haxe
- `hxcpp` and a compatible C++ toolchain (Visual Studio or MinGW) for Windows
- `hxjava`, Java, Android SDK, and Gradle for Android
- `g++` to build the Lemon command-line tool

Install `hxcpp` if it is not already available:

```powershell
haxelib install hxcpp
```

## Lemon command-line tool

From a development checkout, register Lemon with Haxelib and build the CLI:

```powershell
haxelib dev lemon .
haxelib run lemon setup
```

`setup` installs `hxcpp` and `hxjava` if needed and builds `compiler/main.cpp`
as `compiler/lemon.exe` using `g++`. You can then use the CLI directly or
through Haxelib:

```powershell
haxelib run lemon -m windows.x64
lemon create android.arm.x64
lemon -m android.arm.x64
.\compiler\lemon.exe -m windows.x64
```

### Creating an Android project

`lemon create android.arm.x64` creates a self-contained Android project in the
current directory. You may provide a destination directory:

```powershell
lemon create android.arm.x64 MyGame
cd MyGame
lemon -m android.arm.x64
```

The generated project includes the Haxe framework sources, demo, and assets.
Creation does not overwrite existing files. Run `lemon -m android.arm.x64`
from the generated project to build a debug APK.

The CLI builds the project in the current directory when it finds `build.hxml`
for Windows or `gradlew.bat` and `settings.gradle` for Android. Otherwise, it
builds the corresponding demo included with Lemon.

The Android target name `android.arm.x64` is a historical selector. The
current Android application is Java-based and does not include native
libraries for a specific ABI.

## Building the Windows demo

From the `demo` directory:

```powershell
haxe build.hxml
```

This uses Haxe's hxcpp backend and generates the application in `demo/build`.
The native rendering bridge's `@:buildXml` metadata adds the `include/` path
for C++ compilation, so no absolute include path is required.

## Runtime and application modules

Lemon is designed as a runtime library separated from the application or game
module. The planned artifact outputs are:

| Artifact | Purpose | Binary contract |
| --- | --- | --- |
| `.ndll` | Lemon runtime library or native game module | Native platform binary with the Lemon C ABI |
| `.dll` | Windows-compatible runtime library or game module | Windows PE/COFF dynamic library |
| `.hdll` | Haxe application/game module | Haxe module container loaded by a matching Haxe/Lemon runtime |

The output kind is selected by the target and build configuration. A native
module must match the host operating system, CPU architecture, and versioned
Lemon ABI. The build manifest will describe those requirements and the module's
dependencies. The extension alone does not make a binary portable: Windows
uses PE/COFF, Linux uses ELF, and macOS uses Mach-O.

`.hdll` is not a native DLL and must not be passed to the operating-system
dynamic-library loader. Its container format and runtime compatibility rules
are still being designed. Likewise, the module loader and native ABI are
roadmap items; the current build does not yet emit or load all three formats.

iOS requires special handling. Native code must be packaged and signed with
the application under Apple's platform rules. Lemon will not promise arbitrary
loading of downloaded native modules on iOS.

See [Portability and graphics expansion](docs/PORTABILITY_AND_GRAPHICS.md)
for the planned module ABI, platform matrix, and validation requirements.

## Application

`lemon.Application` groups the main window with application services. On
Windows, it supports system notifications, tray notifications, and taskbar
progress:

```haxe
import lemon.Application;

var app = new Application("My application", 800, 600);
if (app.create()) {
    app.show();
    app.progressBar.setProgress(3, 10);
    app.notifications.show("Ready", "The task is complete.");
    app.tray.show("Lemon", "The application is still running.");
    while (app.update()) {
        // Update application logic.
    }
}
app.dispose();
```

Use `app.window` to access the window. `create()`, `show()`, `hide()`,
`update()`, `close()`, and `dispose()` manage its lifecycle. `run()` creates
and shows the window if necessary, then runs the main loop, optionally calling
a callback on each iteration.

`app.progressBar` provides `setProgress(value, maximum)`,
`setIndeterminate()`, `setPaused()`, `setError()`, and `clear()`.
`app.tray.hide()` removes the tray icon. Service errors are exposed through
their `error` property.

On Windows, notifications and tray alerts use native notification-area
balloons, and taskbar progress uses `ITaskbarList3`. These APIs require a
created window and do not yet provide Android, iOS, or macOS notification
backends.

## Sprites and graphics

`Place` manages the window and frame lifecycle; drawing commands belong to
`sprite.graphics` and remain queued until `clear()` is called:

```haxe
import lemon.graphics.Sprite;

var sprite = new Sprite();
sprite.x = 40;
sprite.y = 80;
sprite.graphics.load("assets/hero.png"); // Also accepts haxe.io.Bytes.
sprite.graphics.fillCircle(24, 24, 12, 255, 180, 40);

while (place.update() && place.isOpen()) {
    if (place.beginFrame(20, 24, 36)) {
        place.render(sprite);
        place.endFrame();
    }
}
```

`Sprite` can be positioned, scaled, rotated, and made transparent.
`Graphics.load` accepts a file path or a copy of `haxe.io.Bytes`. Windows
decodes images through Windows Imaging Component. `Graphics` supports lines,
rectangles, circles, and triangles.

Text is represented by a separate `Text` object. Configure its font and
presentation properties before calling `place.renderText(text)`:

```haxe
import lemon.graphics.Text;
import lemon.graphics.FontWeight;
import lemon.graphics.FontStyle;

var label = new Text("Hello Lemon");
label.x = 40;
label.y = 280;
label.fontFamily = "Segoe UI";
label.fontSize = 28;
label.fontWeight = FontWeight.Bold;
label.fontStyle = FontStyle.Italic;
label.color = 0xFFE0A0;
place.renderText(label);
```

`Text` also supports an optional font file path (`fontPath`), font stretch,
horizontal and vertical alignment, dimensions, transforms, opacity, and
visibility. Without `fontPath`, it uses the system font family specified by
`fontFamily` (Segoe UI by default). `Place.render` and `Place.renderText`
return `false` when an object cannot be rendered.

`demo/Main.hx` demonstrates sprites loaded from a path and from bytes, graphics
commands, and a `Text` object. Call `dispose()` when finished.

## Tweens

`Place` exposes `place.tweens` and advances its tweens automatically during
`update()`. Tween destinations can target numeric properties on objects such
as `Sprite` and `Text`:

```haxe
import lemon.tween.Ease;

place.tweens.to(sprite, { x: 400, alpha: 0.25 }, 1.2, Ease.quadInOut)
    .setDelay(0.2)
    .repeat(1, true)
    .onComplete(function() trace("Tween complete"));
```

Tween durations are measured in seconds. `repeat(-1, true)` repeats forever
with a yoyo effect. A tween handle provides `pause()`, `resume()`, and
`clear()`. Available easing functions include `linear`, `quadIn`, `quadOut`,
`quadInOut`, `cubicIn`, `cubicOut`, and `cubicInOut`.

## Video and OpenAL audio on Windows

`lemon.audio.Sound` loads an audio file and provides playback, volume, pitch,
looping, and 3D positioning controls:

```haxe
import lemon.audio.Sound;

var sound = new Sound("assets/effect.wav");
sound.volume = 0.7;
sound.looping = false;
if (!sound.play())
    trace(sound.error);
// sound.pause(); sound.stop(); sound.dispose();
```

The demo accepts `LEMON_SOUND` as the path to a sound file; pressing gamepad
button B plays it. Each sound instance manages its own OpenAL context and
should be released with `dispose()`.

`sprite.graphics.video` plays MP4/MOV video through Media Foundation and
displays its frames in the sprite. Playback depends on the codecs installed
on Windows. The video file's audio is played through OpenAL when possible. If
audio playback is unavailable, `audioStatus` describes the issue while video
may continue:

```haxe
sprite.graphics.video.load("assets/clip.mp4");
sprite.graphics.video.setLooping(true);
sprite.graphics.video.play();
// Also available: pause(), stop(), seek(seconds), currentTime, duration.
```

The demo accepts `LEMON_VIDEO` as the path to a compatible file.
`OpenAL32.dll` (for example, OpenAL Soft) must be available beside the
application or on the Windows loader path. OpenAL audio is decoded to PCM
through Media Foundation; WAV, OGG, and other format support depends on
system codecs. `OpenALSource.queue` can manage queued buffers, but file
decoding currently loads the complete audio file into memory and does not
include an incremental streaming reader.

## Android: Haxe Activity and OpenGL ES

The Android prototype uses Haxe's official Java target (`--java`, backed by
hxjava), not Reflaxe. The project in `demo/android` combines Haxe-generated
Java sources with an Android app. Install hxjava if necessary:

```powershell
haxelib install hxjava
```

From `demo/android`, build a debug APK with:

```powershell
.\gradlew.bat assembleDebug
```

The APK is written to `app/build/outputs/apk/debug/app-debug.apk`. The
launcher Activity is generated from `src/lemon/demo/MainActivity.hx`; no
hand-written Java Activity is required.

`lemon.Activity` provides `create`, `update(elapsed)`, `draw(graphics)`,
`pause`, `resume`, and `destroy` lifecycle callbacks. `GLGraphics` implements
2D primitives on OpenGL ES 2.0. The sample `ShapesActivity.hx` draws shapes
and displays a white point under each active finger.

`lemon.platform.android.AndroidSound` plays audio packaged in the app's
assets using Android's `MediaPlayer`. The demo starts
`demo/assets/re.laced.up.ogg` when it opens and pauses/resumes playback with
the application lifecycle. To load another bundled file:

```haxe
var sound = new AndroidSound(context);
sound.load("audio/music.ogg");
sound.play();
```

`Activity.touch` exposes `activeTouches`, `getTouch(id)`, and the
`touch.down`, `touch.move`, `touch.up`, and `touch.cancel` events. Android
updates multitouch input on the GL frame loop. Touch coordinates are relative
to the rendering surface. Android desktop mouse and gamepad backends are not
implemented yet.

The host uses `GLSurfaceView` and runs rendering on the OpenGL ES thread. It
requires Android SDK API 35, a Java version supported by Gradle, Haxe with
hxjava, and a device supporting OpenGL ES 2.0.

This is an initial Android scene and shape-rendering backend, not a complete
port of `lemon.graphics.Renderer`. Sprites and textures, `Text`, gamepad input,
OpenAL, video, and Android system services are still pending. Android uses
`AndroidSound` for audio; Windows retains its OpenAL backend.

### Using an Activity

Extend `lemon.Activity` and override the lifecycle methods you need. `update`
receives elapsed time in seconds, and `draw` receives the platform-independent
`GraphicsContext` interface. Coordinates are measured in surface pixels:

```haxe
import lemon.Activity;
import lemon.graphics.GraphicsContext;

class GameActivity extends Activity
{
    override public function update(elapsed:Float):Void
    {
        // Update game state. `elapsed` is the time since the previous frame.
    }

    override public function draw(graphics:GraphicsContext):Void
    {
        graphics.clear(24, 28, 38);
        graphics.fillCircle(graphics.width * 0.5, graphics.height * 0.5,
            48, 255, 205, 40);
    }
}
```

For touch input, subscribe to `touch.events`. Event data contains the
corresponding `TouchPoint`:

```haxe
touch.events.on("touch.down", function(event) {
    var point:lemon.input.touch.TouchPoint = cast event.data;
    trace('Pointer ${point.id} at ${point.x}, ${point.y}');
});
```

Override `pause`, `resume`, and `destroy` to suspend and release resources
owned by your activity. Always dispose native resources when they are no
longer needed.

## Input and events on Windows

`Place.update()` pumps Windows messages, updates input state, and dispatches
events. Input classes are organized by package:

```haxe
import lemon.input.keyboard.KeyCode;
import lemon.input.gamepad.GamepadButton;

place.input.events.on("keyboard.keyDown", function(event) {
    if (event.data.keyCode == KeyCode.Escape)
        place.close();
});
place.input.mouse.events.on("mouse.move", function(event) {
    trace('Mouse: ${event.data.x}, ${event.data.y}');
});

while (place.update() && place.isOpen()) {
    if (place.input.keyboard.isDown(KeyCode.Space)) {
        // Space is currently held.
    }
    if (place.input.gamepads[0].isButtonDown(GamepadButton.A)) {
        // Button A on the first gamepad is currently held.
    }
}
```

Events are also delivered through `place.input.events`. Each device has its
own dispatcher (`keyboard.events`, `mouse.events`, and
`gamepads[index].events`). Event types include `keyboard.keyDown`,
`keyboard.keyUp`, `mouse.move`, `mouse.buttonDown`, `mouse.buttonUp`,
`mouse.wheel`, `gamepad.connected`, `gamepad.disconnected`,
`gamepad.buttonDown`, `gamepad.buttonUp`, and `gamepad.axis`. Event payloads
are available through `event.data`.

Mouse coordinates are relative to the window's client area. The wheel uses
standard Windows units (120 per notch). Gamepads use XInput and support up to
four controllers. The current desktop input backend implements keyboard,
mouse, and XInput on Windows. Android currently supports multitouch through
`Activity.touch`, but does not yet have desktop mouse or gamepad backends.

## Platform status and limitations

- **Windows:** Win32 window management, Direct2D/DirectWrite rendering,
  keyboard and mouse input, XInput gamepads, OpenAL audio, and Media Foundation
  video.
- **Android:** Haxe `--java` Activity host, OpenGL ES 2.0 shape rendering,
  multitouch, and basic audio through `MediaPlayer`. This is not yet a full
  `Place` or `Renderer` backend.
- **iOS and macOS:** No host, renderer, or Xcode project generator is
  implemented yet. Building, signing, and testing Apple apps requires macOS
  with Xcode. Shared Haxe code and project generation can be prepared on
  Windows, but Apple applications cannot be built or verified here.
- **Linux:** OpenGL backend is planned.

`Activity.draw` depends on the platform-independent
`lemon.graphics.GraphicsContext` interface. Android currently implements it
with `GLGraphics`; other platform renderers have not been implemented.

## Planned modular architecture

Subsystems live in their own Haxe packages rather than being added to
`lemon` or `lemon.graphics`:

```text
src/lemon/
  graphics/                 # Sprite, Graphics, Text, Renderer, GraphicsContext
  input/
    Input.hx                # lemon.input
    keyboard/               # lemon.input.keyboard
    mouse/                  # lemon.input.mouse
    gamepad/                # lemon.input.gamepad
    touch/                  # lemon.input.touch (Android implemented; iOS planned)
  events/                   # lemon.events
  dialogs/
    error/                  # lemon.dialogs.error
  notifications/            # lemon.notifications
  platform/
    windows/
      taskbar/              # lemon.platform.windows.taskbar
    android/
    ios/
    macos/
    linux/
  net/                      # lemon.net
```

Planned work includes portable error dialogs, platform-specific system
notifications and taskbar progress, networking, and iOS touch support. The
Windows taskbar backend uses `ITaskbarList3` without exposing COM types in the
Haxe API. Shared APIs should remain independent of Win32, Android, and UIKit,
with platform-specific implementations kept in their respective packages.


## New development branch: portability and Sparrow graphics

The branch `feature/portable-platforms-sparrow-atlas` adds the first
Sparrow atlas metadata and animation-clock APIs:

- `lemon.graphics.atlas.TextureAtlas` parses Sparrow XML `TextureAtlas` /
  `SubTexture` metadata, including trimmed-frame offsets.
- `SparrowFrame` stores source rectangle and original frame dimensions.
- `Animation` provides elapsed-time playback, looping, pause, stop, and
  non-looping completion.

Example:

```haxe
import lemon.graphics.atlas.TextureAtlas;
import lemon.graphics.atlas.Animation;

var atlas = TextureAtlas.load("assets/character.xml");
var animation = Animation.fromPrefix(atlas, "idle", 24, true);
var sprite = new lemon.graphics.Sprite();
sprite.playAnimation(atlas, animation);
sprite.update(elapsedSeconds);
place.render(sprite);
```

The Windows Direct2D renderer now draws the selected source rectangle from the
atlas, and Sprite can play an Animation directly. Call `sprite.update(elapsed)`
once per frame before rendering. The Android prototype still exposes only its
shape-oriented GraphicsContext and does not yet implement Sparrow texture
rendering; other future renderers must implement the same source-rectangle
operation before they can display atlas frames.

See [the portability design](docs/PORTABILITY_AND_GRAPHICS.md) and
[the roadmap](docs/ROADMAP.md) for Vulkan, iOS, Linux, macOS, and compiler
work. Those platform backends are planned, not claimed as implemented.
