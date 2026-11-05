package lemon.audio.openal;

import lemon.audio.openal.internal.NativeOpenAL;
import haxe.io.Bytes;

class OpenALContext
{
    private var native:cpp.Pointer<NativeOpenAL>;
    private var disposed:Bool = false;
    public var listener(default, null):OpenALListener;
    public var lastError(get, never):String;

    public function new()
    {
        native = NativeOpenAL.allocate();
        listener = new OpenALListener(this);
    }

    public function open(deviceName:String = null):Bool
    {
        return !disposed && native.ptr.open(deviceName);
    }

    public function close():Void
    {
        if (!disposed)
            native.ptr.close();
    }

    public function isOpen():Bool
    {
        return !disposed && native.ptr.isOpen();
    }

    public function getDevices():Array<String>
    {
        var result:Array<String> = [];
        if (disposed)
            return result;
        var count = native.ptr.deviceCount();
        for (index in 0...count)
            result.push(native.ptr.deviceName(index));
        return result;
    }

    public function createBuffer(path:String):OpenALBuffer
    {
        if (disposed || !isOpen())
            return null;
        var id = native.ptr.loadBuffer(path);
        return id > 0 ? new OpenALBuffer(this, id) : null;
    }

    public function createBufferFromPCM(bytes:Bytes, channels:Int, bitsPerSample:Int, sampleRate:Int):OpenALBuffer
    {
        if (disposed || !isOpen() || bytes == null || bytes.length == 0)
            return null;
        var id = native.ptr.loadBufferFromPCM(bytes.getData(), bytes.length, channels, bitsPerSample, sampleRate);
        return id > 0 ? new OpenALBuffer(this, id) : null;
    }

    public function createSource():OpenALSource
    {
        if (disposed || !isOpen())
            return null;
        var id = native.ptr.createSource();
        return id > 0 ? new OpenALSource(this, id) : null;
    }

    public function supportsEFX():Bool
    {
        return !disposed && native.ptr.efxSupported();
    }

    public function createEffect(type:Int):OpenALEffect
    {
        if (!supportsEFX())
            return null;
        var id = native.ptr.createEffect(type);
        return id > 0 ? new OpenALEffect(this, id) : null;
    }

    public function createEffectSlot():OpenALEffectSlot
    {
        if (!supportsEFX())
            return null;
        var id = native.ptr.createEffectSlot();
        return id > 0 ? new OpenALEffectSlot(this, id) : null;
    }

    public function createFilter(type:Int):OpenALFilter
    {
        if (!supportsEFX())
            return null;
        var id = native.ptr.createFilter(type);
        return id > 0 ? new OpenALFilter(this, id) : null;
    }

    public function dispose():Void
    {
        if (disposed)
            return;
        native.ptr.close();
        native.destroy();
        disposed = true;
    }

    private function get_lastError():String
    {
        return disposed ? "OpenAL context is disposed." : native.ptr.lastError();
    }

    @:allow(lemon.audio.openal.OpenALBuffer)
    @:allow(lemon.audio.openal.OpenALSource)
    @:allow(lemon.audio.openal.OpenALListener)
    @:allow(lemon.audio.openal.OpenALEffect)
    @:allow(lemon.audio.openal.OpenALEffectSlot)
    @:allow(lemon.audio.openal.OpenALFilter)
    private function _native():cpp.Pointer<NativeOpenAL>
    {
        return native;
    }

    @:allow(lemon.audio.openal.OpenALBuffer)
    @:allow(lemon.audio.openal.OpenALSource)
    @:allow(lemon.audio.openal.OpenALEffect)
    @:allow(lemon.audio.openal.OpenALEffectSlot)
    @:allow(lemon.audio.openal.OpenALFilter)
    private function _isDisposed():Bool
    {
        return disposed;
    }
}
