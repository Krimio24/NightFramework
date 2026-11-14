package lemon.platform.android.extern;

import java.NativeArray;

@:native("android.opengl.GLES20")
extern class GLES20
{
    public static function glClearColor(red:Single, green:Single, blue:Single, alpha:Single):Void;
    public static function glClear(mask:Int):Void;
    public static function glViewport(x:Int, y:Int, width:Int, height:Int):Void;
    public static function glEnable(capability:Int):Void;
    public static function glBlendFunc(source:Int, destination:Int):Void;

    public static function glCreateShader(type:Int):Int;
    public static function glShaderSource(shader:Int, source:String):Void;
    public static function glCompileShader(shader:Int):Void;
    public static function glGetShaderiv(shader:Int, pname:Int, params:NativeArray<Int>, offset:Int):Void;
    public static function glGetShaderInfoLog(shader:Int):String;
    public static function glDeleteShader(shader:Int):Void;
    public static function glCreateProgram():Int;
    public static function glAttachShader(program:Int, shader:Int):Void;
    public static function glLinkProgram(program:Int):Void;
    public static function glGetProgramiv(program:Int, pname:Int, params:NativeArray<Int>, offset:Int):Void;
    public static function glGetProgramInfoLog(program:Int):String;
    public static function glDeleteProgram(program:Int):Void;
    public static function glUseProgram(program:Int):Void;
    public static function glGetAttribLocation(program:Int, name:String):Int;
    public static function glGetUniformLocation(program:Int, name:String):Int;
    public static function glEnableVertexAttribArray(index:Int):Void;
    public static function glDisableVertexAttribArray(index:Int):Void;
    public static function glVertexAttribPointer(index:Int, size:Int, type:Int, normalized:Bool,
        stride:Int, pointer:GLBuffer):Void;
    public static function glUniform2f(location:Int, x:Single, y:Single):Void;
    public static function glUniform4f(location:Int, x:Single, y:Single, z:Single, w:Single):Void;
    public static function glDrawArrays(mode:Int, first:Int, count:Int):Void;
}
