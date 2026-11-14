package lemon.platform.android;

import lemon.platform.android.extern.AndroidContext;
import lemon.platform.android.extern.AndroidMotionEvent;
import lemon.platform.android.extern.GLSurfaceView;

class AndroidTouchSurface extends GLSurfaceView
{
    private var host:AndroidHostActivity;

    public function new(context:AndroidContext, host:AndroidHostActivity)
    {
        super(context);
        this.host = host;
    }

    override public function onTouchEvent(event:AndroidMotionEvent):Bool
    {
        host._queueTouchEvent(event);
        return true;
    }
}
