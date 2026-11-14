package lemon.platform.android.extern;

@:native("android.app.Activity")
extern class AndroidActivity extends AndroidContext
{
    public function new():Void;
    public function onCreate(savedInstanceState:AndroidBundle):Void;
    public function onPause():Void;
    public function onResume():Void;
    public function onDestroy():Void;
    public function onTouchEvent(event:AndroidMotionEvent):Bool;
    public function setContentView(view:AndroidView):Void;
}
