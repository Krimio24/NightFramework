package lemon.audio.openal;

class OpenALFilter
{
    private var context:OpenALContext;
    private var id:Int;
    private var disposed:Bool = false;

    @:allow(lemon.audio.openal.OpenALContext)
    private function new(context:OpenALContext, id:Int)
    {
        this.context = context;
        this.id = id;
    }

    public function setFloat(parameter:Int, value:Float):Bool
    {
        return valid() && context._native().ptr.setFilterf(id, parameter, value);
    }

    public function setInt(parameter:Int, value:Int):Bool
    {
        return valid() && context._native().ptr.setFilteri(id, parameter, value);
    }

    public function dispose():Void
    {
        if (disposed) return;
        if (!context._isDisposed()) context._native().ptr.deleteFilter(id);
        disposed = true;
    }

    @:allow(lemon.audio.openal.OpenALSource)
    private function _id():Int return disposed ? -1 : id;

    private function valid():Bool return !disposed && !context._isDisposed() && context.isOpen();
}
