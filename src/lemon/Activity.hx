package lemon;

import lemon.graphics.GraphicsContext;
import lemon.input.touch.Touch;

class Activity
{
    /** Touch input received by this activity. Subscribe to touch.events for pointer events. */
    public var touch(default, null):Touch = new Touch();

    /** Creates an activity. Override lifecycle methods to implement your scene. */
    public function new()
    {
    }

    /** Called once when the activity's rendering surface is ready. */
    public function create():Void
    {
    }

    /** Updates scene logic once per frame. Elapsed time is measured in seconds. */
    public function update(elapsed:Float):Void
    {
    }

    /** Draws the scene using the platform-independent graphics interface. */
    public function draw(graphics:GraphicsContext):Void
    {
    }

    /** Called when the application is paused or sent to the background. */
    public function pause():Void
    {
    }

    /** Called when the application returns to the foreground. */
    public function resume():Void
    {
    }

    /** Called before the activity and its resources are destroyed. */
    public function destroy():Void
    {
    }
}
