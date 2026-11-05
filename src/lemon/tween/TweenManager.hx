package lemon.tween;

class TweenManager
{
    private var tweens:Array<Tween> = [];
    private var paused:Bool = false;

    public var activeCount(get, never):Int;

    public function new()
    {
    }

    public function to(target:Dynamic, values:Dynamic, duration:Float, easing:TweenEase = null):Tween
    {
        var tween = new Tween(target, values, duration, easing);
        if (tween.isActive)
            tweens.push(tween);
        return tween;
    }

    public function update(deltaTime:Float):Void
    {
        if (paused || !Math.isFinite(deltaTime) || deltaTime <= 0)
            return;
        var current = tweens.copy();
        for (tween in current)
        {
            if (tweens.indexOf(tween) >= 0 && !tween.update(deltaTime))
                tweens.remove(tween);
        }
    }

    public function pause():Void
    {
        paused = true;
    }

    public function resume():Void
    {
        paused = false;
    }

    public function clear():Void
    {
        for (tween in tweens)
            tween.cancel();
        tweens.resize(0);
    }

    private function get_activeCount():Int
    {
        var count = 0;
        for (tween in tweens)
            if (tween.isActive)
                count++;
        return count;
    }
}
