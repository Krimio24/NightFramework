package lemon.platform.android.extern;

@:native("android.view.View")
extern class AndroidView
{
    public function onTouchEvent(event:AndroidMotionEvent):Bool;
}
