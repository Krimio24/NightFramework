#pragma once

#ifndef LEMON_OPENAL_HPP
#define LEMON_OPENAL_HPP

#include <hxcpp.h>
#include <Windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <wrl/client.h>
#include <algorithm>
#include <climits>
#include <cstring>
#include <string>
#include <vector>

#define AL_APIENTRY __cdecl
using ALenum = int;
using ALint = int;
using ALsizei = int;
using ALuint = unsigned int;
using ALfloat = float;
using ALCboolean = char;
using ALCenum = int;
using ALCint = int;
using ALCsizei = int;
using ALCchar = char;
struct ALCdevice;
struct ALCcontext;

static constexpr ALenum AL_NO_ERROR = 0;
static constexpr ALenum AL_FORMAT_MONO8 = 0x1100;
static constexpr ALenum AL_FORMAT_MONO16 = 0x1101;
static constexpr ALenum AL_FORMAT_STEREO8 = 0x1102;
static constexpr ALenum AL_FORMAT_STEREO16 = 0x1103;
static constexpr ALenum AL_BUFFER = 0x1009;
static constexpr ALenum AL_ORIENTATION = 0x100F;
static constexpr ALenum AL_SOURCE_STATE = 0x1010;
static constexpr ALenum AL_STOPPED = 0x1014;
static constexpr ALenum AL_BUFFERS_PROCESSED = 0x1016;
static constexpr ALCboolean ALC_FALSE = 0;
static constexpr ALCboolean ALC_TRUE = 1;
static constexpr ALCenum ALC_DEVICE_SPECIFIER = 0x1005;
static constexpr ALCenum ALC_DEFAULT_DEVICE_SPECIFIER = 0x1004;

#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfreadwrite.lib")
#pragma comment(lib, "mfuuid.lib")
#pragma comment(lib, "ole32.lib")

namespace lemon
{
namespace native
{
    class OpenAL
    {
        template<typename T>
        using ComPtr = Microsoft::WRL::ComPtr<T>;

        ALCdevice* device = nullptr;
        ALCcontext* context = nullptr;
        HMODULE openalModule = nullptr;
        bool comInitialized = false;
        bool mfInitialized = false;
        ::String error;
        std::vector<std::string> devices;

        using AlcOpenDevice = ALCdevice* (AL_APIENTRY*)(const ALCchar*);
        using AlcCloseDevice = ALCboolean (AL_APIENTRY*)(ALCdevice*);
        using AlcCreateContext = ALCcontext* (AL_APIENTRY*)(ALCdevice*, const ALCint*);
        using AlcMakeContextCurrent = ALCboolean (AL_APIENTRY*)(ALCcontext*);
        using AlcGetCurrentContext = ALCcontext* (AL_APIENTRY*)();
        using AlcDestroyContext = void (AL_APIENTRY*)(ALCcontext*);
        using AlcGetString = const ALCchar* (AL_APIENTRY*)(ALCdevice*, ALCenum);
        using AlcIsExtensionPresent = ALCboolean (AL_APIENTRY*)(ALCdevice*, const ALCchar*);
        using AlGetProcAddress = void* (AL_APIENTRY*)(const char*);
        using AlGetError = ALenum (AL_APIENTRY*)();
        using AlGenBuffers = void (AL_APIENTRY*)(ALsizei, ALuint*);
        using AlDeleteBuffers = void (AL_APIENTRY*)(ALsizei, const ALuint*);
        using AlBufferData = void (AL_APIENTRY*)(ALuint, ALenum, const void*, ALsizei, ALsizei);
        using AlGenSources = void (AL_APIENTRY*)(ALsizei, ALuint*);
        using AlDeleteSources = void (AL_APIENTRY*)(ALsizei, const ALuint*);
        using AlSourcei = void (AL_APIENTRY*)(ALuint, ALenum, ALint);
        using AlSourcef = void (AL_APIENTRY*)(ALuint, ALenum, ALfloat);
        using AlSource3f = void (AL_APIENTRY*)(ALuint, ALenum, ALfloat, ALfloat, ALfloat);
        using AlSource3i = void (AL_APIENTRY*)(ALuint, ALenum, ALint, ALint, ALint);
        using AlGetSourcei = void (AL_APIENTRY*)(ALuint, ALenum, ALint*);
        using AlSourcePlay = void (AL_APIENTRY*)(ALuint);
        using AlSourcePause = void (AL_APIENTRY*)(ALuint);
        using AlSourceStop = void (AL_APIENTRY*)(ALuint);
        using AlSourceRewind = void (AL_APIENTRY*)(ALuint);
        using AlSourceQueueBuffers = void (AL_APIENTRY*)(ALuint, ALsizei, const ALuint*);
        using AlSourceUnqueueBuffers = void (AL_APIENTRY*)(ALuint, ALsizei, ALuint*);
        using AlListenerf = void (AL_APIENTRY*)(ALenum, ALfloat);
        using AlListener3f = void (AL_APIENTRY*)(ALenum, ALfloat, ALfloat, ALfloat);
        using AlListenerfv = void (AL_APIENTRY*)(ALenum, const ALfloat*);

