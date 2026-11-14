package lemon.events;

typedef EventListener = Event->Void;

class EventDispatcher
{
    private var listeners:Map<String, Array<EventListener>> = new Map();

    public function new()
    {
    }

    public function on(type:String, listener:EventListener):Void
    {
        if (type == null || listener == null)
            throw "Event type and listener are required.";
        var typeListeners = listeners.get(type);
        if (typeListeners == null)
        {
            typeListeners = [];
            listeners.set(type, typeListeners);
        }
        typeListeners.push(listener);
    }

    public function off(type:String, listener:EventListener):Bool
    {
        var typeListeners = listeners.get(type);
        if (typeListeners == null)
            return false;
        var index = typeListeners.indexOf(listener);
        if (index < 0)
            return false;
        typeListeners.splice(index, 1);
        if (typeListeners.length == 0)
            listeners.remove(type);
        return true;
    }

    public function dispatch(event:Event):Void
    {
        var typeListeners = listeners.get(event.type);
        if (typeListeners == null)
            return;
        for (listener in typeListeners.copy())
            listener(event);
    }
}
