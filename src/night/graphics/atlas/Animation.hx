package lemon.graphics.atlas;

class Animation
{
    public var name(default, null):String;
    public var frames(default, null):Array<SparrowFrame>;
    public var frameRate:Float;
    public var loop:Bool;
    public var currentIndex(default, null):Int;
    public var currentFrame(get, never):Null<SparrowFrame>;
    public var playing(default, null):Bool;
    public var finished(default, null):Bool;

    private var accumulator:Float;

    public function new(name:String, frames:Array<SparrowFrame>, frameRate:Float = 24, loop:Bool = true)
    {
        if (frames == null || frames.length == 0)
            throw "Animation requires at least one frame";
        if (frameRate <= 0)
            throw "Animation frame rate must be greater than zero";

        this.name = name;
        this.frames = frames.copy();
        this.frameRate = frameRate;
        this.loop = loop;
        currentIndex = 0;
        accumulator = 0;
        playing = false;
        finished = false;
    }

    public static function fromPrefix(atlas:TextureAtlas, prefix:String,
        frameRate:Float = 24, loop:Bool = true):Animation
    {
        if (atlas == null)
            throw "TextureAtlas cannot be null";
        var selected = atlas.getPrefix(prefix);
        if (selected.length == 0)
            throw 'No Sparrow frames found for prefix "$prefix"';
        return new Animation(prefix, selected, frameRate, loop);
    }

    public function play(restart:Bool = false):Void
    {
        if (restart || finished)
        {
            currentIndex = 0;
            accumulator = 0;
            finished = false;
        }
        playing = true;
    }

    public function pause():Void
    {
        playing = false;
    }

    public function stop():Void
    {
        playing = false;
        finished = false;
        currentIndex = 0;
        accumulator = 0;
    }

    public function update(elapsed:Float):Void
    {
        if (!playing || elapsed <= 0 || finished)
            return;

        accumulator += elapsed;
        var frameDuration = 1.0 / frameRate;
        while (accumulator >= frameDuration && playing)
        {
            accumulator -= frameDuration;
            if (currentIndex + 1 < frames.length)
                currentIndex++;
            else if (loop)
                currentIndex = 0;
            else
            {
                currentIndex = frames.length - 1;
                playing = false;
                finished = true;
            }
        }
    }

    private function get_currentFrame():Null<SparrowFrame>
    {
        return frames[currentIndex];
    }
}
