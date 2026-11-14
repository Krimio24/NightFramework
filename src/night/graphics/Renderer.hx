package lemon.graphics;

import haxe.io.BytesData;
import lemon.platform.windows.internal.NativePlace;

class Renderer
{
    private var native:cpp.Pointer<NativePlace>;
    private var disposed:Bool = false;
    private var closed:Bool = false;
    private var frameActive:Bool = false;
    private var resourceGeneration:Int = 0;

    public function new(native:cpp.Pointer<NativePlace>)
    {
        this.native = native;
    }

    public function beginFrame(red:Int = 0, green:Int = 0, blue:Int = 0, alpha:Int = 255):Bool
    {
        frameActive = !disposed && native.ptr.beginFrame(red, green, blue, alpha);
        return frameActive;
    }

    public function endFrame():Bool
    {
        if (disposed || !frameActive)
            return false;
        frameActive = false;
        return native.ptr.endFrame();
    }

    public function close():Void
    {
        if (disposed || closed)
            return;
        native.ptr.close();
        frameActive = false;
        resourceGeneration++;
        closed = true;
    }

    public function markCreated():Void
    {
        if (!disposed)
            closed = false;
    }

    public function dispose():Void
    {
        if (disposed)
            return;
        close();
        disposed = true;
    }

    public function isDisposed():Bool
    {
        return disposed;
    }

    public function render(sprite:Sprite):Bool
    {
        if (disposed || !frameActive || sprite == null || !sprite.visible || !sprite.graphics.prepare(this))
            return false;

        var texture = sprite.graphics.imageTexture();
        if (sprite.graphics.hasImage())
        {
            var frame = sprite.currentFrame;
            if (sprite.width <= 0)
                sprite.width = frame != null ? frame.frameWidth : native.ptr.textureWidth(texture);
            if (sprite.height <= 0)
                sprite.height = frame != null ? frame.frameHeight : native.ptr.textureHeight(texture);
        }
        else if (sprite.graphics.hasVideo())
        {
            if (sprite.width <= 0)
                sprite.width = native.ptr.textureWidth(sprite.graphics.videoTexture());
            if (sprite.height <= 0)
                sprite.height = native.ptr.textureHeight(sprite.graphics.videoTexture());
        }

        native.ptr.setTransform(sprite.scaleX, sprite.scaleY, sprite.rotation, sprite.x, sprite.y);
        var result = true;
        if (sprite.graphics.hasImage())
        {
            var frame = sprite.currentFrame;
            if (frame != null)
            {
                if (sprite.width <= 0)
                    sprite.width = frame.frameWidth;
                if (sprite.height <= 0)
                    sprite.height = frame.frameHeight;
                result = native.ptr.drawTextureRegion(texture,
                    frame.x, frame.y, frame.width, frame.height,
                    frame.frameX, frame.frameY, frame.width, frame.height, sprite.alpha);
            }
            else
                result = native.ptr.drawTexture(texture, 0, 0, sprite.width, sprite.height, sprite.alpha);
        }
        if (sprite.graphics.hasVideo())
            result = native.ptr.drawTexture(sprite.graphics.videoTexture(), 0, 0, sprite.width, sprite.height, sprite.alpha) && result;
        sprite.graphics.drawCommands(this, sprite.alpha);
        native.ptr.resetTransform();
        return result;
    }

    public function renderText(text:Text):Bool
    {
        if (disposed || !frameActive || text == null || !text.visible || text.text == null || text.text.length == 0)
            return false;

        var font = -1;
        if (text.fontPath != null && text.fontPath.length > 0)
        {
            if (!text.prepareFont(this))
                return false;
            font = text.fontId;
        }

        native.ptr.setTransform(text.scaleX, text.scaleY, text.rotation, text.x, text.y);
        var alpha = opacity(text.alpha);
        var result = native.ptr.drawText(
            text.text,
            0,
            0,
            text.width > 0 ? text.width : native.ptr.width(),
            text.height > 0 ? text.height : native.ptr.height(),
            text.fontSize,
            channel(text.color, 16),
            channel(text.color, 8),
            channel(text.color, 0),
            alpha,
            font,
            text.fontWeight,
            text.fontStyle,
            text.fontStretch,
            text.textAlignment,
            text.paragraphAlignment
        );
        native.ptr.resetTransform();
        return result;
    }

