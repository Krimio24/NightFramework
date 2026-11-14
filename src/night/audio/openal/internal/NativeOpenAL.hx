package lemon.audio.openal.internal;

import haxe.io.BytesData;

@:buildXml("
<files id='haxe'>
    <compilerflag value='-I${this_dir}/../../include'/>
</files>
")
@:include("lemon/OpenAL.hpp")
@:native("lemon::native::OpenAL")
extern class NativeOpenAL
{
    @:native("new lemon::native::OpenAL")
    static function allocate():cpp.Pointer<NativeOpenAL>;

    function open(deviceName:String):Bool;
    function close():Void;
    function isOpen():Bool;
    function lastError():String;
    function deviceCount():Int;
    function deviceName(index:Int):String;

    function loadBuffer(path:String):Int;
    function loadBufferFromPCM(bytes:BytesData, length:Int, channels:Int, bitsPerSample:Int, sampleRate:Int):Int;
    function deleteBuffer(buffer:Int):Void;
    function createSource():Int;
    function deleteSource(source:Int):Void;
    function bindBuffer(source:Int, buffer:Int):Bool;
    function sourcePlay(source:Int):Bool;
    function sourcePause(source:Int):Bool;
    function sourceStop(source:Int):Bool;
    function sourceRewind(source:Int):Bool;
    function sourceState(source:Int):Int;
    function setSourcef(source:Int, parameter:Int, value:Single):Bool;
    function setSource3f(source:Int, parameter:Int, x:Single, y:Single, z:Single):Bool;
    function setSourcei(source:Int, parameter:Int, value:Int):Bool;
    function queueBuffer(source:Int, buffer:Int):Bool;
    function unqueueProcessed(source:Int):Int;

    function setListener3f(parameter:Int, x:Single, y:Single, z:Single):Bool;
    function setListenerf(parameter:Int, value:Single):Bool;
    function setListenerOrientation(atX:Single, atY:Single, atZ:Single, upX:Single, upY:Single, upZ:Single):Bool;

    function efxSupported():Bool;
    function createEffect(type:Int):Int;
    function setEffectf(effect:Int, parameter:Int, value:Single):Bool;
    function setEffecti(effect:Int, parameter:Int, value:Int):Bool;
    function deleteEffect(effect:Int):Void;
    function createEffectSlot():Int;
    function setEffectSlot(slot:Int, effect:Int):Bool;
    function deleteEffectSlot(slot:Int):Void;
    function attachEffectSlot(source:Int, slot:Int, send:Int):Bool;
    function createFilter(type:Int):Int;
    function setFilterf(filter:Int, parameter:Int, value:Single):Bool;
    function setFilteri(filter:Int, parameter:Int, value:Int):Bool;
    function deleteFilter(filter:Int):Void;
    function setSourceFilter(source:Int, filter:Int):Bool;
}