        AlcOpenDevice alcOpenDeviceFn = nullptr;
        AlcCloseDevice alcCloseDeviceFn = nullptr;
        AlcCreateContext alcCreateContextFn = nullptr;
        AlcMakeContextCurrent alcMakeContextCurrentFn = nullptr;
        AlcGetCurrentContext alcGetCurrentContextFn = nullptr;
        AlcDestroyContext alcDestroyContextFn = nullptr;
        AlcGetString alcGetStringFn = nullptr;
        AlcIsExtensionPresent alcIsExtensionPresentFn = nullptr;
        AlGetProcAddress alGetProcAddressFn = nullptr;
        AlGetError alGetErrorFn = nullptr;
        AlGenBuffers alGenBuffersFn = nullptr;
        AlDeleteBuffers alDeleteBuffersFn = nullptr;
        AlBufferData alBufferDataFn = nullptr;
        AlGenSources alGenSourcesFn = nullptr;
        AlDeleteSources alDeleteSourcesFn = nullptr;
        AlSourcei alSourceiFn = nullptr;
        AlSourcef alSourcefFn = nullptr;
        AlSource3f alSource3fFn = nullptr;
        AlSource3i alSource3iFn = nullptr;
        AlGetSourcei alGetSourceiFn = nullptr;
        AlSourcePlay alSourcePlayFn = nullptr;
        AlSourcePause alSourcePauseFn = nullptr;
        AlSourceStop alSourceStopFn = nullptr;
        AlSourceRewind alSourceRewindFn = nullptr;
        AlSourceQueueBuffers alSourceQueueBuffersFn = nullptr;
        AlSourceUnqueueBuffers alSourceUnqueueBuffersFn = nullptr;
        AlListenerf alListenerfFn = nullptr;
        AlListener3f alListener3fFn = nullptr;
        AlListenerfv alListenerfvFn = nullptr;

        template<typename T>
        bool loadFunction(T& function, const char* name)
        {
            function = reinterpret_cast<T>(GetProcAddress(openalModule, name));
            if (function == nullptr)
            {
                error = ::String("OpenAL runtime is missing a required function.");
                return false;
            }
            return true;
        }

