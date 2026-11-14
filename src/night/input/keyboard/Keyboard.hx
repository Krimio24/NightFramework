package lemon.input.keyboard;

import lemon.events.Event;
import lemon.events.EventDispatcher;
import lemon.input.internal.InputBackend;

class Keyboard
{
    public var events(default, null):EventDispatcher = new EventDispatcher();
    private var backend:InputBackend;
    private var previous:Array<Bool> = [];

    public function new(backend:InputBackend)
    {
        this.backend = backend;
        previous.resize(256);
        for (keyCode in 0...256)
            previous[keyCode] = false;
    }

    public function isDown(keyCode:Int):Bool
    {
        return keyCode >= 0 && keyCode < 256 && previous[keyCode];
    }

    @:allow(lemon.input.Input)
    private function update(dispatchGlobal:Event->Void):Void
    {
        for (keyCode in 0...256)
        {
            var down = backend.isKeyDown(keyCode);
            if (down != previous[keyCode])
            {
                var type = down ? "keyboard.keyDown" : "keyboard.keyUp";
                var event = new Event(type, {keyCode: keyCode});
                previous[keyCode] = down;
                events.dispatch(event);
                dispatchGlobal(event);
            }
        }
    }
}
