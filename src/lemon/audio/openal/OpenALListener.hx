package lemon.audio.openal;

class OpenALListener
{
    private var context:OpenALContext;

    @:allow(lemon.audio.openal.OpenALContext)
    private function new(context:OpenALContext)
    {
        this.context = context;
    }

    public function setPosition(x:Float, y:Float, z:Float):Bool
    {
        return context.isOpen() && context._native().ptr.setListener3f(OpenALConstants.POSITION, x, y, z);
    }

    public function setVelocity(x:Float, y:Float, z:Float):Bool
    {
        return context.isOpen() && context._native().ptr.setListener3f(OpenALConstants.VELOCITY, x, y, z);
    }

    public function setGain(value:Float):Bool
    {
        return context.isOpen() && context._native().ptr.setListenerf(OpenALConstants.GAIN, value);
    }

    public function setOrientation(atX:Float, atY:Float, atZ:Float, upX:Float, upY:Float, upZ:Float):Bool
    {
        return context.isOpen() &&
            context._native().ptr.setListenerOrientation(atX, atY, atZ, upX, upY, upZ);
    }
}
