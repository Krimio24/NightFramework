package lemon.graphics.atlas;

import haxe.xml.Access;
import haxe.io.Path;
import sys.io.File;

class TextureAtlas
{
    public var imagePath(default, null):String;
    public var frames(default, null):Map<String, SparrowFrame>;

    public function new()
    {
        imagePath = "";
        frames = new Map<String, SparrowFrame>();
    }

    public static function load(path:String):TextureAtlas
    {
        if (path == null || path.length == 0)
            throw "Atlas path cannot be empty";
        return parse(File.getContent(path), Path.directory(path));
    }

    public static function parse(xmlText:String, basePath:String = ""):TextureAtlas
    {
        if (xmlText == null || xmlText.length == 0)
            throw "Atlas XML cannot be empty";

        var root = new Access(Xml.parse(xmlText).firstElement());
        if (root.name != "TextureAtlas")
            throw "Expected a Sparrow TextureAtlas document";

        var atlas = new TextureAtlas();
        var image = root.att.get("imagePath");
        if (image != null)
            atlas.imagePath = basePath.length > 0 ? Path.join([basePath, image]) : image;

        for (node in root.elements)
        {
            if (node.name != "SubTexture")
                continue;

            var name = node.att.get("name");
            if (name == null || name.length == 0)
                throw "Sparrow SubTexture is missing its name";

            var x = integer(node, "x");
            var y = integer(node, "y");
            var width = integer(node, "width");
            var height = integer(node, "height");
            if (width <= 0 || height <= 0)
                throw 'Invalid dimensions for Sparrow frame "$name"';

            var frame = new SparrowFrame(name, x, y, width, height,
                optionalInteger(node, "frameX"),
                optionalInteger(node, "frameY"),
                optionalInteger(node, "frameWidth"),
                optionalInteger(node, "frameHeight"));

            if (atlas.frames.exists(name))
                throw 'Duplicate Sparrow frame "$name"';
            atlas.frames.set(name, frame);
        }

        return atlas;
    }

    public function get(name:String):Null<SparrowFrame>
    {
        return frames.get(name);
    }

    public function exists(name:String):Bool
    {
        return frames.exists(name);
    }

    public function getPrefix(prefix:String):Array<SparrowFrame>
    {
        if (prefix == null || prefix.length == 0)
            return [];

        var result:Array<SparrowFrame> = [];
        for (name in frames.keys())
        {
            if (StringTools.startsWith(name, prefix))
                result.push(frames.get(name));
        }
        result.sort(function(a, b) return Reflect.compare(a.name, b.name));
        return result;
    }

    public function count():Int
    {
        var total = 0;
        for (_ in frames)
            total++;
        return total;
    }

    private static function integer(node:Access, name:String):Int
    {
        var value = node.att.get(name);
        if (value == null)
            throw 'Sparrow frame is missing "$name"';
        var parsed = Std.parseInt(value);
        if (parsed == null)
            throw 'Invalid integer "$name" in Sparrow frame';
        return parsed;
    }

    private static function optionalInteger(node:Access, name:String):Int
    {
        var value = node.att.get(name);
        if (value == null)
            return 0;
        var parsed = Std.parseInt(value);
        if (parsed == null)
            throw 'Invalid integer "$name" in Sparrow frame';
        return parsed;
    }
}
