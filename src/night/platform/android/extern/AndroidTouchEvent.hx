package lemon.platform.android.extern;

class AndroidTouchEvent
{
    public var action:Int;
    public var id:Int;
    public var x:Float;
    public var y:Float;
    public var pressure:Float;

    public function new(action:Int, id:Int, x:Float, y:Float, pressure:Float)
    {
        this.action = action;
        this.id = id;
        this.x = x;
        this.y = y;
        this.pressure = pressure;
    }
}
