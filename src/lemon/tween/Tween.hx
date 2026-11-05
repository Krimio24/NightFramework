package lemon.tween;

class Tween
{
    private var target:Dynamic;
    private var properties:Array<String> = [];
    private var starts:Array<Float> = [];
    private var ends:Array<Float> = [];
    private var duration:Float;
    private var easing:TweenEase;
    private var delayRemaining:Float = 0;
    private var elapsed:Float = 0;
    private var repeatsRemaining:Int = 0;
    private var yoyoEnabled:Bool = false;
    private var reversed:Bool = false;
    private var paused:Bool = false;
    private var active:Bool = false;
    private var failure:String = "";
    private var completionCallback:Void->Void;

    @:allow(lemon.tween.TweenManager)
    private function new(target:Dynamic, values:Dynamic, duration:Float, easing:TweenEase)
    {
        this.target = target;
        this.duration = duration;
        this.easing = easing == null ? Ease.linear : easing;

        if (target == null || values == null || !Math.isFinite(duration) || duration < 0)
        {
            failure = "A tween requires a target, numeric properties, and a finite non-negative duration.";
            return;
        }

        for (property in Reflect.fields(values))
        {
            var start:Dynamic = Reflect.field(target, property);
            var end:Dynamic = Reflect.field(values, property);
            if ((!Std.isOfType(start, Int) && !Std.isOfType(start, Float)) ||
                (!Std.isOfType(end, Int) && !Std.isOfType(end, Float)))
            {
                failure = 'Tween property "$property" must have numeric start and end values.';
                properties.resize(0);
                starts.resize(0);
                ends.resize(0);
                return;
            }
            properties.push(property);
            starts.push(start);
            ends.push(end);
        }

        if (properties.length == 0)
        {
            failure = "A tween must contain at least one numeric property.";
            return;
        }
        active = true;
    }

    public var isActive(get, never):Bool;
    public var isPaused(get, never):Bool;
    public var error(get, never):String;

    public function setDelay(seconds:Float):Tween
    {
        if (!Math.isFinite(seconds) || seconds < 0)
        {
            failure = "Tween delay must be a finite non-negative number.";
            active = false;
        }
        else
            delayRemaining = seconds;
        return this;
    }

    public function repeat(count:Int = -1, yoyo:Bool = false):Tween
    {
        if (count < -1)
        {
            failure = "Tween repeat count must be -1 (infinite) or non-negative.";
            active = false;
        }
        else
        {
            repeatsRemaining = count;
            yoyoEnabled = yoyo;
        }
        return this;
    }

    public function onComplete(callback:Void->Void):Tween
    {
        completionCallback = callback;
        return this;
    }

    public function pause():Tween
    {
        if (active)
            paused = true;
        return this;
    }

    public function resume():Tween
    {
        paused = false;
        return this;
    }

    public function cancel():Void
    {
        active = false;
    }

    @:allow(lemon.tween.TweenManager)
    private function update(deltaTime:Float):Bool
    {
        if (!active || paused)
            return active;

        if (delayRemaining > 0)
        {
            if (deltaTime < delayRemaining)
            {
                delayRemaining -= deltaTime;
                return true;
            }
            deltaTime -= delayRemaining;
            delayRemaining = 0;
        }

        if (duration == 0)
        {
            apply(1);
            if (!startNextCycle())
                finish();
            return active;
        }

        elapsed += deltaTime;
        var cycles = 0;
        while (active && elapsed >= duration && cycles < 100)
        {
            elapsed -= duration;
            apply(1);
            if (!startNextCycle())
            {
                finish();
                return false;
            }
            cycles++;
        }

        if (active)
            apply(easing(Math.max(0, Math.min(1, elapsed / duration))));
        return active;
    }

    private function startNextCycle():Bool
    {
        if (repeatsRemaining == 0)
            return false;
        if (repeatsRemaining > 0)
            repeatsRemaining--;
        if (yoyoEnabled)
            reversed = !reversed;
        else
            apply(0);
        return true;
    }

    private function apply(progress:Float):Void
    {
        for (index in 0...properties.length)
        {
            var start = reversed ? ends[index] : starts[index];
            var end = reversed ? starts[index] : ends[index];
            Reflect.setField(target, properties[index], start + (end - start) * progress);
        }
    }

    private function finish():Void
    {
        active = false;
        if (completionCallback != null)
            completionCallback();
    }

    private function get_isActive():Bool return active;
    private function get_isPaused():Bool return paused;
    private function get_error():String return failure;
}
