package lemon.platform.windows.input;

import lemon.input.internal.InputBackend;
import lemon.platform.windows.internal.NativePlace;

class WindowsInputBackend implements InputBackend
{
    private var native:cpp.Pointer<NativePlace>;

    public function new(native:cpp.Pointer<NativePlace>)
    {
        this.native = native;
    }

    public function update():Void native.ptr.updateInput();
    public function isKeyDown(keyCode:Int):Bool return native.ptr.isKeyDown(keyCode);
    public function mouseX():Int return native.ptr.mouseX();
    public function mouseY():Int return native.ptr.mouseY();
    public function isMouseButtonDown(button:Int):Bool return native.ptr.isMouseButtonDown(button);
    public function takeMouseWheel():Int return native.ptr.takeMouseWheel();
    public function gamepadConnected(index:Int):Bool return native.ptr.gamepadConnected(index);
    public function gamepadButtons(index:Int):Int return native.ptr.gamepadButtons(index);
    public function gamepadAxisX(index:Int):Float return native.ptr.gamepadAxisX(index);
    public function gamepadAxisY(index:Int):Float return native.ptr.gamepadAxisY(index);
    public function gamepadAxisRX(index:Int):Float return native.ptr.gamepadAxisRX(index);
    public function gamepadAxisRY(index:Int):Float return native.ptr.gamepadAxisRY(index);
    public function gamepadLeftTrigger(index:Int):Float return native.ptr.gamepadLeftTrigger(index);
    public function gamepadRightTrigger(index:Int):Float return native.ptr.gamepadRightTrigger(index);
}
