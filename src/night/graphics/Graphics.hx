package lemon.graphics;

import haxe.io.Bytes;

private enum GraphicsCommand
{
    Line(x1:Float, y1:Float, x2:Float, y2:Float, red:Int, green:Int, blue:Int, alpha:Int, thickness:Float);
    Rectangle(x:Float, y:Float, width:Float, height:Float, red:Int, green:Int, blue:Int, alpha:Int, thickness:Float);
    FilledRectangle(x:Float, y:Float, width:Float, height:Float, red:Int, green:Int, blue:Int, alpha:Int);
    Circle(x:Float, y:Float, radius:Float, red:Int, green:Int, blue:Int, alpha:Int, thickness:Float);
    FilledCircle(x:Float, y:Float, radius:Float, red:Int, green:Int, blue:Int, alpha:Int);
    Triangle(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, red:Int, green:Int, blue:Int, alpha:Int);
    Text(text:String, x:Float, y:Float, size:Float, red:Int, green:Int, blue:Int, alpha:Int);
}

class Graphics
{
    private var commands:Array<GraphicsCommand> = [];
    private var imagePath:String;
    private var imageBytes:Bytes;
    private var textureId:Int = -1;
    private var textureOwner:Renderer;
    private var textureGeneration:Int = -1;
    private var fontPath:String;
    private var fontFamily:String;
    private var fontId:Int = -1;
    private var fontOwner:Renderer;
    private var fontGeneration:Int = -1;
    public var video(default, null):Video;

    public function new()
    {
        video = new Video();
    }

    public function load(source:Dynamic):Bool
    {
        if (textureOwner != null && !textureOwner.isDisposed() &&
            textureGeneration == textureOwner._resourceGeneration())
            textureOwner._unloadTexture(textureId);
        textureOwner = null;
        textureId = -1;
        textureGeneration = -1;
        imagePath = null;
        imageBytes = null;

        if (Std.isOfType(source, String))
        {
            var path:String = cast source;
            if (path.length == 0)
                return false;
            imagePath = path;
            return true;
        }

        if (Std.isOfType(source, Bytes))
        {
            var bytes:Bytes = cast source;
            if (bytes.length == 0)
                return false;
            imageBytes = Bytes.alloc(bytes.length);
            imageBytes.blit(0, bytes, 0, bytes.length);
            return true;
        }

        return false;
    }

    public function clear():Void
    {
        commands.resize(0);
    }

    public function drawLine(x1:Float, y1:Float, x2:Float, y2:Float, red:Int, green:Int, blue:Int, alpha:Int = 255, thickness:Float = 1):Void
    {
        commands.push(Line(x1, y1, x2, y2, red, green, blue, alpha, thickness));
    }

    public function drawRect(x:Float, y:Float, width:Float, height:Float, red:Int, green:Int, blue:Int, alpha:Int = 255, thickness:Float = 1):Void
    {
        commands.push(Rectangle(x, y, width, height, red, green, blue, alpha, thickness));
    }

    public function fillRect(x:Float, y:Float, width:Float, height:Float, red:Int, green:Int, blue:Int, alpha:Int = 255):Void
    {
        commands.push(FilledRectangle(x, y, width, height, red, green, blue, alpha));
    }

    public function drawCircle(x:Float, y:Float, radius:Float, red:Int, green:Int, blue:Int, alpha:Int = 255, thickness:Float = 1):Void
    {
        commands.push(Circle(x, y, radius, red, green, blue, alpha, thickness));
    }

    public function fillCircle(x:Float, y:Float, radius:Float, red:Int, green:Int, blue:Int, alpha:Int = 255):Void
    {
        commands.push(FilledCircle(x, y, radius, red, green, blue, alpha));
    }

    public function fillTriangle(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, red:Int, green:Int, blue:Int, alpha:Int = 255):Void
    {
        commands.push(Triangle(x1, y1, x2, y2, x3, y3, red, green, blue, alpha));
    }

    public function drawText(text:String, x:Float, y:Float, size:Float, red:Int, green:Int, blue:Int, alpha:Int = 255):Void
    {
        commands.push(Text(text, x, y, size, red, green, blue, alpha));
    }

    public function loadFont(path:String, family:String):Bool
    {
        if (path == null || path.length == 0 || family == null || family.length == 0)
            return false;
        if (fontOwner != null && !fontOwner.isDisposed() &&
            fontGeneration == fontOwner._resourceGeneration())
            fontOwner._unloadFont(fontId);
        fontOwner = null;
        fontPath = path;
        fontFamily = family;
        fontId = -1;
        fontGeneration = -1;
        return true;
    }

