# lemon – Place 2D (Windows)

`lemon.Place` administra la ventana y el ciclo de vida de los frames. El
renderizado vive en `lemon.graphics.Renderer`; `Sprite`, `Graphics` y `Text`
describen el contenido visual. El backend Windows usa Direct2D/DirectWrite.

## Requisitos

- Haxe
- Haxelib hxcpp y Windows con un compilador C++ compatible (Visual Studio o MinGW) para el backend Windows
- Haxelib hxjava para generar fuentes Java del port Android

Instala hxcpp si aún no está instalado:

```powershell
haxelib install hxcpp
```

## CLI de compilacion

El CLI nativo C++ vive en `compiler/`. Desde una copia de desarrollo, registra
la carpeta una vez en Haxelib y ejecuta el setup:

```powershell
haxelib dev lemon .
haxelib run lemon setup
```

`setup` instala `hxcpp` y `hxjava` si hacen falta y compila
`compiler/main.cpp` como `compiler/lemon.exe` usando `g++`. Despues puedes
invocar el CLI mediante Haxelib o directamente:

```powershell
haxelib run lemon -m windows.x64
lemon create android.arm.x64
lemon -m android.arm.x64
.\compiler\lemon.exe -m windows.x64
```

`lemon create android.arm.x64` crea en la carpeta actual un proyecto Android
completo, autocontenido y listo para compilar; tambien acepta un directorio de
destino opcional. No sobrescribe archivos existentes. Despues ejecuta
`lemon -m android.arm.x64` desde el proyecto creado para generar la APK debug.
El proyecto incluye el framework Haxe, la demo y sus assets. El CLI compila el
proyecto de la carpeta actual si encuentra `build.hxml` (Windows) o
`gradlew.bat` con `settings.gradle` (Android); si no, compila la demo incluida.
Para Windows usa Haxe/hxcpp. Android requiere Java, Android SDK y las
dependencias Gradle de Android. El nombre `android.arm.x64` es el selector
historico del target; la APK actual usa Java y no contiene bibliotecas nativas
especificas por ABI. `setup` requiere `g++` disponible en `PATH`; tambien se
requiere registrar la copia de desarrollo con Haxelib una vez (o instalar
Lemon desde Haxelib).

## Compilación de la demo

Desde la carpeta `demo`:

```powershell
haxe build.hxml
```

Esto usa el backend hxcpp incluido en Haxe y genera la aplicación en `demo/build`.
La metadata `@:buildXml` del puente nativo de renderizado añade la ruta de
`include/` al compilador C++, así que no hace falta configurar una ruta absoluta.

## Application

`lemon.Application` agrupa la ventana principal y los servicios asociados de
la aplicacion. En Windows, proporciona notificaciones del sistema, avisos del
area de notificacion y progreso en el boton de la barra de tareas:

```haxe
import lemon.Application;

var app = new Application("Mi aplicación", 800, 600);
if (app.create()) {
    app.show();
    app.progressBar.setProgress(3, 10);
    app.notifications.show("Listo", "La tarea terminó.");
    app.tray.show("Lemon", "La aplicación sigue ejecutándose.");
    while (app.update()) {
        // Actualizar la lógica de la aplicación.
    }
}
app.dispose();
```

La ventana se obtiene mediante `app.window`; `create()`, `show()`, `hide()`,
`update()`, `close()` y `dispose()` coordinan el ciclo de vida. `run()` crea y
muestra la ventana si hace falta y bombea el bucle principal, opcionalmente
llamando un callback por iteracion. `app.progressBar` permite
`setProgress(value, maximum)`, `setIndeterminate()`, `setPaused()`,
`setError()` y `clear()`. `app.tray.hide()` quita el icono del area de
notificacion. Los errores de los servicios se exponen mediante su propiedad
`error`.

En el backend Windows, las notificaciones y avisos de bandeja se presentan
como notificaciones nativas del area de notificacion (icono temporal y globo
del sistema); el progreso usa `ITaskbarList3`. Estas APIs dependen de una
ventana creada y no sustituyen aun los backends de notificaciones/toasts de
Android, iOS o macOS.

## Sprites y Graphics

