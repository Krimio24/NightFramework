package lemon;

import lemon.platform.windows.WindowsApplicationBackend;

class TaskbarProgressBar
{
    private var backend:WindowsApplicationBackend;
    private var currentValue:Int = 0;
    private var currentMaximum:Int = 100;
    private var lastError:String = "";

    @:allow(lemon.Application)
    private function new(backend:WindowsApplicationBackend)
    {
        this.backend = backend;
    }

    public var error(get, never):String;
    public var value(get, never):Int;
    public var maximum(get, never):Int;

    public function setProgress(value:Int, maximum:Int = 100):Bool
    {
        if (maximum <= 0 || value < 0 || value > maximum)
        {
            lastError = "Progress value must be between zero and a positive maximum.";
            return false;
        }
        if (!backend.setProgress(ProgressState.Normal, value, maximum))
        {
            lastError = backend.error();
            return false;
        }
        currentValue = value;
        currentMaximum = maximum;
        lastError = "";
        return true;
    }

    public function setIndeterminate():Bool
    {
        return applyState(ProgressState.Indeterminate, 0, 1);
    }

    public function setPaused():Bool
    {
        return applyState(ProgressState.Paused, currentValue, currentMaximum);
    }

    public function setError():Bool
    {
        return applyState(ProgressState.Error, currentValue, currentMaximum);
    }

    public function clear():Bool
    {
        return applyState(ProgressState.NoProgress, 0, 1);
    }

    private function applyState(state:ProgressState, value:Int, maximum:Int):Bool
    {
        if (!backend.setProgress(state, value, maximum))
        {
            lastError = backend.error();
            return false;
        }
        lastError = "";
        return true;
    }

    public function get_error():String return lastError;
    public function get_value():Int return currentValue;
    public function get_maximum():Int return currentMaximum;
}
