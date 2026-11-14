package lemon.platform.android.extern;

@:native("android.view.MotionEvent")
extern class AndroidMotionEvent
{
    public static inline var ACTION_DOWN:Int = 0;
    public static inline var ACTION_UP:Int = 1;
    public static inline var ACTION_MOVE:Int = 2;
    public static inline var ACTION_CANCEL:Int = 3;
    public static inline var ACTION_POINTER_DOWN:Int = 5;
    public static inline var ACTION_POINTER_UP:Int = 6;

    public function getActionMasked():Int;
    public function getActionIndex():Int;
    public function getPointerCount():Int;
    public function getPointerId(pointerIndex:Int):Int;
    public function getX(pointerIndex:Int):Single;
    public function getY(pointerIndex:Int):Single;
    public function getPressure(pointerIndex:Int):Single;
}
