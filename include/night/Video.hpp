#pragma once

#ifndef LEMON_VIDEO_HPP
#define LEMON_VIDEO_HPP

#include <hxcpp.h>
#include <Windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <wrl/client.h>
#include <propvarutil.h>
#include <algorithm>
#include <cmath>
#include <climits>
#include <cstddef>
#include <cstring>
#include <cstdint>
#include <vector>

#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfreadwrite.lib")
#pragma comment(lib, "mfuuid.lib")
#pragma comment(lib, "ole32.lib")

namespace lemon
{
namespace native
{
    class Video
    {
        template<typename T>
        using ComPtr = Microsoft::WRL::ComPtr<T>;

        ComPtr<IMFSourceReader> reader;
        std::vector<unsigned char> frame;
        UINT32 frameWidth = 0;
        UINT32 frameHeight = 0;
        UINT32 frameRateNumerator = 30;
        UINT32 frameRateDenominator = 1;
        LONGLONG videoDuration = 0;
        LONGLONG timestamp = 0;
        bool comInitialized = false;
        bool mediaFoundationInitialized = false;
        bool frameReady = false;

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

    public:
        Video() = default;
        ~Video() { close(); }
        Video* operator->() { return this; }
        const Video* operator->() const { return this; }
        Video(const Video&) = delete;
        Video& operator=(const Video&) = delete;

        bool open(const ::String& path)
        {
            close();
            const HRESULT comResult = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
            comInitialized = SUCCEEDED(comResult);
            if (FAILED(comResult) && comResult != RPC_E_CHANGED_MODE)
                return false;

            if (FAILED(MFStartup(MF_VERSION)))
            {
                close();
                return false;
            }
            mediaFoundationInitialized = true;

            ComPtr<IMFMediaType> outputType;
            const std::wstring widePath = toWide(path);
            HRESULT result = widePath.empty()
                ? E_INVALIDARG
                : MFCreateSourceReaderFromURL(widePath.c_str(), nullptr, reader.GetAddressOf());
            if (SUCCEEDED(result))
                result = reader->SetStreamSelection(MF_SOURCE_READER_ALL_STREAMS, FALSE);
            if (SUCCEEDED(result))
                result = reader->SetStreamSelection(MF_SOURCE_READER_FIRST_VIDEO_STREAM, TRUE);
            if (SUCCEEDED(result))
                result = MFCreateMediaType(outputType.GetAddressOf());
            if (SUCCEEDED(result))
                result = outputType->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
            if (SUCCEEDED(result))
                result = outputType->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32);
            if (SUCCEEDED(result))
                result = reader->SetCurrentMediaType(
                    MF_SOURCE_READER_FIRST_VIDEO_STREAM, nullptr, outputType.Get()
                );

            ComPtr<IMFMediaType> currentType;
            if (SUCCEEDED(result))
                result = reader->GetCurrentMediaType(
                    MF_SOURCE_READER_FIRST_VIDEO_STREAM, currentType.GetAddressOf()
                );
            if (SUCCEEDED(result))
                result = MFGetAttributeSize(currentType.Get(), MF_MT_FRAME_SIZE, &frameWidth, &frameHeight);
            if (SUCCEEDED(result))
            {
                UINT32 numerator = 0;
                UINT32 denominator = 0;
                if (SUCCEEDED(MFGetAttributeRatio(
                    currentType.Get(), MF_MT_FRAME_RATE, &numerator, &denominator
                )) && numerator > 0 && denominator > 0)
                {
                    frameRateNumerator = numerator;
                    frameRateDenominator = denominator;
                }
                PROPVARIANT value;
                PropVariantInit(&value);
                if (SUCCEEDED(reader->GetPresentationAttribute(
                    MF_SOURCE_READER_MEDIASOURCE, MF_PD_DURATION, &value
                )) && value.vt == VT_UI8)
                    videoDuration = static_cast<LONGLONG>(value.uhVal.QuadPart);
                PropVariantClear(&value);
            }

            const uint64_t pixelCount = static_cast<uint64_t>(frameWidth) * frameHeight;
            if (FAILED(result) || frameWidth == 0 || frameHeight == 0 ||
                frameWidth > static_cast<UINT32>(INT_MAX / 4) ||
                pixelCount > 64ULL * 1024 * 1024)
            {
                close();
                return false;
            }
            frame.resize(static_cast<size_t>(frameWidth) * frameHeight * 4);
            return true;
        }

