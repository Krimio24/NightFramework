#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#else
#include <cerrno>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

namespace fs = std::filesystem;

namespace
{
    struct ProjectFile
    {
        fs::path source;
        fs::path destination;
    };

    std::wstring utf8ToWide(const std::string& value)
    {
        if (value.empty())
            return {};
        int size = MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, nullptr, 0);
        if (size <= 0)
            return {};
        std::wstring result(static_cast<size_t>(size), L'\0');
        MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, result.data(), size);
        result.pop_back();
        return result;
    }

    std::wstring quoteWindowsArgument(const std::wstring& argument)
    {
        std::wstring result = L"\"";
        size_t backslashes = 0;
        for (wchar_t character : argument)
        {
            if (character == L'\\')
            {
                ++backslashes;
            }
            else if (character == L'"')
            {
                result.append(backslashes * 2 + 1, L'\\');
                result.push_back(L'"');
                backslashes = 0;
            }
            else
            {
                result.append(backslashes, L'\\');
                backslashes = 0;
                result.push_back(character);
            }
        }
        result.append(backslashes * 2, L'\\');
        result.push_back(L'"');
        return result;
    }

    int runProcess(const std::vector<std::string>& arguments, const fs::path& workingDirectory)
    {
        if (arguments.empty())
            return 1;

#ifdef _WIN32
        std::wstring commandLine;
        std::wstring application;
        const std::string& executable = arguments.front();
        const bool isBatchFile = executable.size() >= 4 &&
            executable.substr(executable.size() - 4) == ".bat";
        if (isBatchFile)
        {
            wchar_t comspecBuffer[MAX_PATH]{};
            DWORD length = GetEnvironmentVariableW(L"COMSPEC", comspecBuffer, MAX_PATH);
            application = length > 0 && length < MAX_PATH ? comspecBuffer : L"cmd.exe";
            commandLine = quoteWindowsArgument(application) + L" /d /s /c \"\"";
            commandLine += utf8ToWide(executable);
            commandLine += L"\"";
            for (size_t index = 1; index < arguments.size(); ++index)
            {
                commandLine.push_back(L' ');
                commandLine += quoteWindowsArgument(utf8ToWide(arguments[index]));
            }
            commandLine.push_back(L'"');
        }
        else
        {
            application.clear();
        }

        if (!isBatchFile)
        {
            for (const auto& argument : arguments)
            {
                if (!commandLine.empty())
                    commandLine.push_back(L' ');
                commandLine += quoteWindowsArgument(utf8ToWide(argument));
            }
        }

        STARTUPINFOW startup{};
        startup.cb = sizeof(startup);
        PROCESS_INFORMATION process{};
        const std::wstring directory = workingDirectory.wstring();
        if (!CreateProcessW(
                isBatchFile ? application.c_str() : nullptr,
                commandLine.data(),
                nullptr,
                nullptr,
                FALSE,
                0,
                nullptr,
                directory.c_str(),
                &startup,
                &process))
        {
            std::cerr << "No se pudo iniciar " << arguments.front()
                      << " (error de Windows " << GetLastError() << ").\n";
            return 1;
        }

        WaitForSingleObject(process.hProcess, INFINITE);
        DWORD exitCode = 1;
        GetExitCodeProcess(process.hProcess, &exitCode);
        CloseHandle(process.hThread);
        CloseHandle(process.hProcess);
        return static_cast<int>(exitCode);
#else
        std::vector<char*> argv;
        argv.reserve(arguments.size() + 1);
        for (const auto& argument : arguments)
            argv.push_back(const_cast<char*>(argument.c_str()));
        argv.push_back(nullptr);

        const pid_t child = fork();
        if (child < 0)
        {
            std::cerr << "No se pudo crear el proceso: " << errno << ".\n";
            return 1;
        }
        if (child == 0)
        {
            if (chdir(workingDirectory.string().c_str()) != 0)
                _exit(126);
            execvp(argv[0], argv.data());
            _exit(errno == ENOENT ? 127 : 126);
        }

        int status = 0;
        if (waitpid(child, &status, 0) < 0)
            return 1;
        return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
#endif
    }

    fs::path executablePath(const char* argumentZero)
    {
#ifdef _WIN32
        std::wstring path(32768, L'\0');
        DWORD length = GetModuleFileNameW(nullptr, path.data(), static_cast<DWORD>(path.size()));
        if (length > 0 && length < path.size())
        {
            path.resize(length);
            return fs::path(path);
        }
#endif
        return fs::absolute(fs::path(argumentZero));
    }

    void printUsage()
    {
        std::cout
            << "Night build tool\n"
            << "Uso:\n"
            << "  night create android.arm.x64 [directorio]\n"
            << "  night -m windows.x64\n"
            << "  night -m android.arm.x64\n"
            << "  haxelib run night setup\n\n"
            << "create genera un proyecto Android en el directorio indicado (o\n"
            << "en el actual). Luego ejecuta night -m android.arm.x64 desde ahi.\n"
            << "Los comandos de compilacion usan la demo incluida si no encuentran\n"
            << "un proyecto compatible en el directorio actual.\n";
    }

    bool isGeneratedDirectory(const fs::path& relativePath)
    {
        for (const auto& component : relativePath)
        {
            const std::string name = component.string();
            if (name == ".gradle" || name == "build" || name == "haxe-generated")
                return true;
        }
        return false;
    }

    bool collectProjectFiles(const fs::path& sourceRoot, const fs::path& destinationRoot,
                             std::vector<ProjectFile>& files)
    {
        if (!fs::exists(sourceRoot) || !fs::is_directory(sourceRoot))
        {
            std::cerr << "No se encontro la plantilla: " << sourceRoot.string() << "\n";
            return false;
        }

        for (auto entry = fs::recursive_directory_iterator(sourceRoot);
             entry != fs::recursive_directory_iterator(); ++entry)
        {
            const fs::path relativePath = fs::relative(entry->path(), sourceRoot);
            if (isGeneratedDirectory(relativePath))
            {
                if (entry->is_directory())
                    entry.disable_recursion_pending();
                continue;
            }
            if (!entry->is_regular_file())
                continue;
            files.push_back({entry->path(), destinationRoot / relativePath});
        }
        return true;
    }

    bool writeTextFile(const fs::path& path, const std::string& contents)
    {
        std::ofstream output(path, std::ios::binary | std::ios::trunc);
        if (!output)
        {
            std::cerr << "No se pudo escribir " << path.string() << ".\n";
            return false;
        }
        output << contents;
        if (!output)
        {
            std::cerr << "Error al guardar " << path.string() << ".\n";
            return false;
        }
        return true;
    }

    bool createAndroidProject(const fs::path& packageRoot, const fs::path& destination)
    {
        const fs::path androidTemplate = packageRoot / "demo" / "android";
        const fs::path frameworkSources = packageRoot / "src";
        const fs::path demoAssets = packageRoot / "demo" / "assets";
        std::vector<ProjectFile> files;
        if (!collectProjectFiles(androidTemplate, destination, files) ||
            !collectProjectFiles(frameworkSources, destination / "lemon" / "src", files) ||
            !collectProjectFiles(demoAssets, destination / "assets", files))
            return false;

        for (const auto& file : files)
        {
            if (fs::exists(file.destination))
            {
                std::cerr << "No se sobrescribiran archivos existentes. Ya existe: "
                          << file.destination.string() << "\n";
                return false;
            }
        }

        for (const auto& file : files)
        {
            std::error_code error;
            fs::create_directories(file.destination.parent_path(), error);
            if (error)
            {
                std::cerr << "No se pudo crear " << file.destination.parent_path().string()
                          << ": " << error.message() << "\n";
                return false;
            }
            fs::copy_file(file.source, file.destination, fs::copy_options::none, error);
            if (error)
            {
                std::cerr << "No se pudo copiar " << file.source.string() << ": "
                          << error.message() << "\n";
                return false;
            }
        }

        const std::string hxml =
            "-cp lemon/src\n"
            "-cp src\n"
            "-cp .\n"
            "-main lemon.demo.MainActivity\n"
            "-java haxe-generated\n"
            "-D no-compilation\n";
        const fs::path appGradle = destination / "app" / "build.gradle";
        std::ifstream gradleInput(appGradle, std::ios::binary);
        if (!gradleInput)
        {
            std::cerr << "No se encontro la configuracion Gradle copiada.\n";
            return false;
        }
        const std::string gradleContents((std::istreambuf_iterator<char>(gradleInput)),
                                         std::istreambuf_iterator<char>());
        const std::string oldSourcePath = "../../src";
        std::string updatedGradle = gradleContents;
        size_t position = 0;
        while ((position = updatedGradle.find(oldSourcePath, position)) != std::string::npos)
        {
            updatedGradle.replace(position, oldSourcePath.length(), "lemon/src");
            position += 9;
        }
        const std::string oldAssetPath = "../assets";
        position = 0;
        while ((position = updatedGradle.find(oldAssetPath, position)) != std::string::npos)
        {
            updatedGradle.replace(position, oldAssetPath.length(), "assets");
            position += 6;
        }

        if (!writeTextFile(destination / "build.hxml", hxml) ||
            !writeTextFile(appGradle, updatedGradle))
            return false;

        std::cout << "Proyecto Android creado en " << destination.string() << "\n"
                  << "Compilalo desde ahi con: night -m android.arm.x64\n";
        return true;
    }
}

