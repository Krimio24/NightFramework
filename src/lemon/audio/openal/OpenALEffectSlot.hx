package lemon.audio.openal;

class OpenALEffectSlot
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

    public function setEffect(effect:OpenALEffect):Bool
    {
        return !disposed && !context._isDisposed() && effect != null &&
            context._native().ptr.setEffectSlot(id, effect._id());
    }

    public function dispose():Void
    {
        if (disposed) return;
        if (!context._isDisposed()) context._native().ptr.deleteEffectSlot(id);
        disposed = true;
    }

    @:allow(lemon.audio.openal.OpenALSource)
    @:allow(lemon.audio.openal.OpenALEffect)
    private function _id():Int return disposed ? -1 : id;
}
