package lemon.platform.android;

import lemon.platform.android.extern.GLES20;
import lemon.platform.android.extern.GLByteBuffer;
import lemon.platform.android.extern.GLByteOrder;
import lemon.platform.android.extern.GLFloatBuffer;
import lemon.platform.android.extern.GLBuffer;
import lemon.graphics.GraphicsContext;
import java.NativeArray;

class GLGraphics implements GraphicsContext
{
    private static inline var GL_COLOR_BUFFER_BIT:Int = 0x4000;
    private static inline var GL_BLEND:Int = 0x0BE2;
    private static inline var GL_SRC_ALPHA:Int = 0x0302;
    private static inline var GL_ONE_MINUS_SRC_ALPHA:Int = 0x0303;
    private static inline var GL_VERTEX_SHADER:Int = 0x8B31;
    private static inline var GL_FRAGMENT_SHADER:Int = 0x8B30;
    private static inline var GL_COMPILE_STATUS:Int = 0x8B81;
    private static inline var GL_LINK_STATUS:Int = 0x8B82;
    private static inline var GL_FLOAT:Int = 0x1406;
    private static inline var GL_TRIANGLES:Int = 0x0004;
    private static inline var GL_TRIANGLE_FAN:Int = 0x0006;
    private static inline var GL_LINE_LOOP:Int = 0x0002;
    private static inline var GL_LINES:Int = 0x0001;
    private static inline var MAX_VERTICES:Int = 64;

    private static inline var VERTEX_SHADER_SOURCE:String =
        "attribute vec2 aPosition;" +
        "uniform vec2 uResolution;" +
        "void main() {" +
        "  vec2 clip = (aPosition / uResolution) * 2.0 - 1.0;" +
        "  gl_Position = vec4(clip.x, -clip.y, 0.0, 1.0);" +
        "}";

    private static inline var FRAGMENT_SHADER_SOURCE:String =
        "precision mediump float;" +
        "uniform vec4 uColor;" +
        "void main() { gl_FragColor = uColor; }";

    private var program:Int = 0;
    private var positionAttribute:Int = -1;
    private var resolutionUniform:Int = -1;
    private var colorUniform:Int = -1;
    private var vertices:GLFloatBuffer;
    public var width(default, null):Int = 0;
    public var height(default, null):Int = 0;

    public function new()
    {
    }

    public function initialize():Void
    {
        GLES20.glEnable(GL_BLEND);
        GLES20.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        var vertexShader = compileShader(GL_VERTEX_SHADER, VERTEX_SHADER_SOURCE);
        var fragmentShader = compileShader(GL_FRAGMENT_SHADER, FRAGMENT_SHADER_SOURCE);
        program = GLES20.glCreateProgram();
        if (program == 0)
            throw "OpenGL ES could not create the Lemon shape program.";

        GLES20.glAttachShader(program, vertexShader);
        GLES20.glAttachShader(program, fragmentShader);
        GLES20.glLinkProgram(program);
        var linkStatus = new NativeArray<Int>(1);
        GLES20.glGetProgramiv(program, GL_LINK_STATUS, linkStatus, 0);
        if (linkStatus[0] == 0)
            throw 'OpenGL ES could not link the Lemon shape program: ${GLES20.glGetProgramInfoLog(program)}';

        GLES20.glDeleteShader(vertexShader);
        GLES20.glDeleteShader(fragmentShader);
        positionAttribute = GLES20.glGetAttribLocation(program, "aPosition");
        resolutionUniform = GLES20.glGetUniformLocation(program, "uResolution");
        colorUniform = GLES20.glGetUniformLocation(program, "uColor");
        if (positionAttribute < 0 || resolutionUniform < 0 || colorUniform < 0)
            throw "OpenGL ES did not expose the Lemon shape shader inputs.";

        var byteBuffer = GLByteBuffer.allocateDirect(MAX_VERTICES * 2 * 4);
        vertices = byteBuffer.order(GLByteOrder.nativeOrder()).asFloatBuffer();
    }

    public function resize(width:Int, height:Int):Void
    {
        this.width = width;
        this.height = height;
        GLES20.glViewport(0, 0, width, height);
    }

    public function clear(red:Int = 0, green:Int = 0, blue:Int = 0, alpha:Int = 255):Void
    {
        GLES20.glClearColor(channel(red), channel(green), channel(blue), channel(alpha));
        GLES20.glClear(GL_COLOR_BUFFER_BIT);
    }

