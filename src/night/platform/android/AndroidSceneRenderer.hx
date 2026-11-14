package lemon.platform.android;

import lemon.platform.android.extern.EGLConfig;
import lemon.platform.android.extern.GL10;
import lemon.platform.android.extern.GLSurfaceRenderer;

class AndroidSceneRenderer implements GLSurfaceRenderer
{
    private var host:AndroidHostActivity;
    private var graphics:GLGraphics;
    private var lastFrameTime:Float = 0;

    public function new(host:AndroidHostActivity)
    {
        this.host = host;
    }

    public function onSurfaceCreated(gl:GL10, config:EGLConfig):Void
    {
        graphics = new GLGraphics();
        graphics.initialize();
        host._surfaceCreated();
        lastFrameTime = haxe.Timer.stamp();
    }

    public function onSurfaceChanged(gl:GL10, width:Int, height:Int):Void
    {
        if (graphics != null)
            graphics.resize(width, height);
    }

    public function onDrawFrame(gl:GL10):Void
    {
        if (graphics == null)
            return;
        var now = haxe.Timer.stamp();
        var elapsed = Math.max(0, Math.min(now - lastFrameTime, 0.25));
        lastFrameTime = now;
        host._drawFrame(graphics, elapsed);
    }
}
