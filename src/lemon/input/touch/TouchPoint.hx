package lemon.input.touch;

class TouchPoint
{
    /** Platform-provided pointer identifier. */
    public var id(default, null):Int;
    /** Horizontal position in drawing-surface pixels. */
    public var x(default, null):Float;
    /** Vertical position in drawing-surface pixels. */
    public var y(default, null):Float;
    /** Pointer pressure reported by the platform, when available. */
    public var pressure(default, null):Float;

    public function new(id:Int, x:Float, y:Float, pressure:Float)
    {
        this.id = id;
        this.x = x;
        this.y = y;
        this.pressure = pressure;
    }

    @:allow(lemon.input.touch.Touch)
    private function update(x:Float, y:Float, pressure:Float):Void
    {
        this.x = x;
        this.y = y;
        this.pressure = pressure;
    }
}