        bool loadFunctions()
        {
            return loadFunction(alcOpenDeviceFn, "alcOpenDevice") &&
                loadFunction(alcCloseDeviceFn, "alcCloseDevice") &&
                loadFunction(alcCreateContextFn, "alcCreateContext") &&
                loadFunction(alcMakeContextCurrentFn, "alcMakeContextCurrent") &&
                loadFunction(alcGetCurrentContextFn, "alcGetCurrentContext") &&
                loadFunction(alcDestroyContextFn, "alcDestroyContext") &&
                loadFunction(alcGetStringFn, "alcGetString") &&
                loadFunction(alcIsExtensionPresentFn, "alcIsExtensionPresent") &&
                loadFunction(alGetProcAddressFn, "alGetProcAddress") &&
                loadFunction(alGetErrorFn, "alGetError") &&
                loadFunction(alGenBuffersFn, "alGenBuffers") &&
                loadFunction(alDeleteBuffersFn, "alDeleteBuffers") &&
                loadFunction(alBufferDataFn, "alBufferData") &&
                loadFunction(alGenSourcesFn, "alGenSources") &&
                loadFunction(alDeleteSourcesFn, "alDeleteSources") &&
                loadFunction(alSourceiFn, "alSourcei") &&
                loadFunction(alSourcefFn, "alSourcef") &&
                loadFunction(alSource3fFn, "alSource3f") &&
                loadFunction(alSource3iFn, "alSource3i") &&
                loadFunction(alGetSourceiFn, "alGetSourcei") &&
                loadFunction(alSourcePlayFn, "alSourcePlay") &&
                loadFunction(alSourcePauseFn, "alSourcePause") &&
                loadFunction(alSourceStopFn, "alSourceStop") &&
                loadFunction(alSourceRewindFn, "alSourceRewind") &&
                loadFunction(alSourceQueueBuffersFn, "alSourceQueueBuffers") &&
                loadFunction(alSourceUnqueueBuffersFn, "alSourceUnqueueBuffers") &&
                loadFunction(alListenerfFn, "alListenerf") &&
                loadFunction(alListener3fFn, "alListener3f") &&
                loadFunction(alListenerfvFn, "alListenerfv");
        }

        ALenum alGetError() const { return alGetErrorFn == nullptr ? AL_NO_ERROR : alGetErrorFn(); }
        void alGenBuffers(ALsizei count, ALuint* ids) const { alGenBuffersFn(count, ids); }
        void alDeleteBuffers(ALsizei count, const ALuint* ids) const { alDeleteBuffersFn(count, ids); }
        void alBufferData(ALuint id, ALenum format, const void* data, ALsizei length, ALsizei rate) const { alBufferDataFn(id, format, data, length, rate); }
        void alGenSources(ALsizei count, ALuint* ids) const { alGenSourcesFn(count, ids); }
        void alDeleteSources(ALsizei count, const ALuint* ids) const { alDeleteSourcesFn(count, ids); }
        void alSourcei(ALuint id, ALenum parameter, ALint value) const { alSourceiFn(id, parameter, value); }
        void alSourcef(ALuint id, ALenum parameter, ALfloat value) const { alSourcefFn(id, parameter, value); }
        void alSource3f(ALuint id, ALenum parameter, ALfloat x, ALfloat y, ALfloat z) const { alSource3fFn(id, parameter, x, y, z); }
        void alSource3i(ALuint id, ALenum parameter, ALint x, ALint y, ALint z) const { alSource3iFn(id, parameter, x, y, z); }
        void alGetSourcei(ALuint id, ALenum parameter, ALint* value) const { alGetSourceiFn(id, parameter, value); }
        void alSourcePlay(ALuint id) const { alSourcePlayFn(id); }
        void alSourcePause(ALuint id) const { alSourcePauseFn(id); }
        void alSourceStop(ALuint id) const { alSourceStopFn(id); }
        void alSourceRewind(ALuint id) const { alSourceRewindFn(id); }
        void alSourceQueueBuffers(ALuint id, ALsizei count, const ALuint* buffers) const { alSourceQueueBuffersFn(id, count, buffers); }
        void alSourceUnqueueBuffers(ALuint id, ALsizei count, ALuint* buffers) const { alSourceUnqueueBuffersFn(id, count, buffers); }
        void alListenerf(ALenum parameter, ALfloat value) const { alListenerfFn(parameter, value); }
        void alListener3f(ALenum parameter, ALfloat x, ALfloat y, ALfloat z) const { alListener3fFn(parameter, x, y, z); }
        void alListenerfv(ALenum parameter, const ALfloat* values) const { alListenerfvFn(parameter, values); }

        static std::wstring toWide(const ::String& value)
        {
            if (value == null())
                return {};
            const char* utf8 = value.utf8_str();
            if (utf8 == nullptr)
                return {};
            const int length = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, nullptr, 0);
            if (length <= 0)
                return {};
            std::wstring result(length, wchar_t{});
            MultiByteToWideChar(CP_UTF8, 0, utf8, -1, &result[0], length);
            result.pop_back();
            return result;
        }

