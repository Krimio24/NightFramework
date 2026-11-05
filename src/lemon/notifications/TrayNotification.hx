package lemon.notifications;

import lemon.platform.windows.WindowsApplicationBackend;

class TrayNotification
{
    private var backend:WindowsApplicationBackend;

    @:allow(lemon.Application)
    private function new(backend:WindowsApplicationBackend)
    {
        this.backend = backend;
    }

    public var error(get, never):String;

    public function show(title:String, message:String):Bool
    {
        return backend.notifyTray(title, message);
    }

    public function hide():Void
    {
        backend.hideTray();
    }

    public function get_error():String
    {
        return backend.error();
    }
}
