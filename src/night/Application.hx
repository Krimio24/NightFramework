package lemon;

#if cpp

import lemon.notifications.NotificationCenter;
import lemon.notifications.TrayNotification;
import lemon.platform.windows.WindowsApplicationBackend;

class Application
{
    public var window(default, null):Place;
    public var notifications(default, null):NotificationCenter;
    public var tray(default, null):TrayNotification;
    public var progressBar(default, null):TaskbarProgressBar;

    private var disposed:Bool = false;

    public function new(title:String, width:Int, height:Int)
    {
        window = new Place(title, width, height);
        var backend = new WindowsApplicationBackend(window);
        notifications = new NotificationCenter(backend);
        tray = new TrayNotification(backend);
        progressBar = new TaskbarProgressBar(backend);
    }

    public function create():Bool
    {
        return !disposed && window.create();
    }

    public function show():Void
    {
        if (!disposed)
            window.show();
    }

    public function hide():Void
    {
        if (!disposed)
            window.hide();
    }

    public function update():Bool
    {
        return !disposed && window.update();
    }

    public function run(onUpdate:Void->Void = null):Bool
    {
        if (disposed || (!window.isOpen() && !create()))
            return false;
        show();
        while (update())
        {
            if (onUpdate != null)
                onUpdate();
            Sys.sleep(1 / 60);
        }
        return true;
    }

    public function close():Void
    {
        if (!disposed)
            window.close();
    }

    public function dispose():Void
    {
        if (disposed)
            return;
        window.dispose();
        disposed = true;
    }

    public function isDisposed():Bool
    {
        return disposed;
    }
}

#else

class Application
{
    public function new(title:String, width:Int, height:Int)
    {
        throw "lemon.Application currently requires hxcpp on Windows.";
    }
}

#end
