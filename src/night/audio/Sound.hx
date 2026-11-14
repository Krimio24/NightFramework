package lemon.audio;

import lemon.audio.openal.OpenALBuffer;
import lemon.audio.openal.OpenALContext;
import lemon.audio.openal.OpenALSource;
import lemon.audio.openal.OpenALConstants;

class Sound
{
    private var context:OpenALContext;
    private var buffer:OpenALBuffer;
    private var source:OpenALSource;
    private var disposed:Bool = false;
    private var lastError:String = "";
    private var currentVolume:Float = 1;
    private var currentPitch:Float = 1;
    private var shouldLoop:Bool = false;
    private var sourceX:Float = 0;
    private var sourceY:Float = 0;
    private var sourceZ:Float = 0;

    public var volume(get, set):Float;
    public var pitch(get, set):Float;
    public var looping(get, set):Bool;
    public var isLoaded(get, never):Bool;
    public var isPlaying(get, never):Bool;
    public var isPaused(get, never):Bool;
    public var error(get, never):String;

    public function new(path:String = null)
    {
        if (path != null && path.length > 0)
            load(path);
    }

    public static function fromFile(path:String):Sound
    {
        return new Sound(path);
    }

    public function load(path:String):Bool
    {
        if (disposed)
            return fail("Sound has been disposed.");
        if (path == null || path.length == 0)
            return fail("A non-empty sound path is required.");

        unload();
        if (context == null)
        {
            context = new OpenALContext();
            if (!context.open())
            {
                var openError = context.lastError;
                context.dispose();
                context = null;
                return fail(openError);
            }
        }

        buffer = context.createBuffer(path);
        if (buffer == null)
            return fail(context.lastError);
        source = context.createSource();
        if (source == null || !source.bind(buffer))
        {
            var sourceError = context.lastError;
            unload();
            return fail(sourceError);
        }
        if (!applyProperties())
        {
            var propertyError = context.lastError;
            unload();
            return fail(propertyError);
        }
        lastError = "";
        return true;
    }

    public function play():Bool
    {
        if (!isLoaded)
            return fail("Load a sound before playback.");
        if (source.state() != OpenALConstants.PAUSED && !source.rewind())
            return fail(context.lastError);
        if (!source.play())
            return fail(context.lastError);
        lastError = "";
        return true;
    }

    public function pause():Bool
    {
        if (!isLoaded)
            return fail("Load a sound before pausing playback.");
        if (!source.pause())
            return fail(context.lastError);
        lastError = "";
        return true;
    }

    public function stop():Bool
    {
        if (!isLoaded)
            return fail("Load a sound before stopping playback.");
        if (!source.stop() || !source.rewind())
            return fail(context.lastError);
        lastError = "";
        return true;
    }

    public function setPosition(x:Float, y:Float, z:Float):Bool
    {
        if (!Math.isFinite(x) || !Math.isFinite(y) || !Math.isFinite(z))
            return fail("Sound position values must be finite.");
        sourceX = x;
        sourceY = y;
        sourceZ = z;
        if (!isLoaded)
        {
            lastError = "";
            return true;
        }
        if (!source.setPosition(x, y, z))
            return fail(context.lastError);
        lastError = "";
        lastError = "";
        return true;
    }

    public function unload():Void
    {
        if (source != null)
        {
            source.dispose();
            source = null;
        }
        if (buffer != null)
        {
            buffer.dispose();
            buffer = null;
        }
    }

    public function dispose():Void
    {
        if (disposed)
            return;
        unload();
        if (context != null)
        {
            context.dispose();
            context = null;
        }
        disposed = true;
    }

    private function applyProperties():Bool
    {
        return source.setGain(currentVolume) &&
            source.setPitch(currentPitch) &&
            source.setLooping(shouldLoop) &&
            source.setPosition(sourceX, sourceY, sourceZ);
    }

    private function fail(message:String):Bool
    {
        lastError = message == null || message.length == 0 ? "OpenAL sound operation failed." : message;
        return false;
    }

    private function get_volume():Float return currentVolume;
    private function set_volume(value:Float):Float
    {
        if (!Math.isFinite(value) || value < 0)
        {
            fail("Sound volume must be a finite non-negative number.");
            return currentVolume;
        }
        currentVolume = value;
        if (isLoaded)
        {
            if (!source.setGain(currentVolume))
                fail(context.lastError);
            else
                lastError = "";
        }
        return currentVolume;
    }

    private function get_pitch():Float return currentPitch;
    private function set_pitch(value:Float):Float
    {
        if (!Math.isFinite(value) || value <= 0)
        {
            fail("Sound pitch must be a finite positive number.");
            return currentPitch;
        }
        currentPitch = value;
        if (isLoaded)
        {
            if (!source.setPitch(currentPitch))
                fail(context.lastError);
            else
                lastError = "";
        }
        return currentPitch;
    }

    private function get_looping():Bool return shouldLoop;
    private function set_looping(value:Bool):Bool
    {
        shouldLoop = value;
        if (isLoaded)
        {
            if (!source.setLooping(value))
                fail(context.lastError);
            else
                lastError = "";
        }
        return value;
    }

    private function get_isLoaded():Bool
    {
        return !disposed && source != null && buffer != null && context != null && context.isOpen();
    }

    private function get_isPlaying():Bool
    {
        return isLoaded && source.state() == OpenALConstants.PLAYING;
    }

    private function get_isPaused():Bool
    {
        return isLoaded && source.state() == OpenALConstants.PAUSED;
    }

    private function get_error():String return lastError;
}
