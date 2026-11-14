package lemon.platform.android.extern;

@:native("java.nio.ByteBuffer")
extern class GLByteBuffer extends GLBuffer
{
    public static function allocateDirect(capacity:Int):GLByteBuffer;
    public function order(byteOrder:GLByteOrder):GLByteBuffer;
    public function asFloatBuffer():GLFloatBuffer;
}
