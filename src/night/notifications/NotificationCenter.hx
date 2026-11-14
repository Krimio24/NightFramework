package lemon.notifications;

import lemon.platform.windows.WindowsApplicationBackend;

class NotificationCenter
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
        return backend.notify(title, message);
    }

    public function get_error():String
    {
        return backend.error();
    }
}
