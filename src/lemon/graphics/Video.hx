package lemon.graphics;

import haxe.io.Bytes;
import lemon.audio.openal.OpenALBuffer;
import lemon.audio.openal.OpenALContext;
import lemon.audio.openal.OpenALSource;
import lemon.graphics.internal.NativeVideo;

class Video
{
    private var native:cpp.Pointer<NativeVideo>;
    private var loaded:Bool = false;
    private var disposed:Bool = false;
    private var playing:Bool = false;
    private var looping:Bool = false;
    private var clockStart:Float = 0;
    private var pausedAt:Float = 0;
    private var pixels:Bytes;
    private var frameVersion:Int = 0;
    private var uploadedVersion:Int = -1;
    private var textureId:Int = -1;
    private var textureOwner:Renderer;
    private var textureGeneration:Int = -1;
    private var lastError:String = "";
    private var audioError:String = "";
    private var audioContext:OpenALContext;
    private var audioBuffer:OpenALBuffer;
    private var audioSource:OpenALSource;

    public function new()
    {
    }

    public var isLoaded(get, never):Bool;
    public var isPlaying(get, never):Bool;
    public var duration(get, never):Float;
    public var currentTime(get, never):Float;
    public var videoWidth(get, never):Int;
    public var videoHeight(get, never):Int;
    public var error(get, never):String;
    public var audioStatus(get, never):String;

    public function load(path:String):Bool
    {
        if (disposed)
        {
            lastError = "Video has been disposed.";
            return false;
        }
        if (path == null || path.length == 0)
        {
            lastError = "A non-empty video path is required.";
            return false;
        }
        unload();
        audioError = "";
        if (native == null)
            native = NativeVideo.allocate();
        if (!native.ptr.open(path))
        {
            lastError = "Media Foundation could not open or decode this video.";
            return false;
        }
        loaded = true;
        pausedAt = 0;
        pixels = Bytes.alloc(videoWidth * videoHeight * 4);
        if (!readFrame())
        {
            unload();
            lastError = "Media Foundation did not return a video frame.";
            return false;
        }
        openAudio(path);
        lastError = "";
        return true;
    }

    public function play():Bool
    {
        if (!loaded || disposed)
        {
            lastError = "Load a video before starting playback.";
            return false;
        }
        if (!playing)
        {
            if (pausedAt >= duration)
                seek(0);
            clockStart = haxe.Timer.stamp() - pausedAt;
            playing = true;
            if (audioSource != null)
            {
                if (!audioSource.setSecondsOffset(pausedAt) || !audioSource.play())
                    audioError = audioContext.lastError;
            }
        }
        return true;
    }

    public function pause():Void
    {
        if (!playing)
            return;
        pausedAt = Math.min(duration, Math.max(0, haxe.Timer.stamp() - clockStart));
        playing = false;
        if (audioSource != null)
            audioSource.pause();
    }

    public function stop():Void
    {
        if (!loaded || disposed)
            return;
        playing = false;
        pausedAt = 0;
        if (audioSource != null)
        {
            audioSource.stop();
            audioSource.setSecondsOffset(0);
        }
        if (!native.ptr.seek(0) || !readFrame())
            lastError = "Media Foundation could not rewind the video.";
        else
            lastError = "";
    }

    public function seek(seconds:Float):Bool
    {
        if (!loaded || disposed)
        {
            lastError = "Load a video before seeking.";
            return false;
        }
        if (!Math.isFinite(seconds))
        {
            lastError = "The seek position must be a finite number.";
            return false;
        }
        pausedAt = Math.max(0, Math.min(duration, seconds));
        if (!native.ptr.seek(pausedAt) || !readFrame())
        {
            lastError = "Media Foundation could not seek to the requested position.";
            return false;
        }
        if (audioSource != null)
        {
            audioSource.pause();
            if (!audioSource.setSecondsOffset(pausedAt))
                audioError = audioContext.lastError;
            if (playing && !audioSource.play())
                audioError = audioContext.lastError;
        }
        if (playing)
            clockStart = haxe.Timer.stamp() - pausedAt;
        return true;
    }

    public function setLooping(value:Bool):Void
    {
        looping = value;
        if (audioSource != null)
            audioSource.setLooping(value);
    }

    public function unload():Void
    {
        if (playing)
            pause();
        loaded = false;
        playing = false;
        pausedAt = 0;
        pixels = null;
        if (audioSource != null)
        {
            audioSource.dispose();
            audioSource = null;
        }
        if (audioBuffer != null)
        {
            audioBuffer.dispose();
            audioBuffer = null;
        }
        if (audioContext != null)
        {
            audioContext.dispose();
            audioContext = null;
        }
        frameVersion++;
        if (textureOwner != null && !textureOwner.isDisposed() &&
            textureGeneration == textureOwner._resourceGeneration())
            textureOwner._unloadTexture(textureId);
        textureOwner = null;
        textureId = -1;
        textureGeneration = -1;
        uploadedVersion = -1;
        if (!disposed && native != null)
            native.ptr.close();
    }

