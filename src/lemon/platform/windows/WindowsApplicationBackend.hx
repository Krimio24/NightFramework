package lemon.platform.windows;

import lemon.Place;

class WindowsApplicationBackend
{
    private var place:Place;
    private var lastError:String = "";

    public function new(place:Place)
    {
        this.place = place;
    }

    public function setProgress(state:Int, value:Int, maximum:Int):Bool
    {
        if (place == null || place.isDisposed())
            return fail("The application window is unavailable.");
        if (!place._setTaskbarProgress(state, value, maximum))
            return fail("Windows could not update the taskbar progress indicator.");
        lastError = "";
        return true;
    }

    public function notify(title:String, message:String):Bool
    {
        if (place == null || place.isDisposed())
            return fail("The application window is unavailable.");
        if (title == null || message == null)
            return fail("Notification title and message must not be null.");
        if (!place._showNotification(title, message))
            return fail("Windows could not display the notification.");
        lastError = "";
        return true;
    }

    public function notifyTray(title:String, message:String):Bool
    {
        if (place == null || place.isDisposed())
            return fail("The application window is unavailable.");
        if (title == null || message == null)
            return fail("Tray notification title and message must not be null.");
        if (!place._showTrayNotification(title, message))
            return fail("Windows could not display the tray notification.");
        lastError = "";
        return true;
    }

    public function hideTray():Void
    {
        if (place != null && !place.isDisposed())
            place._hideTrayNotification();
    }

    public function error():String
    {
        return lastError;
    }

    private function fail(message:String):Bool
    {
        lastError = message;
        return false;
    }
}
