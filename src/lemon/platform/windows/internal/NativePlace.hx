package lemon.platform.windows.internal;

import haxe.io.BytesData;

@:buildXml("
<files id='haxe'>
    <compilerflag value='-I${this_dir}/../../include'/>
</files>
")
@:include("lemon/Place.hpp")
@:native("lemon::native::Place")
extern class NativePlace
{
    @:native("new lemon::native::Place")
    static function allocate(title:String, width:Int, height:Int):cpp.Pointer<NativePlace>;

    function create():Bool;
    function show():Void;
    function hide():Void;
    function setTitle(title:String):Void;
    function setSize(width:Int, height:Int):Void;
    function close():Void;
    function setTaskbarProgress(state:Int, value:Int, maximum:Int):Bool;
    function showNotification(title:String, message:String):Bool;
    function showTrayNotification(title:String, message:String):Bool;
    function hideTrayNotification():Void;

    function beginFrame(red:Int, green:Int, blue:Int, alpha:Int):Bool;
    function endFrame():Bool;

    function drawLine(x1:Float, y1:Float, x2:Float, y2:Float, red:Int, green:Int, blue:Int, alpha:Int, thickness:Float):Void;
    function drawRectangle(x:Float, y:Float, width:Float, height:Float, red:Int, green:Int, blue:Int, alpha:Int, thickness:Float):Void;
    function fillRectangle(x:Float, y:Float, width:Float, height:Float, red:Int, green:Int, blue:Int, alpha:Int):Void;
    function drawCircle(x:Float, y:Float, radius:Float, red:Int, green:Int, blue:Int, alpha:Int, thickness:Float):Void;
    function fillCircle(x:Float, y:Float, radius:Float, red:Int, green:Int, blue:Int, alpha:Int):Void;
    function fillTriangle(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, red:Int, green:Int, blue:Int, alpha:Int):Void;

    function loadTexture(path:String):Int;
    function loadTextureBytes(bytes:BytesData, length:Int):Int;
    function loadTexturePixels(bytes:BytesData, length:Int, width:Int, height:Int):Int;
    function updateTexturePixels(texture:Int, bytes:BytesData, length:Int, width:Int, height:Int):Bool;
    function drawTexture(texture:Int, x:Float, y:Float, width:Float, height:Float, alpha:Float):Bool;
    function unloadTexture(texture:Int):Void;
    function textureWidth(texture:Int):Float;
    function textureHeight(texture:Int):Float;

    function loadFont(path:String, family:String):Int;
    function unloadFont(font:Int):Void;
    function drawText(text:String, x:Float, y:Float, width:Float, height:Float, size:Float,
        red:Int, green:Int, blue:Int, alpha:Int, font:Int, weight:Int, style:Int, stretch:Int,
        textAlignment:Int, paragraphAlignment:Int):Bool;

    function setTransform(scaleX:Float, scaleY:Float, rotation:Float, x:Float, y:Float):Void;
    function resetTransform():Void;

    function updateInput():Void;
    function isKeyDown(keyCode:Int):Bool;
    function mouseX():Int;
    function mouseY():Int;
    function isMouseButtonDown(button:Int):Bool;
    function takeMouseWheel():Int;
    function gamepadConnected(index:Int):Bool;
    function gamepadButtons(index:Int):Int;
    function gamepadAxisX(index:Int):Float;
    function gamepadAxisY(index:Int):Float;
    function gamepadAxisRX(index:Int):Float;
    function gamepadAxisRY(index:Int):Float;
    function gamepadLeftTrigger(index:Int):Float;
    function gamepadRightTrigger(index:Int):Float;

    function isOpen():Bool;
    function isVisible():Bool;
    function width():Int;
    function height():Int;
    function title():String;

    @:native("lemon::native::Place::pollEvents")
    static function pollEvents():Bool;
}