`Place` no contiene la API de formas: comienza/termina frames y delega la
presentacion a `Renderer`. Los comandos se agregan en `sprite.graphics` y quedan
retenidos hasta `clear()`:

```haxe
import lemon.graphics.Sprite;

var sprite = new Sprite();
sprite.x = 40;
sprite.y = 80;
sprite.graphics.load("assets/hero.png"); // Tambien acepta haxe.io.Bytes
sprite.graphics.fillCircle(24, 24, 12, 255, 180, 40);

while (place.update() && place.isOpen()) {
  if (place.beginFrame(20, 24, 36)) {
    place.render(sprite);
    place.endFrame();
  }
}
```

`Sprite` permite mover, escalar, rotar y cambiar opacidad. `Graphics.load` admite
una ruta o una copia de `haxe.io.Bytes`; los formatos de imagen los decodifica
Windows Imaging Component. `Graphics` ofrece lineas, rectangulos, circulos y
triangulos. El texto es un objeto independiente y sus propiedades de fuente y
presentacion se configuran antes de `place.renderText(text)`:

```haxe
import lemon.graphics.Text;
import lemon.graphics.FontWeight;
import lemon.graphics.FontStyle;

var label = new Text("Hola Lemon");
label.x = 40;
label.y = 280;
label.fontFamily = "Segoe UI";
label.fontSize = 28;
label.fontWeight = FontWeight.Bold;
label.fontStyle = FontStyle.Italic;
label.color = 0xFFE0A0;
place.renderText(label);
```

`Text` tambien admite una ruta opcional de archivo de fuente (`fontPath`),
`fontStretch`, alineacion horizontal/vertical, dimensiones, posicion,
transformacion, opacidad y visibilidad. Sin `fontPath`, usa la familia del
sistema indicada por `fontFamily` (Segoe UI por defecto). `Place.render` y
`Place.renderText` devuelven `false` cuando no pueden procesar el objeto.

`demo/Main.hx` demuestra sprites con imagen cargada desde ruta y desde bytes,
comandos de `Graphics` y un objeto `Text`. Llama `dispose()` al terminar.

## Tweens

`Place` mantiene `place.tweens` y actualiza sus animaciones automáticamente
desde `update()`. Los destinos aceptan propiedades numéricas, como las de
`Sprite` y `Text`:

```haxe
import lemon.tween.Ease;

place.tweens.to(sprite, { x: 400, alpha: 0.25 }, 1.2, Ease.quadInOut)
    .setDelay(0.2)
    .repeat(1, true)
    .onComplete(function() trace("Tween terminado"));
```

Los tweens se expresan en segundos; `repeat(-1, true)` los repite
indefinidamente con ida y vuelta. El manejador ofrece `pause()`, `resume()` y
`clear()`. Hay easing `linear`, `quadIn`, `quadOut`, `quadInOut`, `cubicIn`,
`cubicOut` y `cubicInOut`.

## Video y audio OpenAL (Windows)

La clase `lemon.audio.Sound` carga un archivo y expone controles de
reproduccion, volumen, pitch, repeticion y posicion 3D:

```haxe
import lemon.audio.Sound;

var sound = new Sound("assets/effect.wav");
sound.volume = 0.7;
sound.looping = false;
if (!sound.play())
    trace(sound.error);
// sound.pause(); sound.stop(); sound.dispose();
```

La demo acepta `LEMON_SOUND` para cargar un sonido; el boton B del gamepad lo
reproduce. Cada instancia administra su contexto OpenAL y debe liberarse con
`dispose()`.

`sprite.graphics.video` reproduce video MP4/MOV mediante Media Foundation y
presenta sus frames en el sprite. La decodificacion depende de los codecs
instalados en Windows. El audio del archivo se intenta reproducir con OpenAL;
si el audio no esta disponible, `audioStatus` expone el motivo y el video
visual puede continuar:

```haxe
sprite.graphics.video.load("assets/clip.mp4");
sprite.graphics.video.setLooping(true);
sprite.graphics.video.play();
// Tambien: pause(), stop(), seek(seconds), currentTime, duration
```

