package lemon.graphics.internal;

import haxe.io.BytesData;

@:buildXml("
<files id='haxe'>
    <compilerflag value='-I${this_dir}/../../../include'/>
</files>
")
@:include("lemon/Video.hpp")
@:native("lemon::native::Video")
extern class NativeVideo
{
    @:native("new lemon::native::Video")
    static function allocate():cpp.Pointer<NativeVideo>;

    function open(path:String):Bool;
    function close():Void;
    function readFrame():Bool;
    function seek(seconds:Float):Bool;
    function width():Int;
    function height():Int;
    function duration():Float;
    function frameTime():Float;
    function copyFrame(bytes:BytesData, length:Int):Bool;
}