        static bool decodeFile(const std::wstring& path, std::vector<unsigned char>& pcm,
            int& channels, int& sampleRate)
        {
            HRESULT comResult = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
            const bool initializedCom = SUCCEEDED(comResult);
            if (FAILED(comResult) && comResult != RPC_E_CHANGED_MODE)
                return false;

            HRESULT result = MFStartup(MF_VERSION);
            if (FAILED(result))
            {
                if (initializedCom)
                    CoUninitialize();
                return false;
            }

            ComPtr<IMFSourceReader> reader;
            ComPtr<IMFMediaType> outputType;
            result = MFCreateSourceReaderFromURL(path.c_str(), nullptr, reader.GetAddressOf());
            if (SUCCEEDED(result))
                result = reader->SetStreamSelection(MF_SOURCE_READER_ALL_STREAMS, FALSE);
            if (SUCCEEDED(result))
                result = reader->SetStreamSelection(MF_SOURCE_READER_FIRST_AUDIO_STREAM, TRUE);
            if (SUCCEEDED(result))
                result = MFCreateMediaType(outputType.GetAddressOf());
            if (SUCCEEDED(result))
                result = outputType->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
            if (SUCCEEDED(result))
                result = outputType->SetGUID(MF_MT_SUBTYPE, MFAudioFormat_PCM);
            if (SUCCEEDED(result))
                result = outputType->SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, 16);
            if (SUCCEEDED(result))
                result = reader->SetCurrentMediaType(
                    MF_SOURCE_READER_FIRST_AUDIO_STREAM, nullptr, outputType.Get()
                );

            ComPtr<IMFMediaType> actualType;
            if (SUCCEEDED(result))
                result = reader->GetCurrentMediaType(
                    MF_SOURCE_READER_FIRST_AUDIO_STREAM, actualType.GetAddressOf()
                );
            UINT32 actualChannels = 0;
            UINT32 actualRate = 0;
            if (SUCCEEDED(result))
                result = actualType->GetUINT32(MF_MT_AUDIO_NUM_CHANNELS, &actualChannels);
            if (SUCCEEDED(result))
                result = actualType->GetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, &actualRate);

            pcm.clear();
            while (SUCCEEDED(result))
            {
                DWORD streamIndex = 0;
                DWORD flags = 0;
                LONGLONG timestamp = 0;
                ComPtr<IMFSample> sample;
                result = reader->ReadSample(
                    MF_SOURCE_READER_FIRST_AUDIO_STREAM,
                    0,
                    &streamIndex,
                    &flags,
                    &timestamp,
                    sample.GetAddressOf()
                );
                if (FAILED(result) || (flags & MF_SOURCE_READERF_ENDOFSTREAM) != 0)
                    break;
                if (sample == nullptr)
                    continue;

                ComPtr<IMFMediaBuffer> buffer;
                result = sample->ConvertToContiguousBuffer(buffer.GetAddressOf());
                if (FAILED(result))
                    break;
                BYTE* data = nullptr;
                DWORD maximumLength = 0;
                DWORD currentLength = 0;
                result = buffer->Lock(&data, &maximumLength, &currentLength);
                if (FAILED(result))
                    break;
                if (currentLength > static_cast<DWORD>(INT_MAX) ||
                    pcm.size() > static_cast<size_t>(INT_MAX) - currentLength)
                    result = E_OUTOFMEMORY;
                else
                    pcm.insert(pcm.end(), data, data + currentLength);
                buffer->Unlock();
                if (FAILED(result))
                    break;
            }