    @:allow(lemon.graphics.Graphics)
    private function _drawLine(x1:Float, y1:Float, x2:Float, y2:Float, red:Int, green:Int, blue:Int, alpha:Int, thickness:Float):Void
    {
        native.ptr.drawLine(x1, y1, x2, y2, red, green, blue, alpha, thickness);
    }

    @:allow(lemon.graphics.Graphics)
    private function _drawRectangle(x:Float, y:Float, width:Float, height:Float, red:Int, green:Int, blue:Int, alpha:Int, thickness:Float):Void
    {
        native.ptr.drawRectangle(x, y, width, height, red, green, blue, alpha, thickness);
    }

    @:allow(lemon.graphics.Graphics)
    private function _fillRectangle(x:Float, y:Float, width:Float, height:Float, red:Int, green:Int, blue:Int, alpha:Int):Void
    {
        native.ptr.fillRectangle(x, y, width, height, red, green, blue, alpha);
    }

    @:allow(lemon.graphics.Graphics)
    private function _drawCircle(x:Float, y:Float, radius:Float, red:Int, green:Int, blue:Int, alpha:Int, thickness:Float):Void
    {
        native.ptr.drawCircle(x, y, radius, red, green, blue, alpha, thickness);
    }

    @:allow(lemon.graphics.Graphics)
    private function _fillCircle(x:Float, y:Float, radius:Float, red:Int, green:Int, blue:Int, alpha:Int):Void
    {
        native.ptr.fillCircle(x, y, radius, red, green, blue, alpha);
    }

    @:allow(lemon.graphics.Graphics)
    private function _fillTriangle(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, red:Int, green:Int, blue:Int, alpha:Int):Void
    {
        native.ptr.fillTriangle(x1, y1, x2, y2, x3, y3, red, green, blue, alpha);
    }

    @:allow(lemon.graphics.Graphics)
    private function _loadTexture(path:String):Int
    {
        return disposed ? -1 : native.ptr.loadTexture(path);
    }

    @:allow(lemon.graphics.Graphics)
    private function _loadTextureBytes(bytes:BytesData, length:Int):Int
    {
        return disposed ? -1 : native.ptr.loadTextureBytes(bytes, length);
    }

    @:allow(lemon.graphics.Video)
    private function _loadTexturePixels(bytes:BytesData, length:Int, width:Int, height:Int):Int
    {
        return disposed ? -1 : native.ptr.loadTexturePixels(bytes, length, width, height);
    }

    @:allow(lemon.graphics.Video)
    private function _updateTexturePixels(texture:Int, bytes:BytesData, length:Int, width:Int, height:Int):Bool
    {
        return !disposed && native.ptr.updateTexturePixels(texture, bytes, length, width, height);
    }

    @:allow(lemon.graphics.Graphics)
    @:allow(lemon.graphics.Video)
    private function _unloadTexture(texture:Int):Void
    {
        if (!disposed && texture >= 0)
            native.ptr.unloadTexture(texture);
    }

    @:allow(lemon.graphics.Graphics)
    @:allow(lemon.graphics.Text)
    private function _loadFont(path:String, family:String):Int
    {
        return disposed ? -1 : native.ptr.loadFont(path, family);
    }

    @:allow(lemon.graphics.Graphics)
    @:allow(lemon.graphics.Text)
    private function _unloadFont(font:Int):Void
    {
        if (!disposed && font >= 0)
            native.ptr.unloadFont(font);
    }

    @:allow(lemon.graphics.Graphics)
    @:allow(lemon.graphics.Text)
    @:allow(lemon.graphics.Video)
    private function _resourceGeneration():Int
    {
        return resourceGeneration;
    }

    @:allow(lemon.graphics.Graphics)
    private function _drawText(text:String, x:Float, y:Float, size:Float, red:Int, green:Int, blue:Int, alpha:Int, font:Int):Void
    {
        native.ptr.drawText(text, x, y, native.ptr.width(), native.ptr.height(), size,
            red, green, blue, alpha, font, 400, 0, 5, 0, 0);
    }

    private static function opacity(alpha:Float):Int
    {
        return Std.int(Math.max(0, Math.min(255, alpha * 255)));
    }

    private static function channel(color:Int, shift:Int):Int
    {
        return (color >> shift) & 0xFF;
    }
}
