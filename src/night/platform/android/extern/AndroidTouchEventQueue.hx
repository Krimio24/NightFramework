package lemon.platform.android.extern;

@:native("java.util.concurrent.ConcurrentLinkedQueue")
extern class AndroidTouchEventQueue
{
    public function new():Void;
    public function offer(event:AndroidTouchEvent):Bool;
    public function poll():Dynamic;
}
