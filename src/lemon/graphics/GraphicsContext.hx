package lemon.graphics;

interface GraphicsContext
{
    /** Current drawing surface width in pixels. */
    public var width(default, null):Int;
    /** Current drawing surface height in pixels. */
    public var height(default, null):Int;

    /** Clears the surface. Color channels are integers from 0 to 255. */
    public function clear(red:Int = 0, green:Int = 0, blue:Int = 0, alpha:Int = 255):Void;

    /** Draws a filled rectangle in surface pixel coordinates. */
    public function fillRect(x:Float, y:Float, width:Float, height:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255):Void;

    /** Draws a rectangle outline in surface pixel coordinates. */
    public function drawRect(x:Float, y:Float, width:Float, height:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255):Void;

    /** Draws a filled triangle using its three vertices. */
    public function fillTriangle(x1:Float, y1:Float, x2:Float, y2:Float,
        x3:Float, y3:Float, red:Int, green:Int, blue:Int, alpha:Int = 255):Void;

    /** Draws a filled circle. Increase segments for a smoother edge. */
    public function fillCircle(x:Float, y:Float, radius:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255, segments:Int = 32):Void;

    /** Draws a circle outline. Increase segments for a smoother edge. */
    public function drawCircle(x:Float, y:Float, radius:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255, segments:Int = 32):Void;

    /** Draws a filled oval inside the given rectangle. */
    public function fillOval(x:Float, y:Float, width:Float, height:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255, segments:Int = 32):Void;

    /** Draws a line between two surface pixel coordinates. */
    public function drawLine(x1:Float, y1:Float, x2:Float, y2:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255):Void;
}
