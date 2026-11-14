package lemon;

#if cpp

import lemon.graphics.Renderer;
import lemon.graphics.Sprite;
import lemon.graphics.Text;
import lemon.input.Input;
import lemon.platform.windows.input.WindowsInputBackend;
import lemon.platform.windows.internal.NativePlace;
import lemon.tween.TweenManager;

class Place
{
    private var native:cpp.Pointer<NativePlace>;
    private var renderer:Renderer;
    public var input(default, null):Input;
    public var tweens(default, null):TweenManager;
    private var disposed:Bool = false;
    private var closed:Bool = false;
    private var closePending:Bool = false;
    private var disposePending:Bool = false;
    private var lastTweenUpdate:Float;

    public function new(title:String, width:Int, height:Int)
    {
        native = NativePlace.allocate(title, width, height);
        renderer = new Renderer(native);
        input = new Input(new WindowsInputBackend(native));
        tweens = new TweenManager();
        lastTweenUpdate = haxe.Timer.stamp();
    }

    public function create():Bool
    {
        if (disposed)
            return false;
        var created = native.ptr.create();
        if (created)
        {
            closed = false;
            lastTweenUpdate = haxe.Timer.stamp();
            renderer.markCreated();
        }
        return created;
    }

    public function show():Void
    {
        if (!disposed)
            native.ptr.show();
    }

    public function hide():Void
    {
        if (!disposed)
            native.ptr.hide();
    }

    public function setTitle(title:String):Void
    {
        if (!disposed)
            native.ptr.setTitle(title);
    }

    public function setSize(width:Int, height:Int):Void
    {
        if (!disposed)
            native.ptr.setSize(width, height);
    }

    public function close():Void
    {
        if (disposed || closed)
            return;
        if (input.isUpdating)
        {
            closePending = true;
            return;
        }
        renderer.close();
        closed = true;
    }

    public function beginFrame(red:Int = 0, green:Int = 0, blue:Int = 0, alpha:Int = 255):Bool
    {
        return !disposed && renderer.beginFrame(red, green, blue, alpha);
    }

    public function endFrame():Bool
    {
        return !disposed && renderer.endFrame();
    }

    public function update():Bool
    {
        if (disposed || !NativePlace.pollEvents())
            return false;
        input.update();
        if (disposePending)
        {
            disposePending = false;
            renderer.dispose();
            tweens.clear();
            native.destroy();
            disposed = true;
            closed = true;
            closePending = false;
            return false;
        }
        if (closePending)
        {
            closePending = false;
            renderer.close();
            closed = true;
        }
        var now = haxe.Timer.stamp();
        tweens.update(now - lastTweenUpdate);
        lastTweenUpdate = now;
        return isOpen();
    }

    public function render(sprite:Sprite):Bool
    {
        return !disposed && renderer.render(sprite);
    }

    public function renderText(text:Text):Bool
    {
        return !disposed && renderer.renderText(text);
    }

    public function dispose():Void
    {
        if (disposed)
            return;
        if (input.isUpdating)
        {
            disposePending = true;
            closePending = true;
            return;
        }
        renderer.dispose();
        tweens.clear();
        native.destroy();
        disposed = true;
        closed = true;
    }

    public function isDisposed():Bool
    {
        return disposed;
    }

    public function isOpen():Bool
    {
        return !disposed && native.ptr.isOpen();
    }

    public function isVisible():Bool
    {
        return !disposed && native.ptr.isVisible();
    }

    public function width():Int
    {
        return disposed ? 0 : native.ptr.width();
    }

    public function height():Int
    {
        return disposed ? 0 : native.ptr.height();
    }

    public function title():String
    {
        return disposed ? "" : native.ptr.title();
    }

    @:allow(lemon.platform.windows.WindowsApplicationBackend)
    private function _setTaskbarProgress(state:Int, value:Int, maximum:Int):Bool
    {
        return !disposed && native.ptr.setTaskbarProgress(state, value, maximum);
    }

    @:allow(lemon.platform.windows.WindowsApplicationBackend)
    private function _showNotification(title:String, message:String):Bool
    {
        return !disposed && native.ptr.showNotification(title, message);
    }

    @:allow(lemon.platform.windows.WindowsApplicationBackend)
    private function _showTrayNotification(title:String, message:String):Bool
    {
        return !disposed && native.ptr.showTrayNotification(title, message);
    }

    @:allow(lemon.platform.windows.WindowsApplicationBackend)
    private function _hideTrayNotification():Void
    {
        if (!disposed)
            native.ptr.hideTrayNotification();
    }

    public static function pollEvents():Bool
    {
        return NativePlace.pollEvents();
    }
}

#else

class Place
{
    public function new(title:String, width:Int, height:Int)
    {
        throw "lemon.Place requires hxcpp on Windows.";
    }
}

#end
