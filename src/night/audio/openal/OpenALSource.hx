package lemon.audio.openal;

class OpenALSource
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

    public function bind(buffer:OpenALBuffer):Bool
    {
        if (!valid() || buffer == null || buffer._id() <= 0)
            return false;
        return context._native().ptr.bindBuffer(id, buffer._id());
    }

    public function play():Bool return valid() && context._native().ptr.sourcePlay(id);
    public function pause():Bool return valid() && context._native().ptr.sourcePause(id);
    public function stop():Bool return valid() && context._native().ptr.sourceStop(id);
    public function rewind():Bool return valid() && context._native().ptr.sourceRewind(id);
    public function state():Int return valid() ? context._native().ptr.sourceState(id) : OpenALConstants.STOPPED;

    public function setGain(value:Float):Bool return setFloat(OpenALConstants.GAIN, value);
    public function setPitch(value:Float):Bool return setFloat(OpenALConstants.PITCH, value);
    public function setLooping(value:Bool):Bool return setInt(OpenALConstants.LOOPING, value ? 1 : 0);
    public function setPosition(x:Float, y:Float, z:Float):Bool return setVector(OpenALConstants.POSITION, x, y, z);
    public function setVelocity(x:Float, y:Float, z:Float):Bool return setVector(OpenALConstants.VELOCITY, x, y, z);
    public function setReferenceDistance(value:Float):Bool return setFloat(OpenALConstants.REFERENCE_DISTANCE, value);
    public function setRolloffFactor(value:Float):Bool return setFloat(OpenALConstants.ROLLOFF_FACTOR, value);
    public function setMaxDistance(value:Float):Bool return setFloat(OpenALConstants.MAX_DISTANCE, value);
    public function setSecondsOffset(value:Float):Bool return setFloat(OpenALConstants.SEC_OFFSET, value);

    public function queue(buffer:OpenALBuffer):Bool
    {
        return valid() && buffer != null && buffer._id() > 0 &&
            context._native().ptr.queueBuffer(id, buffer._id());
    }

    public function unqueueProcessed():Int
    {
        return valid() ? context._native().ptr.unqueueProcessed(id) : -1;
    }

    public function applyFilter(filter:OpenALFilter):Bool
    {
        return valid() && filter != null && context._native().ptr.setSourceFilter(id, filter._id());
    }

    public function sendTo(slot:OpenALEffectSlot, send:Int = 0):Bool
    {
        return valid() && slot != null && context._native().ptr.attachEffectSlot(id, slot._id(), send);
    }

    public function dispose():Void
    {
        if (disposed)
            return;
        if (!context._isDisposed())
            context._native().ptr.deleteSource(id);
        disposed = true;
    }

    private function valid():Bool
    {
        return !disposed && !context._isDisposed() && context.isOpen();
    }

    private function setFloat(parameter:Int, value:Float):Bool
    {
        return valid() && context._native().ptr.setSourcef(id, parameter, value);
    }

    private function setVector(parameter:Int, x:Float, y:Float, z:Float):Bool
    {
        return valid() && context._native().ptr.setSource3f(id, parameter, x, y, z);
    }

    private function setInt(parameter:Int, value:Int):Bool
    {
        return valid() && context._native().ptr.setSourcei(id, parameter, value);
    }
}