La demo acepta la variable de entorno `LEMON_VIDEO` con la ruta a un archivo
compatible. Para audio se necesita `OpenAL32.dll` (por ejemplo, OpenAL Soft)
disponible junto a la aplicacion o en la ruta de carga de Windows. OpenAL
decodifica audio a PCM mediante Media Foundation; la disponibilidad de WAV,
OGG u otros formatos depende de los codecs del sistema. `OpenALSource.queue`
permite administrar buffers en cola, pero la decodificacion de archivos
actualmente carga el audio completo en memoria y no implementa un lector
incremental integrado.

## Android (Activity Haxe y OpenGL ES)

El target Java aprobado para el port es el target oficial de Haxe (`--java`,
respaldado por hxjava), no Reflaxe. El proyecto en `demo/android` integra las
fuentes generadas por Haxe con una Activity Android y crea un APK de prueba.
Desde esa carpeta se compila con:

Instala el soporte Java con `haxelib install hxjava`.

```powershell
.\gradlew.bat assembleDebug
```

El APK de depuracion queda en
`app/build/outputs/apk/debug/app-debug.apk`. La Activity Android que registra
el manifest se genera desde `src/lemon/demo/MainActivity.hx`; no hace falta
editar una Activity Java. `lemon.Activity` funciona como una escena/state de
Flixel con callbacks `create`, `update(elapsed)`, `draw(graphics)`, `pause`,
`resume` y `destroy`. `GLGraphics` ofrece primitivas 2D sobre OpenGL ES 2.0:
`clear`, rectangulos, circulos, ovalos, triangulos y lineas. La demo de
`ShapesActivity.hx` dibuja solo formas usando ese renderer.
`lemon.platform.android.AndroidSound` reproduce audio incluido en `assets`
con el `MediaPlayer` de Android. La demo reproduce `demo/assets/re.laced.up.ogg`
al iniciar y pausa/reanuda el sonido al cambiar el estado de la aplicacion.
Para otros sonidos, carga un asset con `new AndroidSound(context)`,
`load("archivo.ogg")` y `play()`.
`Activity.touch` expone `activeTouches`, `getTouch(id)` y los eventos
`touch.down`, `touch.move`, `touch.up` y `touch.cancel`. El backend Android
actualiza el input multitactil desde el ciclo GL; los puntos usan coordenadas
de la superficie de render. La demo dibuja un punto blanco bajo cada dedo.

El host usa `GLSurfaceView` y entrega el ciclo de render a OpenGL ES en el hilo
de GL. Requiere Android SDK (API 35), JDK 17 o superior compatible con Gradle,
Haxe con hxjava instalado y un dispositivo con OpenGL ES 2.0.

Este es el primer backend Android de escenas y formas, no el port entero de
`lemon.graphics.Renderer`: sprites/texturas, `Text`, input gamepad, audio
OpenAL, video y servicios Android siguen pendientes. Android ya admite touch
mediante `Activity.touch` y audio mediante `AndroidSound`; Windows conserva su
backend OpenAL.

`Activity.draw` usa `lemon.graphics.GraphicsContext`, una interfaz de dibujo
compartida que no depende de Android. `GLGraphics` es la implementacion actual
para Android; el backend Metal de iOS/macOS todavia no esta implementado.

### Using an Activity

Extend `lemon.Activity` and override the lifecycle methods you need. `update`
receives elapsed time in seconds, and `draw` receives a platform-independent
`GraphicsContext` whose coordinates are measured in surface pixels:

```haxe
import lemon.Activity;
import lemon.graphics.GraphicsContext;

class GameActivity extends Activity
{
    override public function update(elapsed:Float):Void
    {
        // Update your game state. `elapsed` is the time since the previous frame.
    }

    override public function draw(graphics:GraphicsContext):Void
    {
        graphics.clear(24, 28, 38);
        graphics.fillCircle(graphics.width * 0.5, graphics.height * 0.5,
            48, 255, 205, 40);
    }
}
```

For touch input, subscribe to `touch.events`. Event payloads are available as
`event.data` and contain the corresponding `TouchPoint`:

```haxe
touch.events.on("touch.down", function(event) {
    var point:lemon.input.touch.TouchPoint = cast event.data;
    trace('Pointer ${point.id} at ${point.x}, ${point.y}');
});
```

