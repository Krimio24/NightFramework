package lemon.platform.android.extern;

@:native("android.opengl.GLSurfaceView")
extern class GLSurfaceView extends AndroidView
{
    public static var RENDERMODE_CONTINUOUSLY:Int;

    public function new(context:AndroidContext):Void;
    public function setEGLContextClientVersion(version:Int):Void;
    public function setRenderer(renderer:GLSurfaceRenderer):Void;
    public function setRenderMode(mode:Int):Void;
    public function onPause():Void;
    public function onResume():Void;
}