    public function unloadFont():Void
    {
        if (fontOwner != null && !fontOwner.isDisposed() &&
            fontGeneration == fontOwner._resourceGeneration())
            fontOwner._unloadFont(fontId);
        fontOwner = null;
        fontPath = null;
        fontFamily = null;
        fontId = -1;
        fontGeneration = -1;
    }

    @:allow(lemon.graphics.Renderer)
    private function prepare(renderer:Renderer):Bool
    {
        if (video.isAvailable() && !video.prepare(renderer))
            return false;

        if (imagePath != null || imageBytes != null)
        {
            if (textureOwner != renderer || textureId < 0 || textureGeneration != renderer._resourceGeneration())
            {
                if (textureOwner != null && !textureOwner.isDisposed() &&
                    textureOwner != renderer &&
                    textureGeneration == textureOwner._resourceGeneration())
                    textureOwner._unloadTexture(textureId);

                textureId = imagePath != null
                    ? renderer._loadTexture(imagePath)
                    : renderer._loadTextureBytes(imageBytes.getData(), imageBytes.length);
                if (textureId < 0)
                {
                    textureOwner = null;
                    return false;
                }
                textureOwner = renderer;
                textureGeneration = renderer._resourceGeneration();
            }
        }

        if (fontPath != null)
        {
            if (fontOwner != renderer || fontId < 0 || fontGeneration != renderer._resourceGeneration())
            {
                if (fontOwner != null && !fontOwner.isDisposed() &&
                    fontGeneration == fontOwner._resourceGeneration())
                    fontOwner._unloadFont(fontId);
                fontId = renderer._loadFont(fontPath, fontFamily);
                if (fontId < 0)
                {
                    fontOwner = null;
                    return false;
                }
                fontOwner = renderer;
                fontGeneration = renderer._resourceGeneration();
            }
        }
        return true;
    }

    @:allow(lemon.graphics.Renderer)
    private function imageTexture():Int
    {
        return textureId;
    }

    @:allow(lemon.graphics.Renderer)
    private function hasImage():Bool
    {
        return imagePath != null || imageBytes != null;
    }

    @:allow(lemon.graphics.Renderer)
    private function hasVideo():Bool
    {
        return video.isAvailable();
    }

    @:allow(lemon.graphics.Renderer)
    private function videoTexture():Int
    {
        return video.texture();
    }

    @:allow(lemon.graphics.Renderer)
    private function drawCommands(renderer:Renderer, spriteAlpha:Float):Void
    {
        for (command in commands)
        {
            switch (command)
            {
                case Line(x1, y1, x2, y2, red, green, blue, alpha, thickness):
                    renderer._drawLine(x1, y1, x2, y2, red, green, blue, opacity(alpha, spriteAlpha), thickness);
                case Rectangle(x, y, width, height, red, green, blue, alpha, thickness):
                    renderer._drawRectangle(x, y, width, height, red, green, blue, opacity(alpha, spriteAlpha), thickness);
                case FilledRectangle(x, y, width, height, red, green, blue, alpha):
                    renderer._fillRectangle(x, y, width, height, red, green, blue, opacity(alpha, spriteAlpha));
                case Circle(x, y, radius, red, green, blue, alpha, thickness):
                    renderer._drawCircle(x, y, radius, red, green, blue, opacity(alpha, spriteAlpha), thickness);
                case FilledCircle(x, y, radius, red, green, blue, alpha):
                    renderer._fillCircle(x, y, radius, red, green, blue, opacity(alpha, spriteAlpha));
                case Triangle(x1, y1, x2, y2, x3, y3, red, green, blue, alpha):
                    renderer._fillTriangle(x1, y1, x2, y2, x3, y3, red, green, blue, opacity(alpha, spriteAlpha));
                case Text(text, x, y, size, red, green, blue, alpha):
                    renderer._drawText(text, x, y, size, red, green, blue, opacity(alpha, spriteAlpha), fontId);
            }
        }
    }

    private static function opacity(alpha:Int, spriteAlpha:Float):Int
    {
        return Std.int(Math.max(0, Math.min(255, alpha)) * Math.max(0, Math.min(1, spriteAlpha)));
    }

}
