package lemon.graphics;

import lemon.graphics.atlas.Animation;
import lemon.graphics.atlas.SparrowFrame;
import lemon.graphics.atlas.TextureAtlas;

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
    public var animation(default, null):Animation;
    public var currentFrame(get, never):Null<SparrowFrame>;

    public function new()
    {
        graphics = new Graphics();
    }

    public function playAnimation(atlas:TextureAtlas, animation:Animation, restart:Bool = true):Bool
    {
        if (atlas == null || animation == null || atlas.imagePath == null || atlas.imagePath.length == 0)
            return false;
        if (!graphics.load(atlas.imagePath))
            return false;

        this.animation = animation;
        animation.play(restart);
        var frame = animation.currentFrame;
        if (frame != null)
        {
            width = frame.frameWidth;
            height = frame.frameHeight;
        }
        return true;
    }

    public function update(elapsed:Float):Void
    {
        if (animation == null)
            return;
        animation.update(elapsed);
        var frame = animation.currentFrame;
        if (frame != null)
        {
            if (width <= 0)
                width = frame.frameWidth;
            if (height <= 0)
                height = frame.frameHeight;
        }
    }

    public function stopAnimation():Void
    {
        if (animation != null)
            animation.stop();
    }

    private function get_currentFrame():Null<SparrowFrame>
    {
        return animation == null ? null : animation.currentFrame;
    }
}
