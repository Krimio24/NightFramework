package;

import lemon.Application;
import lemon.Place;
import lemon.graphics.Sprite;
import lemon.graphics.Text;
import lemon.graphics.FontWeight;
import lemon.graphics.FontStyle;
import lemon.tween.Ease;
import lemon.audio.Sound;
import lemon.audio.openal.OpenALContext;
import lemon.audio.openal.OpenALConstants;
import haxe.io.Bytes;
import sys.io.File;

class Main
{
    static function main():Void
    {
        var application = new Application("Mi Ventana", 800, 600);
        var place:Place = application.window;

        if (!application.create())
        {
            trace("No se pudo crear la ventana.");
            application.dispose();
            return;
        }

        application.show();
        var imagePath = Sys.getEnv("WINDIR") + "\\Web\\Wallpaper\\Windows\\img0.jpg";
        var sprite = new Sprite();
        sprite.x = 40;
        sprite.y = 100;
        sprite.width = 320;
        sprite.height = 180;
        if (!sprite.graphics.load(imagePath))
            trace("No se pudo configurar la imagen del sprite.");

        var byteSprite = new Sprite();
        byteSprite.x = 390;
        byteSprite.y = 100;
        byteSprite.width = 320;
        byteSprite.height = 180;
        var imageBytes:Bytes = File.getBytes(imagePath);
        if (!byteSprite.graphics.load(imageBytes))
            trace("No se pudo cargar la imagen desde Bytes.");
        byteSprite.graphics.drawRect(0, 0, byteSprite.width, byteSprite.height, 240, 244, 250, 255, 2);
        byteSprite.graphics.fillCircle(160, 120, 28, 244, 178, 58, 230);
        place.tweens.to(byteSprite, { rotation: 3 }, 1, Ease.quadInOut).repeat(-1, true);

        var videoSprite = new Sprite();
        videoSprite.x = 240;
        videoSprite.y = 330;
        videoSprite.width = 320;
        videoSprite.height = 180;
        var videoPath = Sys.getEnv("LEMON_VIDEO");
        var videoLoaded = videoPath != null && videoSprite.graphics.video.load(videoPath);
        if (videoLoaded)
        {
            videoSprite.graphics.video.setLooping(true);
            videoSprite.graphics.video.play();
            if (videoSprite.graphics.video.audioStatus.length > 0)
                trace('Video audio unavailable: ${videoSprite.graphics.video.audioStatus}');
        }
        else if (videoPath != null)
            trace('Video could not be loaded: ${videoSprite.graphics.video.error}');

        var sampleSound = new Sound();
        var soundPath = Sys.getEnv("LEMON_SOUND");
        if (soundPath != null && !sampleSound.load(soundPath))
            trace('Sound could not be loaded: ${sampleSound.error}');

        var label = new Text("Loaded from Bytes");
        label.x = 402;
        label.y = 112;
        label.width = 290;
        label.height = 36;
        label.fontSize = 20;
        label.fontWeight = FontWeight.SemiBold;
        label.fontStyle = FontStyle.Italic;

        var gamepadStatus = new Text();
        gamepadStatus.x = 24;
        gamepadStatus.y = 24;
        gamepadStatus.width = 750;
        gamepadStatus.height = 60;
        gamepadStatus.fontSize = 16;
        var lastGamepadEvent = "none";
        var audio = new OpenALContext();
        var toneBuffer = null;
        var toneSource = null;
        if (audio.open())
        {
            var sampleCount = 22050;
            var toneBytes = Bytes.alloc(sampleCount * 2);
            for (sample in 0...sampleCount)
            {
                var value = Std.int(Math.sin(sample * Math.PI * 2 * 440 / 22050) * 8192);
                toneBytes.setUInt16(sample * 2, value & 0xFFFF);
            }
            toneBuffer = audio.createBufferFromPCM(toneBytes, 1, 16, 22050);
            toneSource = audio.createSource();
            if (toneBuffer != null && toneSource != null)
            {
                toneSource.bind(toneBuffer);
                toneSource.setPosition(0, 0, -2);
            }
            else
                trace('OpenAL audio setup failed: ${audio.lastError}');
        }
        else
            trace('OpenAL unavailable: ${audio.lastError}');

        place.input.events.on("gamepad.connected", function(event) {
            lastGamepadEvent = "connected";
        });
        place.input.events.on("gamepad.disconnected", function(event) {
            lastGamepadEvent = "disconnected";
        });
        place.input.events.on("gamepad.buttonDown", function(event) {
            lastGamepadEvent = 'buttonDown 0x${StringTools.hex(event.data.button, 4)}';
        });
        place.input.events.on("gamepad.buttonUp", function(event) {
            lastGamepadEvent = 'buttonUp 0x${StringTools.hex(event.data.button, 4)}';
        });
        place.input.events.on("gamepad.buttonDown", function(event) {
            if (event.data.button == 0x1000 && toneSource != null)
                toneSource.play();
            if (event.data.button == 0x2000 && sampleSound.isLoaded && !sampleSound.play())
                trace('Sound playback failed: ${sampleSound.error}');
            if (event.data.button == 0x4000 && !application.progressBar.setProgress(50, 100))
                trace('Taskbar progress failed: ${application.progressBar.error}');
            if (event.data.button == 0x8000 && !application.tray.show("Lemon", "Tray notification test"))
                trace('Tray notification failed: ${application.tray.error}');
        });

        place.input.events.on("keyboard.keyDown", function(event) {
            if (event.data.keyCode == 0x1B)
                place.close();
        });

        while (application.update() && place.isOpen())
        {
            var gamepad = place.input.gamepads[0];
            gamepadStatus.text = gamepad.connected
                ? 'Xbox/XInput 0 connected | A: ${gamepad.isButtonDown(0x1000)} | left: ${Std.int(gamepad.leftX * 100)}, ${Std.int(gamepad.leftY * 100)} | event: $lastGamepadEvent'
                : "Xbox/XInput 0 disconnected";

            if (place.beginFrame(20, 24, 36))
            {
                if (!place.render(sprite))
                    trace("No se pudo renderizar el sprite de archivo.");
                if (!place.render(byteSprite))
                    trace("No se pudo renderizar el sprite de Bytes.");
                if (videoLoaded && !place.render(videoSprite))
                    trace('No se pudo renderizar el video: ${videoSprite.graphics.video.error}');
                if (!place.renderText(label))
                    trace("No se pudo renderizar el texto.");
                if (!place.renderText(gamepadStatus))
                    trace("No se pudo renderizar el estado del gamepad.");
                if (!place.endFrame())
                    trace("No se pudo presentar el frame.");
            }
            Sys.sleep(1 / 60);
        }

        sprite.graphics.clear();
        byteSprite.graphics.clear();
        sampleSound.dispose();
        videoSprite.graphics.video.dispose();
        if (toneSource != null)
            toneSource.dispose();
        if (toneBuffer != null)
            toneBuffer.dispose();
        audio.dispose();
        application.progressBar.clear();
        application.close();
        application.dispose();
    }
}