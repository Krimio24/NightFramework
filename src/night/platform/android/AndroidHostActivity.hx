package lemon.platform.android;

import java.Init;
import lemon.Activity;
import lemon.graphics.GraphicsContext;
import lemon.platform.android.extern.AndroidActivity;
import lemon.platform.android.extern.AndroidBundle;
import lemon.platform.android.extern.AndroidMotionEvent;
import lemon.platform.android.extern.AndroidTouchEvent;
import lemon.platform.android.extern.AndroidTouchEventQueue;
import lemon.platform.android.extern.GLSurfaceView;

class AndroidHostActivity extends AndroidActivity
{
    private var surface:GLSurfaceView;
    private var activity:Activity;
    private var activityCreated:Bool = false;
    private var touchEvents:AndroidTouchEventQueue = new AndroidTouchEventQueue();

    override public function onCreate(savedInstanceState:AndroidBundle):Void
    {
        super.onCreate(savedInstanceState);
        Init.init();
        activity = createActivity();
        if (activity == null)
            throw "AndroidHostActivity.createActivity() must return a Lemon Activity.";

        surface = new AndroidTouchSurface(this, this);
        surface.setEGLContextClientVersion(2);
        surface.setRenderer(new AndroidSceneRenderer(this));
        surface.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
        setContentView(surface);
    }

    public function createActivity():Activity
    {
        return new Activity();
    }

    override public function onPause():Void
    {
        if (surface != null)
            surface.onPause();
        if (activityCreated && activity != null)
            activity.pause();
        super.onPause();
    }

    override public function onResume():Void
    {
        super.onResume();
        if (surface != null)
            surface.onResume();
        if (activityCreated && activity != null)
            activity.resume();
    }

    override public function onDestroy():Void
    {
        if (activityCreated && activity != null)
        {
            activity.destroy();
            activityCreated = false;
        }
        super.onDestroy();
    }

    @:allow(lemon.platform.android.AndroidTouchSurface)
    private function _queueTouchEvent(event:AndroidMotionEvent):Void
    {
        if (activity == null || event == null)
            return;

        var action = event.getActionMasked();
        var actionIndex = event.getActionIndex();
        switch (action)
        {
            case AndroidMotionEvent.ACTION_DOWN, AndroidMotionEvent.ACTION_POINTER_DOWN:
                queueTouch(event, actionIndex, AndroidMotionEvent.ACTION_DOWN);
            case AndroidMotionEvent.ACTION_MOVE:
                for (index in 0...event.getPointerCount())
                    queueTouch(event, index, AndroidMotionEvent.ACTION_MOVE);
            case AndroidMotionEvent.ACTION_UP, AndroidMotionEvent.ACTION_POINTER_UP:
                queueTouch(event, actionIndex, AndroidMotionEvent.ACTION_UP);
            case AndroidMotionEvent.ACTION_CANCEL:
                touchEvents.offer(new AndroidTouchEvent(AndroidMotionEvent.ACTION_CANCEL, -1, 0, 0, 0));
            default:
                return;
        }
    }

    @:allow(lemon.platform.android.AndroidSceneRenderer)
    private function _surfaceCreated():Void
    {
        if (activityCreated || activity == null)
            return;
        activity.create();
        activityCreated = true;
    }

    @:allow(lemon.platform.android.AndroidSceneRenderer)
    private function _drawFrame(graphics:GraphicsContext, elapsed:Float):Void
    {
        if (!activityCreated || activity == null)
            return;
        drainTouchEvents();
        activity.update(elapsed);
        activity.draw(graphics);
    }

    private function queueTouch(event:AndroidMotionEvent, pointerIndex:Int, action:Int):Void
    {
        touchEvents.offer(new AndroidTouchEvent(
            action,
            event.getPointerId(pointerIndex),
            event.getX(pointerIndex),
            event.getY(pointerIndex),
            event.getPressure(pointerIndex)
        ));
    }

    private function drainTouchEvents():Void
    {
        var queued:Dynamic = touchEvents.poll();
        while (queued != null)
        {
            var event:AndroidTouchEvent = cast queued;
            switch (event.action)
            {
                case AndroidMotionEvent.ACTION_DOWN:
                    activity.touch.down(event.id, event.x, event.y, event.pressure);
                case AndroidMotionEvent.ACTION_MOVE:
                    activity.touch.move(event.id, event.x, event.y, event.pressure);
                case AndroidMotionEvent.ACTION_UP:
                    activity.touch.up(event.id, event.x, event.y, event.pressure);
                case AndroidMotionEvent.ACTION_CANCEL:
                    activity.touch.cancelAll();
            }
            queued = touchEvents.poll();
        }
    }
}
