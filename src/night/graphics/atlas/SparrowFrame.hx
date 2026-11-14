package lemon.graphics.atlas;

class SparrowFrame
{
    public final name:String;
    public final x:Int;
    public final y:Int;
    public final width:Int;
    public final height:Int;
    public final frameX:Int;
    public final frameY:Int;
    public final frameWidth:Int;
    public final frameHeight:Int;

    public function new(name:String, x:Int, y:Int, width:Int, height:Int,
        frameX:Int = 0, frameY:Int = 0, frameWidth:Int = 0, frameHeight:Int = 0)
    {
        this.name = name;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.frameX = frameX;
        this.frameY = frameY;
        this.frameWidth = frameWidth > 0 ? frameWidth : width;
        this.frameHeight = frameHeight > 0 ? frameHeight : height;
    }
}
