package lemon.input.touch;

import lemon.events.Event;
import lemon.events.EventDispatcher;

class Touch
{
    /** Events emitted for pointer changes: touch.down, touch.move, touch.up, and touch.cancel. */
    public var events(default, null):EventDispatcher = new EventDispatcher();
    /** Pointers currently held on the surface. */
    public var activeTouches(default, null):Array<TouchPoint> = [];

    public function new()
    {
    }

    /** Returns the active pointer with this platform-provided ID, or null if it is not active. */
    public function getTouch(id:Int):TouchPoint
    {
        for (point in activeTouches)
            if (point.id == id)
                return point;
        return null;
    }

    @:allow(lemon.platform.android.AndroidHostActivity)
    private function down(id:Int, x:Float, y:Float, pressure:Float):Void
    {
        var point = getTouch(id);
        if (point != null)
            point.update(x, y, pressure);
        else
        {
            point = new TouchPoint(id, x, y, pressure);
            activeTouches.push(point);
        }
        events.dispatch(new Event("touch.down", point));
    }

    @:allow(lemon.platform.android.AndroidHostActivity)
    private function move(id:Int, x:Float, y:Float, pressure:Float):Void
    {
        var point = getTouch(id);
        if (point == null)
            return;
        point.update(x, y, pressure);
        events.dispatch(new Event("touch.move", point));
    }

    @:allow(lemon.platform.android.AndroidHostActivity)
    private function up(id:Int, x:Float, y:Float, pressure:Float):Void
    {
        var point = getTouch(id);
        if (point == null)
            return;
        point.update(x, y, pressure);
        events.dispatch(new Event("touch.up", point));
        activeTouches.remove(point);
    }

    @:allow(lemon.platform.android.AndroidHostActivity)
    private function cancelAll():Void
    {
        for (point in activeTouches.copy())
            events.dispatch(new Event("touch.cancel", point));
        activeTouches.resize(0);
    }
}
