package lemon.input;

import lemon.events.Event;
import lemon.events.EventDispatcher;
import lemon.input.gamepad.Gamepad;
import lemon.input.internal.InputBackend;
import lemon.input.keyboard.Keyboard;
import lemon.input.mouse.Mouse;

class Input
{
    public var events(default, null):EventDispatcher = new EventDispatcher();
    public var keyboard(default, null):Keyboard;
    public var mouse(default, null):Mouse;
    public var gamepads(default, null):Array<Gamepad>;
    public var isUpdating(default, null):Bool = false;
    private var backend:InputBackend;

    public function new(backend:InputBackend, gamepadCount:Int = 4)
    {
        this.backend = backend;
        keyboard = new Keyboard(backend);
        mouse = new Mouse(backend);
        gamepads = [];
        for (index in 0...gamepadCount)
            gamepads.push(new Gamepad(index, backend));
    }

    @:allow(lemon.Place)
    private function update():Void
    {
        backend.update();
        isUpdating = true;
        try
        {
            keyboard.update(dispatch);
            mouse.update(dispatch);
            for (gamepad in gamepads)
                gamepad.update(dispatch);
        }
        catch (error:Dynamic)
        {
            isUpdating = false;
            throw error;
        }
        isUpdating = false;
    }

    private function dispatch(event:Event):Void
    {
        events.dispatch(event);
    }
}
