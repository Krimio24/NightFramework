package lemon.platform.android.extern;

@:native("android.media.MediaPlayer")
extern class AndroidMediaPlayer
{
    public function new():Void;
    public function setDataSource(fileDescriptor:AndroidFileDescriptor, offset:haxe.Int64, length:haxe.Int64):Void;
    public function prepare():Void;
    public function start():Void;
    public function pause():Void;
    public function seekTo(milliseconds:Int):Void;
    public function isPlaying():Bool;
    public function setVolume(left:Single, right:Single):Void;
    public function setLooping(looping:Bool):Void;
    public function release():Void;
}
