package lemon.input.mouse;

import lemon.events.Event;
import lemon.events.EventDispatcher;
import lemon.input.internal.InputBackend;

class Mouse
{
    public var events(default, null):EventDispatcher = new EventDispatcher();
    public var x(default, null):Int = 0;
    public var y(default, null):Int = 0;
    public var wheelDelta(default, null):Int = 0;
    private var backend:InputBackend;
    private var previous:Array<Bool> = [false, false, false];

    public function new(backend:InputBackend)
    {
        this.backend = backend;
    }

    public function isDown(button:Int):Bool
    {
        return button >= 0 && button < previous.length && previous[button];
    }

    @:allow(lemon.input.Input)
    private function update(dispatchGlobal:Event->Void):Void
    {
        var nextX = backend.mouseX();
        var nextY = backend.mouseY();
        if (nextX != x || nextY != y)
        {
            var event = new Event("mouse.move", {x: nextX, y: nextY, deltaX: nextX - x, deltaY: nextY - y});
            x = nextX;
            y = nextY;
            events.dispatch(event);
            dispatchGlobal(event);
        }

        for (button in 0...previous.length)
        {
            var down = backend.isMouseButtonDown(button);
            if (down != previous[button])
            {
                var event = new Event(down ? "mouse.buttonDown" : "mouse.buttonUp", {button: button, x: x, y: y});
                previous[button] = down;
                events.dispatch(event);
                dispatchGlobal(event);
            }
        }

        wheelDelta = backend.takeMouseWheel();
        if (wheelDelta != 0)
        {
            var event = new Event("mouse.wheel", {delta: wheelDelta, x: x, y: y});
            events.dispatch(event);
            dispatchGlobal(event);
        }
    }
}