    public function fillRect(x:Float, y:Float, width:Float, height:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255):Void
    {
        draw([
            x, y, x + width, y, x + width, y + height,
            x, y, x + width, y + height, x, y + height
        ], GL_TRIANGLES, red, green, blue, alpha);
    }

    public function drawRect(x:Float, y:Float, width:Float, height:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255):Void
    {
        draw([
            x, y, x + width, y, x + width, y + height, x, y + height
        ], GL_LINE_LOOP, red, green, blue, alpha);
    }

    public function fillTriangle(x1:Float, y1:Float, x2:Float, y2:Float,
        x3:Float, y3:Float, red:Int, green:Int, blue:Int, alpha:Int = 255):Void
    {
        draw([x1, y1, x2, y2, x3, y3], GL_TRIANGLES, red, green, blue, alpha);
    }

    public function fillCircle(x:Float, y:Float, radius:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255, segments:Int = 32):Void
    {
        var count = validSegmentCount(segments);
        var points:Array<Float> = [x, y];
        for (index in 0...(count + 1))
        {
            var angle = Math.PI * 2 * index / count;
            points.push(x + Math.cos(angle) * radius);
            points.push(y + Math.sin(angle) * radius);
        }
        draw(points, GL_TRIANGLE_FAN, red, green, blue, alpha);
    }

    public function drawCircle(x:Float, y:Float, radius:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255, segments:Int = 32):Void
    {
        var count = validSegmentCount(segments);
        var points:Array<Float> = [];
        for (index in 0...count)
        {
            var angle = Math.PI * 2 * index / count;
            points.push(x + Math.cos(angle) * radius);
            points.push(y + Math.sin(angle) * radius);
        }
        draw(points, GL_LINE_LOOP, red, green, blue, alpha);
    }

    public function fillOval(x:Float, y:Float, width:Float, height:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255, segments:Int = 32):Void
    {
        var count = validSegmentCount(segments);
        var centerX = x + width * 0.5;
        var centerY = y + height * 0.5;
        var points:Array<Float> = [centerX, centerY];
        for (index in 0...(count + 1))
        {
            var angle = Math.PI * 2 * index / count;
            points.push(centerX + Math.cos(angle) * width * 0.5);
            points.push(centerY + Math.sin(angle) * height * 0.5);
        }
        draw(points, GL_TRIANGLE_FAN, red, green, blue, alpha);
    }

    public function drawLine(x1:Float, y1:Float, x2:Float, y2:Float,
        red:Int, green:Int, blue:Int, alpha:Int = 255):Void
    {
        draw([x1, y1, x2, y2], GL_LINES, red, green, blue, alpha);
    }

    private function draw(points:Array<Float>, mode:Int,
        red:Int, green:Int, blue:Int, alpha:Int):Void
    {
        if (program == 0 || vertices == null || width <= 0 || height <= 0 ||
            points.length < 4 || (points.length >> 1) > MAX_VERTICES)
            return;

        vertices.position(0);
        for (index in 0...points.length)
            vertices.put(index, points[index]);

        GLES20.glUseProgram(program);
        GLES20.glUniform2f(resolutionUniform, width, height);
        GLES20.glUniform4f(colorUniform, channel(red), channel(green), channel(blue), channel(alpha));
        GLES20.glEnableVertexAttribArray(positionAttribute);
        var buffer:GLBuffer = vertices;
        GLES20.glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, false, 0, buffer);
        GLES20.glDrawArrays(mode, 0, points.length >> 1);
        GLES20.glDisableVertexAttribArray(positionAttribute);
    }

    private function compileShader(type:Int, source:String):Int
    {
        var shader = GLES20.glCreateShader(type);
        if (shader == 0)
            throw "OpenGL ES could not create a Lemon shape shader.";

        GLES20.glShaderSource(shader, source);
        GLES20.glCompileShader(shader);
        var compileStatus = new NativeArray<Int>(1);
        GLES20.glGetShaderiv(shader, GL_COMPILE_STATUS, compileStatus, 0);
        if (compileStatus[0] == 0)
        {
            var error = GLES20.glGetShaderInfoLog(shader);
            GLES20.glDeleteShader(shader);
            throw 'OpenGL ES could not compile a Lemon shape shader: $error';
        }
        return shader;
    }

    private static function validSegmentCount(segments:Int):Int
    {
        return segments < 3 ? 3 : segments > 62 ? 62 : segments;
    }

    private static function channel(value:Int):Single
    {
        return Math.max(0, Math.min(value, 255)) / 255;
    }
}