            reader.Reset();
            outputType.Reset();
            MFShutdown();
            if (initializedCom)
                CoUninitialize();
            if (FAILED(result) || pcm.empty() || (actualChannels != 1 && actualChannels != 2) ||
                actualRate == 0)
            {
                pcm.clear();
                return false;
            }
            channels = static_cast<int>(actualChannels);
            sampleRate = static_cast<int>(actualRate);
            return true;
        }

        bool ready()
        {
            if (context == nullptr || alcGetCurrentContextFn == nullptr ||
                alcGetCurrentContextFn() != context)
            {
                error = ::String("OpenAL context is not open or current.");
                return false;
            }
            return true;
        }

        bool checkAL(const char* operation)
        {
            const ALenum code = alGetError();
            if (code == AL_NO_ERROR)
                return true;
            error = ::String(operation);
            return false;
        }

        template<typename T>
        T extension(const char* name) const
        {
            return alGetProcAddressFn == nullptr
                ? nullptr
                : reinterpret_cast<T>(alGetProcAddressFn(name));
        }

    public:
        OpenAL() = default;

        ~OpenAL()
        {
            close();
        }

        OpenAL* operator->() { return this; }
        const OpenAL* operator->() const { return this; }

        bool open(const ::String& deviceName)
        {
            close();
            openalModule = LoadLibraryW(L"OpenAL32.dll");
            if (openalModule == nullptr)
            {
                error = ::String("OpenAL32.dll was not found. Install OpenAL Soft or place its runtime DLL on the application path.");
                return false;
            }
            if (!loadFunctions())
            {
                close();
                return false;
            }

            HRESULT result = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
            comInitialized = SUCCEEDED(result);
            if (FAILED(result) && result != RPC_E_CHANGED_MODE)
            {
                error = ::String("Could not initialize COM for Media Foundation.");
                close();
                return false;
            }
            if (FAILED(MFStartup(MF_VERSION)))
            {
                error = ::String("Could not initialize Media Foundation audio decoding.");
                close();
                return false;
            }
            mfInitialized = true;

            const std::string utf8Name = deviceName == null() ? "" : deviceName.utf8_str();
            device = alcOpenDeviceFn(utf8Name.empty() ? nullptr : utf8Name.c_str());
            if (device == nullptr)
            {
                error = ::String("OpenAL could not open the requested playback device.");
                close();
                return false;
            }
            context = alcCreateContextFn(device, nullptr);
            if (context == nullptr || alcMakeContextCurrentFn(context) == ALC_FALSE)
            {
                error = ::String("OpenAL could not create or activate a context.");
                close();
                return false;
            }
            error = ::String("");
            return true;
        }

        void close()
        {
            if (context != nullptr)
            {
                if (alcGetCurrentContextFn != nullptr && alcGetCurrentContextFn() == context)
                    alcMakeContextCurrentFn(nullptr);
                if (alcDestroyContextFn != nullptr)
                    alcDestroyContextFn(context);
                context = nullptr;
            }
            if (device != nullptr)
            {
                if (alcCloseDeviceFn != nullptr)
                    alcCloseDeviceFn(device);
                device = nullptr;
            }
            if (mfInitialized)
            {
                MFShutdown();
                mfInitialized = false;
            }
            if (comInitialized)
            {
                CoUninitialize();
                comInitialized = false;
            }
            if (openalModule != nullptr)
            {
                FreeLibrary(openalModule);
                openalModule = nullptr;
            }
        }

        bool isOpen() const { return context != nullptr; }
        ::String lastError() const { return error; }

        int deviceCount()
        {
            devices.clear();
            const ALCchar* list = nullptr;
            if (openalModule == nullptr)
                return 0;
            if (alcIsExtensionPresentFn(nullptr, "ALC_ENUMERATE_ALL_EXT") == ALC_TRUE)
                list = alcGetStringFn(nullptr, 0x1013);
            else if (alcIsExtensionPresentFn(nullptr, "ALC_ENUMERATION_EXT") == ALC_TRUE)
                list = alcGetStringFn(nullptr, ALC_DEVICE_SPECIFIER);
            else
            {
                list = alcGetStringFn(nullptr, ALC_DEFAULT_DEVICE_SPECIFIER);
                if (list != nullptr)
                    devices.emplace_back(list);
                return static_cast<int>(devices.size());
            }
            if (list == nullptr)
                return 0;
            for (const ALCchar* current = list; *current != '\0'; current += strlen(current) + 1)
                devices.emplace_back(current);
            return static_cast<int>(devices.size());
        }

        ::String deviceName(int index) const
        {
            return index < 0 || static_cast<size_t>(index) >= devices.size()
                ? ::String("")
                : ::String(devices[static_cast<size_t>(index)].c_str());
        }

        int loadBuffer(const ::String& path)
        {
            if (!ready())
                return -1;
            const std::wstring widePath = toWide(path);
            std::vector<unsigned char> pcm;
            int channels = 0;
            int sampleRate = 0;
            if (widePath.empty() || !decodeFile(widePath, pcm, channels, sampleRate))
            {
                error = ::String("Media Foundation could not decode this audio file. Check its codec and extension support.");
                return -1;
            }

            ALuint buffer = 0;
            alGenBuffers(1, &buffer);
            const ALenum format = channels == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16;
            alBufferData(buffer, format, pcm.data(), static_cast<ALsizei>(pcm.size()), sampleRate);
            if (!checkAL("OpenAL failed to create an audio buffer."))
            {
                if (buffer != 0)
                    alDeleteBuffers(1, &buffer);
                return -1;
            }
            error = ::String("");
            return static_cast<int>(buffer);
        }

        int loadBufferFromPCM(const ::Array<unsigned char>& bytes, int length,
            int channels, int bitsPerSample, int sampleRate)
        {
            if (!ready() || bytes == null() || length <= 0 ||
                static_cast<size_t>(length) > bytes->size() ||
                (channels != 1 && channels != 2) ||
                (bitsPerSample != 8 && bitsPerSample != 16) || sampleRate <= 0 ||
                static_cast<size_t>(length) > static_cast<size_t>(INT_MAX))
            {
                error = ::String("Invalid PCM audio buffer parameters.");
                return -1;
            }
            const char* data = bytes->GetBase();
            if (data == nullptr)
            {
                error = ::String("PCM audio data is empty.");
                return -1;
            }
            const ALenum format = channels == 1
                ? (bitsPerSample == 8 ? AL_FORMAT_MONO8 : AL_FORMAT_MONO16)
                : (bitsPerSample == 8 ? AL_FORMAT_STEREO8 : AL_FORMAT_STEREO16);
            ALuint buffer = 0;
            alGenBuffers(1, &buffer);
            alBufferData(buffer, format, data, length, sampleRate);
            if (!checkAL("OpenAL failed to upload PCM data."))
            {
                if (buffer != 0)
                    alDeleteBuffers(1, &buffer);
                return -1;
            }
            return static_cast<int>(buffer);
        }

        void deleteBuffer(int buffer)
        {
            if (ready() && buffer > 0)
            {
                const ALuint id = static_cast<ALuint>(buffer);
                alDeleteBuffers(1, &id);
                checkAL("OpenAL failed to delete an audio buffer.");
            }
        }

        int createSource()
        {
            if (!ready())
                return -1;
            ALuint source = 0;
            alGenSources(1, &source);
            if (!checkAL("OpenAL failed to create an audio source."))
                return -1;
            return static_cast<int>(source);
        }

        void deleteSource(int source)
        {
            if (ready() && source > 0)
            {
                const ALuint id = static_cast<ALuint>(source);
                alDeleteSources(1, &id);
                checkAL("OpenAL failed to delete an audio source.");
            }
        }

        bool bindBuffer(int source, int buffer)
        {
            if (!ready())
                return false;
            alSourcei(static_cast<ALuint>(source), AL_BUFFER, buffer);
            return checkAL("OpenAL failed to attach the buffer to the source.");
        }

        bool sourcePlay(int source) { if (!ready()) return false; alSourcePlay(static_cast<ALuint>(source)); return checkAL("OpenAL source play failed."); }
        bool sourcePause(int source) { if (!ready()) return false; alSourcePause(static_cast<ALuint>(source)); return checkAL("OpenAL source pause failed."); }
        bool sourceStop(int source) { if (!ready()) return false; alSourceStop(static_cast<ALuint>(source)); return checkAL("OpenAL source stop failed."); }
        bool sourceRewind(int source) { if (!ready()) return false; alSourceRewind(static_cast<ALuint>(source)); return checkAL("OpenAL source rewind failed."); }

        int sourceState(int source)
        {
            if (!ready())
                return AL_STOPPED;
            ALint state = AL_STOPPED;
            alGetSourcei(static_cast<ALuint>(source), AL_SOURCE_STATE, &state);
            checkAL("Could not query OpenAL source state.");
            return state;
        }

        bool setSourcef(int source, int parameter, float value)
        {
            if (!ready()) return false;
            alSourcef(static_cast<ALuint>(source), parameter, value);
            return checkAL("Could not set an OpenAL source property.");
        }

        bool setSource3f(int source, int parameter, float x, float y, float z)
        {
            if (!ready()) return false;
            alSource3f(static_cast<ALuint>(source), parameter, x, y, z);
            return checkAL("Could not set an OpenAL source vector property.");
        }

        bool setSourcei(int source, int parameter, int value)
        {
            if (!ready()) return false;
            alSourcei(static_cast<ALuint>(source), parameter, value);
            return checkAL("Could not set an OpenAL source integer property.");
        }

        bool queueBuffer(int source, int buffer)
        {
            if (!ready()) return false;
            const ALuint id = static_cast<ALuint>(buffer);
            alSourceQueueBuffers(static_cast<ALuint>(source), 1, &id);
            return checkAL("Could not queue an OpenAL streaming buffer.");
        }

        int unqueueProcessed(int source)
        {
            if (!ready()) return -1;
            ALint processed = 0;
            alGetSourcei(static_cast<ALuint>(source), AL_BUFFERS_PROCESSED, &processed);
            if (!checkAL("Could not query processed OpenAL buffers.") || processed <= 0)
                return 0;
            ALuint buffer = 0;
            alSourceUnqueueBuffers(static_cast<ALuint>(source), 1, &buffer);
            return checkAL("Could not unqueue a processed OpenAL buffer.")
                ? static_cast<int>(buffer)
                : -1;
        }

        bool setListener3f(int parameter, float x, float y, float z)
        {
            if (!ready()) return false;
            alListener3f(parameter, x, y, z);
            return checkAL("Could not set an OpenAL listener property.");
        }

        bool setListenerf(int parameter, float value)
        {
            if (!ready()) return false;
            alListenerf(parameter, value);
            return checkAL("Could not set OpenAL listener gain.");
        }

        bool setListenerOrientation(float atX, float atY, float atZ, float upX, float upY, float upZ)
        {
            if (!ready()) return false;
            const ALfloat orientation[] = {atX, atY, atZ, upX, upY, upZ};
            alListenerfv(AL_ORIENTATION, orientation);
            return checkAL("Could not set OpenAL listener orientation.");
        }

        bool efxSupported()
        {
            return device != nullptr && alcIsExtensionPresentFn != nullptr &&
                alcIsExtensionPresentFn(device, "ALC_EXT_EFX") == ALC_TRUE;
        }

        int createEffect(int type)
        {
            if (!ready() || !efxSupported()) return -1;
            using GenEffects = void (AL_APIENTRY*)(ALsizei, ALuint*);
            using EffectI = void (AL_APIENTRY*)(ALuint, ALenum, ALint);
            const GenEffects gen = extension<GenEffects>("alGenEffects");
            const EffectI setType = extension<EffectI>("alEffecti");
            if (gen == nullptr || setType == nullptr) return -1;
            ALuint effect = 0;
            gen(1, &effect);
            setType(effect, 0x8001, type);
            if (alGetError() != AL_NO_ERROR) return -1;
            return static_cast<int>(effect);
        }

        bool setEffectf(int effect, int parameter, float value)
        {
            using EffectF = void (AL_APIENTRY*)(ALuint, ALenum, ALfloat);
            const EffectF set = extension<EffectF>("alEffectf");
            if (!ready() || set == nullptr) return false;
            set(static_cast<ALuint>(effect), parameter, value);
            return checkAL("Could not set an OpenAL EFX effect property.");
        }

        bool setEffecti(int effect, int parameter, int value)
        {
            using EffectI = void (AL_APIENTRY*)(ALuint, ALenum, ALint);
            const EffectI set = extension<EffectI>("alEffecti");
            if (!ready() || set == nullptr) return false;
            set(static_cast<ALuint>(effect), parameter, value);
            return checkAL("Could not set an OpenAL EFX effect property.");
        }

        void deleteEffect(int effect)
        {
            using DeleteEffects = void (AL_APIENTRY*)(ALsizei, const ALuint*);
            const DeleteEffects remove = extension<DeleteEffects>("alDeleteEffects");
            if (ready() && remove != nullptr && effect > 0)
            {
                const ALuint id = static_cast<ALuint>(effect);
                remove(1, &id);
            }
        }

        int createEffectSlot()
        {
            using GenSlots = void (AL_APIENTRY*)(ALsizei, ALuint*);
            const GenSlots gen = extension<GenSlots>("alGenAuxiliaryEffectSlots");
            if (!ready() || gen == nullptr) return -1;
            ALuint slot = 0;
            gen(1, &slot);
            return alGetError() == AL_NO_ERROR ? static_cast<int>(slot) : -1;
        }

        bool setEffectSlot(int slot, int effect)
        {
            using SlotI = void (AL_APIENTRY*)(ALuint, ALenum, ALint);
            const SlotI set = extension<SlotI>("alAuxiliaryEffectSloti");
            if (!ready() || set == nullptr) return false;
            set(static_cast<ALuint>(slot), 0x0001, effect);
            return checkAL("Could not attach the effect to its auxiliary slot.");
        }

        void deleteEffectSlot(int slot)
        {
            using DeleteSlots = void (AL_APIENTRY*)(ALsizei, const ALuint*);
            const DeleteSlots remove = extension<DeleteSlots>("alDeleteAuxiliaryEffectSlots");
            if (ready() && remove != nullptr && slot > 0)
            {
                const ALuint id = static_cast<ALuint>(slot);
                remove(1, &id);
            }
        }

        bool attachEffectSlot(int source, int slot, int send)
        {
            if (!ready()) return false;
            alSource3i(static_cast<ALuint>(source), 0x20006, slot, send, 0);
            return checkAL("Could not route a source to an OpenAL EFX slot.");
        }

        int createFilter(int type)
        {
            using GenFilters = void (AL_APIENTRY*)(ALsizei, ALuint*);
            using FilterI = void (AL_APIENTRY*)(ALuint, ALenum, ALint);
            const GenFilters gen = extension<GenFilters>("alGenFilters");
            const FilterI setType = extension<FilterI>("alFilteri");
            if (!ready() || gen == nullptr || setType == nullptr) return -1;
            ALuint filter = 0;
            gen(1, &filter);
            setType(filter, 0x8001, type);
            return alGetError() == AL_NO_ERROR ? static_cast<int>(filter) : -1;
        }

        bool setFilterf(int filter, int parameter, float value)
        {
            using FilterF = void (AL_APIENTRY*)(ALuint, ALenum, ALfloat);
            const FilterF set = extension<FilterF>("alFilterf");
            if (!ready() || set == nullptr) return false;
            set(static_cast<ALuint>(filter), parameter, value);
            return checkAL("Could not set an OpenAL EFX filter property.");
        }

        bool setFilteri(int filter, int parameter, int value)
        {
            using FilterI = void (AL_APIENTRY*)(ALuint, ALenum, ALint);
            const FilterI set = extension<FilterI>("alFilteri");
            if (!ready() || set == nullptr) return false;
            set(static_cast<ALuint>(filter), parameter, value);
            return checkAL("Could not set an OpenAL EFX filter property.");
        }

        void deleteFilter(int filter)
        {
            using DeleteFilters = void (AL_APIENTRY*)(ALsizei, const ALuint*);
            const DeleteFilters remove = extension<DeleteFilters>("alDeleteFilters");
            if (ready() && remove != nullptr && filter > 0)
            {
                const ALuint id = static_cast<ALuint>(filter);
                remove(1, &id);
            }
        }

        bool setSourceFilter(int source, int filter)
        {
            if (!ready()) return false;
            alSourcei(static_cast<ALuint>(source), 0x20005, filter);
            return checkAL("Could not apply an OpenAL EFX filter to the source.");
        }
    };
}
}

#endif
