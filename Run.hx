import haxe.io.Path;
import sys.io.Process;

class Run
{
    static function main():Void
    {
        var args = Sys.args();
        if (args.length == 0)
        {
            printUsage();
            return;
        }

        var invocationDirectory = args.pop();
        var packageRoot = Sys.getCwd();
        if (invocationDirectory == null || !Path.isAbsolute(invocationDirectory))
        {
            Sys.println("No se pudo determinar la carpeta desde donde se ejecuto haxelib.");
            Sys.exit(2);
        }

        if (args.length > 0 && args[0] == "setup")
        {
            setup(packageRoot);
            return;
        }

        var executable = Path.join([
            packageRoot,
            "compiler",
            Sys.systemName() == "Windows" ? "lemon.exe" : "lemon"
        ]);
        if (!sys.FileSystem.exists(executable))
        {
            Sys.println("El compilador de Lemon aun no esta instalado.");
            Sys.println("Ejecuta: haxelib run lemon setup");
            Sys.exit(2);
        }

        Sys.setCwd(invocationDirectory);
        Sys.exit(Sys.command(executable, args));
    }

    static function setup(packageRoot:String):Void
    {
        Sys.println("Configurando Lemon...");
        ensureHaxelib("hxcpp");
        ensureHaxelib("hxjava");

        var executable = Path.join([
            packageRoot,
            "compiler",
            Sys.systemName() == "Windows" ? "lemon.exe" : "lemon"
        ]);
        var source = Path.join([packageRoot, "compiler", "main.cpp"]);
        var compilerArgs = ["-std=c++17", "-O2", "-static", source, "-o", executable];
        var exitCode = Sys.command("g++", compilerArgs);
        if (exitCode != 0)
        {
            Sys.println("No se pudo compilar el CLI C++. Comprueba que g++ este instalado y disponible en PATH.");
            Sys.exit(exitCode);
        }
        if (!sys.FileSystem.exists(executable))
        {
            Sys.println("g++ termino sin error, pero no se genero el ejecutable de Lemon.");
            Sys.exit(1);
        }

        Sys.println('Lemon quedo configurado: $executable');
        Sys.println("Targets: windows.x64, android.arm.x64");
    }

    static function ensureHaxelib(name:String):Void
    {
        var check = new Process("haxelib", ["path", name]);
        var output = check.stdout.readAll().toString();
        var errors = check.stderr.readAll().toString();
        var result = check.exitCode();
        check.close();
        if (result == 0)
        {
            Sys.println('$name ya esta instalado.');
            return;
        }
        if (output.length > 0)
            Sys.print(output);
        if (errors.length > 0)
            Sys.print(errors);

        Sys.println('Instalando $name...');
        var install = new Process("haxelib", ["install", name]);
        var installOutput = install.stdout.readAll().toString();
        var installErrors = install.stderr.readAll().toString();
        var installResult = install.exitCode();
        install.close();
        if (installOutput.length > 0)
            Sys.print(installOutput);
        if (installErrors.length > 0)
            Sys.print(installErrors);
        if (installResult != 0)
        {
            Sys.println('No se pudo instalar $name.');
            Sys.exit(installResult);
        }
    }

    static function printUsage():Void
    {
        Sys.println("Uso: haxelib run lemon setup");
        Sys.println("Luego: lemon create android.arm.x64 [directorio]");
        Sys.println("Compila desde el proyecto creado: lemon -m android.arm.x64");
    }
}
