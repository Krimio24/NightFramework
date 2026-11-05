package lemon;

enum abstract ProgressState(Int) from Int to Int
{
    var NoProgress = 0;
    var Indeterminate = 1;
    var Normal = 2;
    var Error = 4;
    var Paused = 8;
}
