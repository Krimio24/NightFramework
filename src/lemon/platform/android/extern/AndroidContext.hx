package lemon.platform.android.extern;

@:native("android.content.Context")
extern class AndroidContext
{
    public function getAssets():AndroidAssetManager;
}