        void close()
        {
            reader.Reset();
            frame.clear();
            frameWidth = 0;
            frameHeight = 0;
            frameRateNumerator = 30;
            frameRateDenominator = 1;
            videoDuration = 0;
            timestamp = 0;
            frameReady = false;
            if (mediaFoundationInitialized)
            {
                MFShutdown();
                mediaFoundationInitialized = false;
            }
            if (comInitialized)
            {
                CoUninitialize();
                comInitialized = false;
            }
        }

        bool readFrame()
        {
            if (reader == nullptr || frame.empty())
                return false;

            frameReady = false;
            for (;;)
            {
                DWORD streamIndex = 0;
                DWORD flags = 0;
                LONGLONG sampleTime = 0;
                ComPtr<IMFSample> sample;
                const HRESULT result = reader->ReadSample(
                    MF_SOURCE_READER_FIRST_VIDEO_STREAM,
                    0,
                    &streamIndex,
                    &flags,
                    &sampleTime,
                    sample.GetAddressOf()
                );
                if (FAILED(result) || (flags & MF_SOURCE_READERF_ENDOFSTREAM) != 0)
                    return false;
                if (sample == nullptr)
                    continue;

                ComPtr<IMFMediaBuffer> buffer;
                if (FAILED(sample->ConvertToContiguousBuffer(buffer.GetAddressOf())))
                    return false;

                BYTE* data = nullptr;
                LONG stride = 0;
                ComPtr<IMF2DBuffer> buffer2D;
                if (SUCCEEDED(buffer.As(&buffer2D)))
                {
                    if (FAILED(buffer2D->Lock2D(&data, &stride)))
                        return false;
                    const size_t rowSize = static_cast<size_t>(frameWidth) * 4;
                    if (static_cast<size_t>(std::abs(stride)) < rowSize)
                    {
                        buffer2D->Unlock2D();
                        return false;
                    }
                    for (UINT32 row = 0; row < frameHeight; ++row)
                    {
                        const BYTE* source = data + static_cast<ptrdiff_t>(row) * stride;
                        unsigned char* destination = frame.data() + static_cast<size_t>(row) * rowSize;
                        std::memcpy(destination, source, rowSize);
                        for (UINT32 column = 0; column < frameWidth; ++column)
                            destination[column * 4 + 3] = 0xFF;
                    }
                    buffer2D->Unlock2D();
                }
                else
                {
                    DWORD maximumLength = 0;
                    DWORD currentLength = 0;
                    if (FAILED(buffer->Lock(&data, &maximumLength, &currentLength)))
                        return false;
                    const size_t expected = frame.size();
                    const bool validLength = currentLength >= expected;
                    if (validLength)
                    {
                        std::memcpy(frame.data(), data, expected);
                        for (size_t offset = 3; offset < expected; offset += 4)
                            frame[offset] = 0xFF;
                    }
                    buffer->Unlock();
                    if (!validLength)
                        return false;
                }
                timestamp = sampleTime;
                frameReady = true;
                return true;
            }
        }

        bool seek(double seconds)
        {
            if (reader == nullptr || !std::isfinite(seconds) || seconds < 0)
                return false;
            const LONGLONG position = static_cast<LONGLONG>(seconds * 10000000.0);
            PROPVARIANT value;
            PropVariantInit(&value);
            value.vt = VT_I8;
            value.hVal.QuadPart = position;
            const HRESULT result = reader->SetCurrentPosition(GUID_NULL, value);
            PropVariantClear(&value);
            if (FAILED(result))
                return false;
            timestamp = position;
            frameReady = false;
            return true;
        }

        int width() const { return static_cast<int>(frameWidth); }
        int height() const { return static_cast<int>(frameHeight); }
        double duration() const { return static_cast<double>(videoDuration) / 10000000.0; }
        double frameTime() const { return static_cast<double>(timestamp) / 10000000.0; }

        bool copyFrame(const ::Array<unsigned char>& bytes, int length) const
        {
            if (!frameReady || bytes == null() || length != static_cast<int>(frame.size()) ||
                bytes->size() < static_cast<size_t>(length))
                return false;
            char* destination = const_cast<char*>(bytes->GetBase());
            if (destination == nullptr)
                return false;
            std::memcpy(destination, frame.data(), frame.size());
            return true;
        }
    };
}
}

#endif
