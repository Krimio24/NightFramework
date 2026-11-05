package lemon.events;

class Event
{
    public var type(default, null):String;
    public var data(default, null):Dynamic;

    public function new(type:String, data:Dynamic = null)
    {
        this.type = type;
        this.data = data;
    }
}