int main(int argc, char** argv)
{
    if (argc == 1 || std::string(argv[1]) == "--help" || std::string(argv[1]) == "-h")
    {
        printUsage();
        return 0;
    }
    if (std::string(argv[1]) == "setup")
    {
        std::cerr << "Ejecuta la configuracion con: haxelib run night setup\n";
        return 2;
    }
    if (std::string(argv[1]) == "create")
    {
        if ((argc != 3 && argc != 4) || std::string(argv[2]) != "android.arm.x64")
        {
            printUsage();
            return 2;
        }
        const fs::path packageRoot = executablePath(argv[0]).parent_path().parent_path();
        const fs::path invocationDirectory = fs::current_path();
        const fs::path destination = argc == 4
            ? (fs::path(argv[3]).is_absolute() ? fs::path(argv[3]) : invocationDirectory / argv[3])
            : invocationDirectory;
        return createAndroidProject(packageRoot, destination) ? 0 : 1;
    }
    if (argc != 3 || std::string(argv[1]) != "-m")
    {
        printUsage();
        return 2;
    }

    const std::string target = argv[2];
    const fs::path packageRoot = executablePath(argv[0]).parent_path().parent_path();
    const fs::path invocationDirectory = fs::current_path();
    fs::path projectDirectory;
    std::vector<std::string> command;

    if (target == "windows.x64")
    {
        if (fs::exists(invocationDirectory / "build.hxml"))
        {
            projectDirectory = invocationDirectory;
        }
        else
        {
            projectDirectory = packageRoot / "demo";
        }
        if (!fs::exists(projectDirectory / "build.hxml"))
        {
            std::cerr << "No se encontro build.hxml en el proyecto ni en la demo de Night.\n";
            return 2;
        }
        command = {"haxe", "build.hxml"};
    }
    else if (target == "android.arm.x64")
    {
        if (fs::exists(invocationDirectory / "gradlew.bat") &&
            fs::exists(invocationDirectory / "settings.gradle"))
        {
            projectDirectory = invocationDirectory;
        }
        else
        {
            projectDirectory = packageRoot / "demo" / "android";
        }

#ifdef _WIN32
        const fs::path gradleWrapper = projectDirectory / "gradlew.bat";
        if (!fs::exists(gradleWrapper))
        {
            std::cerr << "No se encontro gradlew.bat en el proyecto ni en la demo Android de Night.\n";
            return 2;
        }
        command = {gradleWrapper.string(), "assembleDebug"};
#else
        const fs::path gradleWrapper = projectDirectory / "gradlew";
        if (!fs::exists(gradleWrapper))
        {
            std::cerr << "No se encontro gradlew en el proyecto Android.\n";
            return 2;
        }
        command = {gradleWrapper.string(), "assembleDebug"};
#endif
    }
    else
    {
        std::cerr << "Target no soportado: " << target << "\n\n";
        printUsage();
        return 2;
    }

    std::cout << "Compilando Night para " << target << "...\n";
    const int result = runProcess(command, projectDirectory);
    if (result != 0)
    {
        std::cerr << "La compilacion fallo con codigo " << result << ".\n";
        return result;
    }

    if (target == "android.arm.x64")
    {
        std::cout << "APK: "
                  << (projectDirectory / "app" / "build" / "outputs" / "apk" / "debug" / "app-debug.apk")
                         .string()
                  << "\n";
    }
    else
    {
        std::cout << "Compilacion Windows terminada.\n";
    }
    return 0;
}