    public function dispose():Void
    {
        if (disposed)
            return;
        unload();
        if (native != null)
        {
            native.destroy();
            native = null;
        }
        disposed = true;
    }

    @:allow(lemon.graphics.Graphics)
    @:allow(lemon.graphics.Renderer)
    private function prepare(renderer:Renderer):Bool
    {
        if (!loaded || disposed)
            return true;

        var changed = false;
        if (playing)
        {
            var targetTime = haxe.Timer.stamp() - clockStart;
            if (duration > 0 && targetTime >= duration)
            {
                if (looping)
                {
                    if (!native.ptr.seek(0))
                        return fail("Could not restart the video at end of stream.");
                    clockStart = haxe.Timer.stamp();
                    targetTime = 0;
                    if (!readFrame())
                        return fail("Could not decode the first frame after looping.");
                    changed = true;
                }
                else
                {
                    targetTime = duration;
                    pausedAt = duration;
                    playing = false;
                    if (audioSource != null)
                        audioSource.pause();
                }
            }

            var reads = 0;
            while (playing && reads < 8 && native.ptr.frameTime() < targetTime)
            {
                if (!readFrame())
                {
                    if (looping && native.ptr.seek(0))
                    {
                        clockStart = haxe.Timer.stamp();
                        targetTime = 0;
                        if (!readFrame())
                            return fail("Could not decode the next video frame.");
                        changed = true;
                    }
                    else
                    {
                        pausedAt = Math.min(duration, targetTime);
                        playing = false;
                        if (audioSource != null)
                            audioSource.pause();
                    }
                    break;
                }
                changed = true;
                reads++;
            }
        }

        if (textureOwner != renderer || textureId < 0 ||
            textureGeneration != renderer._resourceGeneration())
        {
            if (textureOwner != null && !textureOwner.isDisposed() && textureOwner != renderer &&
                textureGeneration == textureOwner._resourceGeneration())
                textureOwner._unloadTexture(textureId);
            textureId = renderer._loadTexturePixels(pixels.getData(), pixels.length, videoWidth, videoHeight);
            if (textureId < 0)
                return fail("Could not create the video texture.");
            textureOwner = renderer;
            textureGeneration = renderer._resourceGeneration();
            uploadedVersion = frameVersion;
        }
        else if (changed || uploadedVersion != frameVersion)
        {
            if (!renderer._updateTexturePixels(textureId, pixels.getData(), pixels.length, videoWidth, videoHeight))
                return fail("Could not update the video texture.");
            uploadedVersion = frameVersion;
        }
        return true;
    }

    @:allow(lemon.graphics.Graphics)
    private function isAvailable():Bool
    {
        return loaded && !disposed;
    }

    @:allow(lemon.graphics.Graphics)
    private function texture():Int
    {
        return textureId;
    }

    private function readFrame():Bool
    {
        if (!native.ptr.readFrame() || !native.ptr.copyFrame(pixels.getData(), pixels.length))
            return false;
        frameVersion++;
        return true;
    }

    private function openAudio(path:String):Void
    {
        audioError = "";
        audioContext = new OpenALContext();
        if (!audioContext.open())
        {
            audioError = audioContext.lastError;
            audioContext.dispose();
            audioContext = null;
            return;
        }

        audioBuffer = audioContext.createBuffer(path);
        if (audioBuffer == null)
        {
            audioError = audioContext.lastError;
            audioContext.dispose();
            audioContext = null;
            return;
        }

        audioSource = audioContext.createSource();
        if (audioSource == null || !audioSource.bind(audioBuffer))
        {
            audioError = audioContext.lastError;
            if (audioSource != null)
            {
                audioSource.dispose();
                audioSource = null;
            }
            audioBuffer.dispose();
            audioBuffer = null;
            audioContext.dispose();
            audioContext = null;
            return;
        }
        if (!audioSource.setLooping(looping))
            audioError = audioContext.lastError;
    }

    private function fail(message:String):Bool
    {
        lastError = message;
        return false;
    }

    private function get_isLoaded():Bool return loaded && !disposed;
    private function get_isPlaying():Bool return playing && !disposed;
    private function get_duration():Float return loaded && !disposed ? native.ptr.duration() : 0;
    private function get_currentTime():Float
    {
        return playing ? Math.min(duration, Math.max(0, haxe.Timer.stamp() - clockStart)) : pausedAt;
    }
    private function get_videoWidth():Int return loaded && !disposed ? native.ptr.width() : 0;
    private function get_videoHeight():Int return loaded && !disposed ? native.ptr.height() : 0;
    private function get_error():String return lastError;
    private function get_audioStatus():String return audioError;
}
