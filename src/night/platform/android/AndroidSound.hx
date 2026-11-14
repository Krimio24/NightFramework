package lemon.platform.android;

import lemon.platform.android.extern.AndroidAssetFileDescriptor;
import lemon.platform.android.extern.AndroidContext;
import lemon.platform.android.extern.AndroidMediaPlayer;

class AndroidSound
{
    private var context:AndroidContext;
    private var player:AndroidMediaPlayer;
    private var lastError:String = "";
    private var currentVolume:Float = 1;
    private var shouldLoop:Bool = false;
    private var resumeAfterPause:Bool = false;

    public var volume(get, set):Float;
    public var looping(get, set):Bool;
    public var isLoaded(get, never):Bool;
    public var isPlaying(get, never):Bool;
    public var error(get, never):String;

    /** Creates an Android sound player using the activity's context. */
    public function new(context:AndroidContext)
    {
        this.context = context;
    }

    /** Loads an audio file packaged in the app's assets directory. */
    public function load(assetPath:String):Bool
    {
        unload();
        if (context == null)
            return fail("An Android context is required to load a sound.");
        if (assetPath == null || assetPath.length == 0)
            return fail("A non-empty Android asset path is required.");

        var descriptor:AndroidAssetFileDescriptor = null;
        try
        {
            descriptor = context.getAssets().openFd(assetPath);
            player = new AndroidMediaPlayer();
            player.setDataSource(descriptor.getFileDescriptor(), descriptor.getStartOffset(), descriptor.getLength());
            descriptor.close();
            descriptor = null;
            player.prepare();
            player.setVolume(cast currentVolume, cast currentVolume);
            player.setLooping(shouldLoop);
            lastError = "";
            return true;
        }
        catch (error:Dynamic)
        {
            if (descriptor != null)
            {
                try
                {
                    descriptor.close();
                }
                catch (closeError:Dynamic)
                {
                    trace('Could not close the Android audio asset: $closeError');
                }
            }
            unload();
            return fail(Std.string(error));
        }
    }

    /** Starts playback from the beginning. */
    public function play():Bool
    {
        if (!isLoaded)
            return fail("Load a sound before playback.");
        try
        {
            if (player.isPlaying())
                player.seekTo(0);
            player.start();
            resumeAfterPause = false;
            lastError = "";
            return true;
        }
        catch (error:Dynamic)
        {
            return fail(Std.string(error));
        }
    }

    /** Pauses playback and remembers whether it should resume later. */
    public function pause():Bool
    {
        if (!isLoaded)
            return fail("Load a sound before pausing playback.");
        try
        {
            resumeAfterPause = player.isPlaying();
            if (resumeAfterPause)
                player.pause();
            lastError = "";
            return true;
        }
        catch (error:Dynamic)
        {
            return fail(Std.string(error));
        }
    }

    /** Resumes playback only if pause() interrupted an active sound. */
    public function resume():Bool
    {
        if (!isLoaded)
            return fail("Load a sound before resuming playback.");
        if (!resumeAfterPause)
            return true;
        try
        {
            player.start();
            resumeAfterPause = false;
            lastError = "";
            return true;
        }
        catch (error:Dynamic)
        {
            return fail(Std.string(error));
        }
    }

    /** Releases the native player and unloads the current asset. */
    public function unload():Void
    {
        resumeAfterPause = false;
        if (player != null)
        {
            player.release();
            player = null;
        }
    }

    /** Releases this sound and its Android context reference. */
    public function dispose():Void
    {
        unload();
        context = null;
    }

    private function fail(message:String):Bool
    {
        lastError = message == null || message.length == 0 ? "Android audio playback failed." : message;
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
        if (player != null)
        {
            try
            {
                player.setVolume(cast value, cast value);
                lastError = "";
            }
            catch (error:Dynamic)
            {
                fail(Std.string(error));
            }
        }
        return currentVolume;
    }

    private function get_looping():Bool return shouldLoop;
    private function set_looping(value:Bool):Bool
    {
        shouldLoop = value;
        if (player != null)
        {
            try
            {
                player.setLooping(value);
                lastError = "";
            }
            catch (error:Dynamic)
            {
                fail(Std.string(error));
            }
        }
        return value;
    }

    private function get_isLoaded():Bool return player != null;
    private function get_isPlaying():Bool return player != null && player.isPlaying();
    private function get_error():String return lastError;
}
