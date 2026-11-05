package lemon.input.gamepad;

enum abstract GamepadButton(Int) from Int to Int
{
    var DPadUp = 0x0001;
    var DPadDown = 0x0002;
    var DPadLeft = 0x0004;
    var DPadRight = 0x0008;
    var Start = 0x0010;
    var Back = 0x0020;
    var LeftThumb = 0x0040;
    var RightThumb = 0x0080;
    var LeftShoulder = 0x0100;
    var RightShoulder = 0x0200;
    var A = 0x1000;
    var B = 0x2000;
    var X = 0x4000;
    var Y = 0x8000;
}
