package lemon.platform.android.extern;

@:native("java.nio.FloatBuffer")
extern class GLFloatBuffer extends GLBuffer
{
    public function put(index:Int, value:Single):GLFloatBuffer;
    public function position(newPosition:Int):GLFloatBuffer;
}
