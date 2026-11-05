package lemon.graphics;

class Sprite
{
    public var x:Float = 0;
    public var y:Float = 0;
    public var width:Float = 0;
    public var height:Float = 0;
    public var scaleX:Float = 1;
    public var scaleY:Float = 1;
    public var rotation:Float = 0;
    public var alpha:Float = 1;
    public var visible:Bool = true;
    public var graphics(default, null):Graphics;

    public function new()
    {
        graphics = new Graphics();
    }
}
