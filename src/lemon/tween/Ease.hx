package lemon.tween;

class Ease
{
    public static function linear(value:Float):Float
    {
        return value;
    }

    public static function quadIn(value:Float):Float
    {
        return value * value;
    }

    public static function quadOut(value:Float):Float
    {
        return value * (2 - value);
    }

    public static function quadInOut(value:Float):Float
    {
        return value < 0.5
            ? 2 * value * value
            : 1 - Math.pow(-2 * value + 2, 2) / 2;
    }

    public static function cubicIn(value:Float):Float
    {
        return value * value * value;
    }

    public static function cubicOut(value:Float):Float
    {
        return 1 - Math.pow(1 - value, 3);
    }

    public static function cubicInOut(value:Float):Float
    {
        return value < 0.5
            ? 4 * value * value * value
            : 1 - Math.pow(-2 * value + 2, 3) / 2;
    }
}
