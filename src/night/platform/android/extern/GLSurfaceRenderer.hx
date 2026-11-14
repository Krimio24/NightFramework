package lemon.platform.android.extern;

@:native("android.opengl.GLSurfaceView.Renderer")
extern interface GLSurfaceRenderer
{
    public function onSurfaceCreated(gl:GL10, config:EGLConfig):Void;
    public function onSurfaceChanged(gl:GL10, width:Int, height:Int):Void;
    public function onDrawFrame(gl:GL10):Void;
}