Override `pause`, `resume`, and `destroy` to suspend and release resources
owned by your activity. Always dispose native resources when they are no
longer needed.

## Input y eventos (Windows)

`Place.update()` bombea los mensajes de Windows, actualiza el estado de input y
despacha los eventos. Las APIs y tipos estan separados por paquete:

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
        // El espacio esta presionado.
    }
    if (place.input.gamepads[0].isButtonDown(GamepadButton.A)) {
        // El boton A del primer mando esta presionado.
    }
}
```

Los eventos tambien se reciben en `place.input.events`. Los dispositivos
exponen dispatchers propios (`keyboard.events`, `mouse.events` y
`gamepads[index].events`). Los tipos publicados son `keyboard.keyDown`,
`keyboard.keyUp`, `mouse.move`, `mouse.buttonDown`, `mouse.buttonUp`,
`mouse.wheel`, `gamepad.connected`, `gamepad.disconnected`,
`gamepad.buttonDown`, `gamepad.buttonUp` y `gamepad.axis`; el payload va en
`event.data`. Las coordenadas del mouse son relativas al cliente de la ventana,
y la rueda usa las unidades estandarizadas de Windows (120 por notch).
Gamepads usa XInput y admite hasta cuatro mandos. El backend actual solo
implementa teclado, mouse y XInput en Windows; los paquetes publicos se separan
del adaptador nativo para permitir otros backends.

En Android, el mouse de escritorio aun no tiene backend; la superficie
`Activity.touch` admite entrada tactil multitouch.

## Estado y límites

- Implementación actual: Windows, Win32 + Direct2D/DirectWrite.
- `Place.hx` administra la ventana y delega el renderizado a `lemon.graphics.Renderer`.
- El puente nativo hxcpp incorpora la cabecera C++ mediante `@:include`.
- El constructor acepta un `String` normal de Haxe.
- Android usa Haxe `--java`/hxjava para `Activity`, OpenGL ES, touch y audio
  basico; no es todavia el backend completo de `Place`.
- `Activity.draw` ahora depende de `GraphicsContext`, lo que permite agregar
  renderers de otras plataformas sin acoplar la escena a GLES.
- iOS/macOS aun no tienen host, renderer ni proyecto Xcode generable. Para
  compilar, firmar y probar esos targets hace falta macOS con Xcode; el codigo
  comun y el generador pueden prepararse desde Windows, pero no verificarse
  aqui como aplicaciones Apple.
- Linux/OpenGL queda para una etapa posterior.

## Arquitectura modular planeada

Cada subsistema vivira en su propio directorio y paquete Haxe; no se acumularan
clases de input, red, dialogos o servicios del sistema dentro de `lemon` ni de
`lemon.graphics`. La estructura prevista es:

```text
src/lemon/
  graphics/                 # Sprite, Graphics, Text y Renderer
  input/
    Input.hx                # lemon.input
    keyboard/               # lemon.input.keyboard
    mouse/                  # lemon.input.mouse
    gamepad/                # lemon.input.gamepad
    touch/                  # lemon.input.touch (Android implementado, iOS pendiente)
  events/                   # lemon.events: eventos y suscripciones
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

El orden de implementacion previsto para las siguientes etapas sera:

1. **Dialogos de error:** API portable en `lemon.dialogs.error`, con un backend
   nativo separado por plataforma.
2. **Servicios del sistema:** ampliar `Application` con backends de
   notificaciones y progreso de taskbar para Android, iOS, macOS y Linux. El
   backend Windows actual usa `ITaskbarList3` y Win32 sin exponer tipos COM en
   la API Haxe.
3. **Red:** API comun en `lemon.net`; transporte y detalles especificos de
   plataforma quedaran en backends separados.
4. **Touch movil:** completar y ampliar `lemon.input.touch` con un backend para
   iOS; Android ya reporta los eventos tactiles desde `lemon.Activity`.

Los dialogos de error, red y soporte touch de iOS siguen siendo roadmap. Las APIs
comunes no dependeran de Win32, Android o UIKit; cada plataforma implementara
su propio backend en el paquete correspondiente. Se mantienen independientes
el ciclo de vida de `Place`, el renderizador y los servicios de sistema.
