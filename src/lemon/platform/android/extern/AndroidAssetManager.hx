package lemon.platform.android.extern;

@:native("android.content.res.AssetManager")
extern class AndroidAssetManager
{
    public function openFd(fileName:String):AndroidAssetFileDescriptor;
}
