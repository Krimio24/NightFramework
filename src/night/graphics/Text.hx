package lemon.graphics;

@:allow(lemon.graphics.Renderer)
class Text
{
    public var text:String = "";
    public var x:Float = 0;
    public var y:Float = 0;
    public var width:Float = 0;
    public var height:Float = 0;
    public var scaleX:Float = 1;
    public var scaleY:Float = 1;
    public var rotation:Float = 0;
    public var alpha:Float = 1;
    public var visible:Bool = true;
    public var color:Int = 0xFFFFFF;

    public var fontPath:String;
    public var fontFamily:String = "Segoe UI";
    public var fontSize:Float = 20;
    public var fontWeight:FontWeight = FontWeight.Normal;
    public var fontStyle:FontStyle = FontStyle.Normal;
    public var fontStretch:FontStretch = FontStretch.Normal;
    public var textAlignment:TextAlignment = TextAlignment.Leading;
    public var paragraphAlignment:ParagraphAlignment = ParagraphAlignment.Near;

    private var fontId:Int = -1;
    private var fontOwner:Renderer;
    private var fontGeneration:Int = -1;
    private var loadedFontPath:String;
    private var loadedFontFamily:String;

    public function new(text:String = "")
    {
        this.text = text;
    }

    @:allow(lemon.graphics.Renderer)
    private function prepareFont(renderer:Renderer):Bool
    {
        if (fontPath == null || fontPath.length == 0)
        {
            releaseFont();
            return true;
        }

        if (fontOwner != renderer || fontId < 0 ||
            fontGeneration != renderer._resourceGeneration() ||
            loadedFontPath != fontPath || loadedFontFamily != fontFamily)
        {
            releaseFont();
            fontId = renderer._loadFont(fontPath, fontFamily);
            if (fontId < 0)
                return false;
            fontOwner = renderer;
            fontGeneration = renderer._resourceGeneration();
            loadedFontPath = fontPath;
            loadedFontFamily = fontFamily;
        }
        return true;
    }

    private function releaseFont():Void
    {
        if (fontOwner != null && !fontOwner.isDisposed() &&
            fontGeneration == fontOwner._resourceGeneration())
            fontOwner._unloadFont(fontId);
        fontOwner = null;
        fontId = -1;
        fontGeneration = -1;
        loadedFontPath = null;
        loadedFontFamily = null;
    }
}
