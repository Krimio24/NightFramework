package lemon.platform.android.extern;

@:native("android.content.res.AssetFileDescriptor")
extern class AndroidAssetFileDescriptor
{
    public function getFileDescriptor():AndroidFileDescriptor;
    public function getStartOffset():haxe.Int64;
    public function getLength():haxe.Int64;
    public function close():Void;
}
