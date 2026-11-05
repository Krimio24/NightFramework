package lemon.input.gamepad;

import lemon.events.Event;
import lemon.events.EventDispatcher;
import lemon.input.internal.InputBackend;

class Gamepad
{
    public var events(default, null):EventDispatcher = new EventDispatcher();
    public var index(default, null):Int;
    public var connected(default, null):Bool = false;
    public var leftX(default, null):Float = 0;
    public var leftY(default, null):Float = 0;
    public var rightX(default, null):Float = 0;
    public var rightY(default, null):Float = 0;
    public var leftTrigger(default, null):Float = 0;
    public var rightTrigger(default, null):Float = 0;
    private var backend:InputBackend;
    private var previousButtons:Int = 0;

    public function new(index:Int, backend:InputBackend)
    {
        this.index = index;
        this.backend = backend;
    }

    public function isButtonDown(buttonMask:Int):Bool
    {
        return (previousButtons & buttonMask) != 0;
    }

    @:allow(lemon.input.Input)
    private function update(dispatchGlobal:Event->Void):Void
    {
        var isConnected = backend.gamepadConnected(index);
        if (isConnected != connected)
        {
            connected = isConnected;
            var connectionEvent = new Event(isConnected ? "gamepad.connected" : "gamepad.disconnected", {index: index});
            events.dispatch(connectionEvent);
            dispatchGlobal(connectionEvent);
            if (!isConnected)
            {
                dispatchButtonReleases(dispatchGlobal);
                setAxes(0, 0, 0, 0, 0, 0, dispatchGlobal);
                return;
            }
        }

        var buttons = backend.gamepadButtons(index);
        var changed = buttons ^ previousButtons;
        for (bit in 0...16)
        {
            var mask = 1 << bit;
            if ((changed & mask) != 0)
            {
                var event = new Event((buttons & mask) != 0 ? "gamepad.buttonDown" : "gamepad.buttonUp",
                    {index: index, button: mask});
                events.dispatch(event);
                dispatchGlobal(event);
            }
        }
        previousButtons = buttons;

        setAxes(
            backend.gamepadAxisX(index),
            backend.gamepadAxisY(index),
            backend.gamepadAxisRX(index),
            backend.gamepadAxisRY(index),
            backend.gamepadLeftTrigger(index),
            backend.gamepadRightTrigger(index),
            dispatchGlobal
        );
    }

    private function dispatchButtonReleases(dispatchGlobal:Event->Void):Void
    {
        for (bit in 0...16)
        {
            var mask = 1 << bit;
            if ((previousButtons & mask) != 0)
            {
                var event = new Event("gamepad.buttonUp", {index: index, button: mask});
                events.dispatch(event);
                dispatchGlobal(event);
            }
        }
        previousButtons = 0;
    }

    private function setAxes(x:Float, y:Float, rx:Float, ry:Float, lt:Float, rt:Float, dispatchGlobal:Event->Void):Void
    {
        if (x != leftX || y != leftY || rx != rightX || ry != rightY || lt != leftTrigger || rt != rightTrigger)
        {
            leftX = x;
            leftY = y;
            rightX = rx;
            rightY = ry;
            leftTrigger = lt;
            rightTrigger = rt;
            var event = new Event("gamepad.axis", {
                index: index, leftX: x, leftY: y, rightX: rx, rightY: ry,
                leftTrigger: lt, rightTrigger: rt
            });
            events.dispatch(event);
            dispatchGlobal(event);
        }
    }
}
