package lemon.input.internal;

interface InputBackend
{
    public function update():Void;
    public function isKeyDown(keyCode:Int):Bool;
    public function mouseX():Int;
    public function mouseY():Int;
    public function isMouseButtonDown(button:Int):Bool;
    public function takeMouseWheel():Int;
    public function gamepadConnected(index:Int):Bool;
    public function gamepadButtons(index:Int):Int;
    public function gamepadAxisX(index:Int):Float;
    public function gamepadAxisY(index:Int):Float;
    public function gamepadAxisRX(index:Int):Float;
    public function gamepadAxisRY(index:Int):Float;
    public function gamepadLeftTrigger(index:Int):Float;
    public function gamepadRightTrigger(index:Int):Float;
}
