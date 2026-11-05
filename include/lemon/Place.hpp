#pragma once

#ifndef LEMON_PLACE_HPP
#define LEMON_PLACE_HPP

#include <hxcpp.h>
#include <windows.h>
#include <d2d1.h>
#include <dwrite.h>
#include <dwrite_3.h>
#include <shobjidl.h>
#include <shellapi.h>
#include <wincodec.h>
#include <wrl/client.h>
#include <Xinput.h>
#include <algorithm>
#include <cstring>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#pragma comment(lib, "d2d1.lib")
#pragma comment(lib, "dwrite.lib")
#pragma comment(lib, "windowscodecs.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "xinput9_1_0.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "uuid.lib")

namespace lemon
{
namespace native
{
    class Place
    {
        template<typename T>
        using ComPtr = Microsoft::WRL::ComPtr<T>;

        struct Texture
        {
            std::wstring path;
            std::vector<unsigned char> data;
            ComPtr<ID2D1Bitmap> bitmap;
        };

        struct Font
        {
            std::wstring family;
            ComPtr<IDWriteFontCollection> collection;
        };

        HWND window = nullptr;
        bool opened = false;
        bool drawing = false;
        bool comInitialized = false;
        int mouseWheel = 0;
        XINPUT_STATE gamepadState[4]{};
        bool gamepadIsConnected[4]{};
        int currentWidth;
        int currentHeight;
        int nextTexture = 1;
        int nextFont = 1;
        std::wstring currentTitle;
        ComPtr<ID2D1Factory> d2dFactory;
        ComPtr<ID2D1HwndRenderTarget> renderTarget;
        ComPtr<IDWriteFactory> writeFactory;
        ComPtr<IWICImagingFactory> imagingFactory;
        ComPtr<ITaskbarList3> taskbarList;
        NOTIFYICONDATAW trayIcon{};
        bool trayIconAdded = false;
        std::unordered_map<int, Texture> textures;
        std::unordered_map<int, Font> fonts;

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

        static float channel(int value)
        {
            return static_cast<float>(std::max(0, std::min(value, 255))) / 255.0f;
        }

        static D2D1_COLOR_F color(int red, int green, int blue, int alpha)
        {
            return D2D1::ColorF(channel(red), channel(green), channel(blue), channel(alpha));
        }

        static void copyNotificationText(wchar_t* destination, size_t capacity, const std::wstring& value)
        {
            if (capacity == 0)
                return;
            wcsncpy_s(destination, capacity, value.c_str(), _TRUNCATE);
        }

        bool ensureTrayIcon()
        {
            if (trayIconAdded)
                return true;
            if (window == nullptr)
                return false;

            trayIcon = {};
            trayIcon.cbSize = sizeof(trayIcon);
            trayIcon.hWnd = window;
            trayIcon.uID = 1;
            trayIcon.uFlags = NIF_ICON | NIF_TIP;
            trayIcon.hIcon = LoadIconW(nullptr, MAKEINTRESOURCEW(32512));
            copyNotificationText(trayIcon.szTip, ARRAYSIZE(trayIcon.szTip), currentTitle);
            if (!Shell_NotifyIconW(NIM_ADD, &trayIcon))
                return false;
            trayIconAdded = true;
            trayIcon.uVersion = NOTIFYICON_VERSION_4;
            if (Shell_NotifyIconW(NIM_SETVERSION, &trayIcon))
                return true;
            removeTrayIcon();
            return false;
        }

        void removeTrayIcon()
        {
            if (!trayIconAdded)
                return;
            Shell_NotifyIconW(NIM_DELETE, &trayIcon);
            trayIconAdded = false;
            trayIcon = {};
        }

        static LRESULT CALLBACK windowProcedure(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
        {
            Place* place = reinterpret_cast<Place*>(
                GetWindowLongPtrW(hwnd, GWLP_USERDATA)
            );

            switch (message)
            {
                case WM_NCCREATE:
                {
                    auto* data = reinterpret_cast<CREATESTRUCTW*>(lParam);
                    place = static_cast<Place*>(data->lpCreateParams);
                    SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(place));
                    break;
                }
                case WM_CLOSE:
                    DestroyWindow(hwnd);
                    return 0;
                case WM_DESTROY:
                    if (place != nullptr)
                    {
                        place->removeTrayIcon();
                        if (place->taskbarList != nullptr)
                            place->taskbarList->SetProgressState(hwnd, TBPF_NOPROGRESS);
                        place->taskbarList.Reset();
                        place->opened = false;
                        place->window = nullptr;
                    }
                    PostQuitMessage(0);
                    return 0;
                case WM_ERASEBKGND:
                    return 1;
                case WM_PAINT:
                {
                    PAINTSTRUCT paint{};
                    BeginPaint(hwnd, &paint);
                    EndPaint(hwnd, &paint);
                    return 0;
                }
                case WM_SIZE:
                    if (place != nullptr)
                    {
                        place->currentWidth = LOWORD(lParam);
                        place->currentHeight = HIWORD(lParam);
                        if (place->renderTarget != nullptr &&
                            place->currentWidth > 0 && place->currentHeight > 0)
                        {
                            place->renderTarget->Resize(D2D1::SizeU(
                                place->currentWidth,
                                place->currentHeight
                            ));
                        }
                    }
                    break;
                case WM_MOUSEWHEEL:
                    if (place != nullptr)
                        place->mouseWheel += GET_WHEEL_DELTA_WPARAM(wParam);
                    return 0;
            }

            return DefWindowProcW(hwnd, message, wParam, lParam);
        }

        bool createRenderTarget()
        {
            if (window == nullptr || currentWidth <= 0 || currentHeight <= 0)
                return false;

            const HRESULT result = d2dFactory->CreateHwndRenderTarget(
                D2D1::RenderTargetProperties(),
                D2D1::HwndRenderTargetProperties(
                    window,
                    D2D1::SizeU(currentWidth, currentHeight)
                ),
                renderTarget.GetAddressOf()
            );
            if (FAILED(result))
                return false;

            for (auto& entry : textures)
            {
                if (!createBitmap(entry.second))
                {
                    entry.second.bitmap.Reset();
                }
            }

            return true;
        }

        bool createBitmap(Texture& texture)
        {
            if (renderTarget == nullptr || imagingFactory == nullptr)
                return false;
            if (texture.path.empty())
                return createBitmap(texture, texture.data.data(), texture.data.size());

            ComPtr<IWICBitmapDecoder> decoder;
            ComPtr<IWICBitmapFrameDecode> frame;
            ComPtr<IWICFormatConverter> converter;

            HRESULT result = imagingFactory->CreateDecoderFromFilename(
                texture.path.c_str(),
                nullptr,
                GENERIC_READ,
                WICDecodeMetadataCacheOnLoad,
                decoder.GetAddressOf()
            );
            if (FAILED(result))
                return false;

            result = decoder->GetFrame(0, frame.GetAddressOf());
            if (FAILED(result))
                return false;

            result = imagingFactory->CreateFormatConverter(converter.GetAddressOf());
            if (FAILED(result))
                return false;

            result = converter->Initialize(
                frame.Get(),
                GUID_WICPixelFormat32bppPBGRA,
                WICBitmapDitherTypeNone,
                nullptr,
                0.0,
                WICBitmapPaletteTypeMedianCut
            );
            if (FAILED(result))
                return false;

            return SUCCEEDED(renderTarget->CreateBitmapFromWicBitmap(
                converter.Get(),
                nullptr,
                texture.bitmap.ReleaseAndGetAddressOf()
            ));
        }

        bool createBitmap(Texture& texture, const BYTE* bytes, size_t length)
        {
            if (renderTarget == nullptr || imagingFactory == nullptr ||
                bytes == nullptr || length == 0 ||
                length > static_cast<size_t>(MAXDWORD))
                return false;

            ComPtr<IWICStream> stream;
            ComPtr<IWICBitmapDecoder> decoder;
            ComPtr<IWICBitmapFrameDecode> frame;
            ComPtr<IWICFormatConverter> converter;
            if (FAILED(imagingFactory->CreateStream(stream.GetAddressOf())) ||
                FAILED(stream->InitializeFromMemory(
                    const_cast<BYTE*>(bytes),
                    static_cast<DWORD>(length)
                )) ||
                FAILED(imagingFactory->CreateDecoderFromStream(
                    stream.Get(),
                    nullptr,
                    WICDecodeMetadataCacheOnLoad,
                    decoder.GetAddressOf()
                )) ||
                FAILED(decoder->GetFrame(0, frame.GetAddressOf())) ||
                FAILED(imagingFactory->CreateFormatConverter(converter.GetAddressOf())) ||
                FAILED(converter->Initialize(
                    frame.Get(),
                    GUID_WICPixelFormat32bppPBGRA,
                    WICBitmapDitherTypeNone,
                    nullptr,
                    0.0,
                    WICBitmapPaletteTypeMedianCut
                )))
                return false;

            return SUCCEEDED(renderTarget->CreateBitmapFromWicBitmap(
                converter.Get(),
                nullptr,
                texture.bitmap.ReleaseAndGetAddressOf()
            ));
        }

        bool readyToDraw() const
        {
            return drawing && renderTarget != nullptr;
        }

        bool createBrush(int red, int green, int blue, int alpha, ID2D1SolidColorBrush** brush)
        {
            return readyToDraw() && SUCCEEDED(renderTarget->CreateSolidColorBrush(
                color(red, green, blue, alpha),
                brush
            ));
        }

    public:
        Place(const ::String& title, int width, int height)
            : currentWidth(width),
              currentHeight(height),
              currentTitle(toWide(title))
        {
        }

        ~Place()
        {
            close();
        }

        Place(const Place&) = delete;
        Place& operator=(const Place&) = delete;

        Place* operator->() { return this; }
        const Place* operator->() const { return this; }

        bool create()
        {
            if (window != nullptr)
                return true;

            const HRESULT comResult = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
            comInitialized = SUCCEEDED(comResult);

            D2D1_FACTORY_OPTIONS options{};
            if (FAILED(D2D1CreateFactory(
                D2D1_FACTORY_TYPE_SINGLE_THREADED,
                __uuidof(ID2D1Factory),
                &options,
                reinterpret_cast<void**>(d2dFactory.GetAddressOf())
            )))
                return false;

            if (FAILED(DWriteCreateFactory(
                DWRITE_FACTORY_TYPE_SHARED,
                __uuidof(IDWriteFactory),
                reinterpret_cast<IUnknown**>(writeFactory.GetAddressOf())
            )))
                return false;

            if (FAILED(CoCreateInstance(
                CLSID_WICImagingFactory,
                nullptr,
                CLSCTX_INPROC_SERVER,
                IID_PPV_ARGS(imagingFactory.GetAddressOf())
            )))
                return false;

            static const wchar_t* className = L"LemonPlaceWindowClass";
            static bool registered = false;
            HINSTANCE instance = GetModuleHandleW(nullptr);

            if (!registered)
            {
                WNDCLASSEXW wc{};
                wc.cbSize = sizeof(wc);
                wc.style = CS_HREDRAW | CS_VREDRAW;
                wc.lpfnWndProc = windowProcedure;
                wc.hInstance = instance;
                wc.hCursor = LoadCursorW(nullptr, MAKEINTRESOURCEW(32512));
                wc.lpszClassName = className;

                if (!RegisterClassExW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS)
                    return false;
                registered = true;
            }

            RECT rect{ 0, 0, currentWidth, currentHeight };
            AdjustWindowRect(&rect, WS_OVERLAPPEDWINDOW, FALSE);

            window = CreateWindowExW(
                0,
                className,
                currentTitle.c_str(),
                WS_OVERLAPPEDWINDOW,
                CW_USEDEFAULT,
                CW_USEDEFAULT,
                rect.right - rect.left,
                rect.bottom - rect.top,
                nullptr,
                nullptr,
                instance,
                this
            );
            opened = window != nullptr;
            return opened && createRenderTarget();
        }

        void show()
        {
            if (window != nullptr)
            {
                ShowWindow(window, SW_SHOW);
                UpdateWindow(window);
            }
        }

        void hide()
        {
            if (window != nullptr)
                ShowWindow(window, SW_HIDE);
        }

        void setTitle(const ::String& title)
        {
            currentTitle = toWide(title);
            if (window != nullptr)
                SetWindowTextW(window, currentTitle.c_str());
        }

        void setSize(int width, int height)
        {
            currentWidth = width;
            currentHeight = height;
            if (window == nullptr)
                return;

            RECT rect{ 0, 0, width, height };
            AdjustWindowRect(&rect, WS_OVERLAPPEDWINDOW, FALSE);
            SetWindowPos(
                window, nullptr, 0, 0, rect.right - rect.left, rect.bottom - rect.top,
                SWP_NOMOVE | SWP_NOZORDER
            );
        }

        void close()
        {
            drawing = false;
            removeTrayIcon();
            if (taskbarList != nullptr && window != nullptr)
                taskbarList->SetProgressState(window, TBPF_NOPROGRESS);
            taskbarList.Reset();
            if (window != nullptr)
                DestroyWindow(window);
            window = nullptr;
            opened = false;
            renderTarget.Reset();
            textures.clear();
            fonts.clear();
            mouseWheel = 0;
            for (int index = 0; index < 4; ++index)
            {
                gamepadState[index] = {};
                gamepadIsConnected[index] = false;
            }
            imagingFactory.Reset();
            writeFactory.Reset();
            d2dFactory.Reset();
            if (comInitialized)
            {
                CoUninitialize();
                comInitialized = false;
            }
        }

        bool setTaskbarProgress(int state, int value, int maximum)
        {
                if (window == nullptr ||
                    (state != TBPF_NOPROGRESS && state != TBPF_INDETERMINATE &&
                        state != TBPF_NORMAL && state != TBPF_ERROR && state != TBPF_PAUSED))
                    return false;
                if (taskbarList == nullptr)
                {
                    if (FAILED(CoCreateInstance(
                        CLSID_TaskbarList,
                        nullptr,
                        CLSCTX_INPROC_SERVER,
                        IID_PPV_ARGS(taskbarList.GetAddressOf())
                    )) || FAILED(taskbarList->HrInit()))
                    {
                        taskbarList.Reset();
                        return false;
                    }
                }

                if (state == TBPF_NORMAL || state == TBPF_PAUSED || state == TBPF_ERROR)
                {
                    if (maximum <= 0 || value < 0 || value > maximum)
                        return false;
                    if (FAILED(taskbarList->SetProgressValue(
                        window,
                        static_cast<ULONGLONG>(value),
                        static_cast<ULONGLONG>(maximum)
                    )))
                        return false;
                }
                return SUCCEEDED(taskbarList->SetProgressState(window, static_cast<TBPFLAG>(state)));
        }

        bool showTrayNotification(const ::String& title, const ::String& message)
        {
                if (!ensureTrayIcon())
                    return false;
                trayIcon.uFlags = NIF_INFO;
                trayIcon.dwInfoFlags = NIIF_INFO;
                copyNotificationText(trayIcon.szInfoTitle, ARRAYSIZE(trayIcon.szInfoTitle), toWide(title));
                copyNotificationText(trayIcon.szInfo, ARRAYSIZE(trayIcon.szInfo), toWide(message));
                const bool shown = Shell_NotifyIconW(NIM_MODIFY, &trayIcon) != FALSE;
                trayIcon.uFlags = NIF_ICON | NIF_TIP;
                trayIcon.uVersion = NOTIFYICON_VERSION_4;
                trayIcon.szInfoTitle[0] = L'\0';
                trayIcon.szInfo[0] = L'\0';
                return shown;
        }

        bool showNotification(const ::String& title, const ::String& message)
        {
            return showTrayNotification(title, message);
        }

        void hideTrayNotification()
        {
            removeTrayIcon();
        }

        bool beginFrame(int red, int green, int blue, int alpha)
        {
            if (!opened)
                return false;
            if (renderTarget == nullptr && !createRenderTarget())
                return false;

            renderTarget->BeginDraw();
            drawing = true;
            renderTarget->SetTransform(D2D1::Matrix3x2F::Identity());
            renderTarget->Clear(color(red, green, blue, alpha));
            return true;
        }

        bool endFrame()
        {
            if (!readyToDraw())
                return false;

            drawing = false;
            const HRESULT result = renderTarget->EndDraw();
            if (result == D2DERR_RECREATE_TARGET)
            {
                renderTarget.Reset();
                for (auto& entry : textures)
                    entry.second.bitmap.Reset();
                return createRenderTarget();
            }
            return SUCCEEDED(result);
        }

        void drawLine(double x1, double y1, double x2, double y2,
            int red, int green, int blue, int alpha, double thickness)
        {
            ComPtr<ID2D1SolidColorBrush> brush;
            if (createBrush(red, green, blue, alpha, brush.GetAddressOf()))
                renderTarget->DrawLine(
                    D2D1::Point2F(static_cast<float>(x1), static_cast<float>(y1)),
                    D2D1::Point2F(static_cast<float>(x2), static_cast<float>(y2)),
                    brush.Get(),
                    static_cast<float>(thickness)
                );
        }

        void drawRectangle(double x, double y, double width, double height,
            int red, int green, int blue, int alpha, double thickness)
        {
            ComPtr<ID2D1SolidColorBrush> brush;
            if (createBrush(red, green, blue, alpha, brush.GetAddressOf()))
                renderTarget->DrawRectangle(
                    D2D1::RectF(
                        static_cast<float>(x), static_cast<float>(y),
                        static_cast<float>(x + width), static_cast<float>(y + height)
                    ),
                    brush.Get(),
                    static_cast<float>(thickness)
                );
        }

        void fillRectangle(double x, double y, double width, double height,
            int red, int green, int blue, int alpha)
        {
            ComPtr<ID2D1SolidColorBrush> brush;
            if (createBrush(red, green, blue, alpha, brush.GetAddressOf()))
                renderTarget->FillRectangle(
                    D2D1::RectF(
                        static_cast<float>(x), static_cast<float>(y),
                        static_cast<float>(x + width), static_cast<float>(y + height)
                    ),
                    brush.Get()
                );
        }

        void drawCircle(double x, double y, double radius,
            int red, int green, int blue, int alpha, double thickness)
        {
            ComPtr<ID2D1SolidColorBrush> brush;
            if (createBrush(red, green, blue, alpha, brush.GetAddressOf()))
                renderTarget->DrawEllipse(
                    D2D1::Ellipse(
                        D2D1::Point2F(static_cast<float>(x), static_cast<float>(y)),
                        static_cast<float>(radius),
                        static_cast<float>(radius)
                    ),
                    brush.Get(),
                    static_cast<float>(thickness)
                );
        }

        void fillCircle(double x, double y, double radius,
            int red, int green, int blue, int alpha)
        {
            ComPtr<ID2D1SolidColorBrush> brush;
            if (createBrush(red, green, blue, alpha, brush.GetAddressOf()))
                renderTarget->FillEllipse(
                    D2D1::Ellipse(
                        D2D1::Point2F(static_cast<float>(x), static_cast<float>(y)),
                        static_cast<float>(radius),
                        static_cast<float>(radius)
                    ),
                    brush.Get()
                );
        }

        void fillTriangle(double x1, double y1, double x2, double y2,
            double x3, double y3, int red, int green, int blue, int alpha)
        {
            if (!readyToDraw())
                return;

            ComPtr<ID2D1PathGeometry> geometry;
            ComPtr<ID2D1GeometrySink> sink;
            ComPtr<ID2D1SolidColorBrush> brush;
            if (FAILED(d2dFactory->CreatePathGeometry(geometry.GetAddressOf())) ||
                FAILED(geometry->Open(sink.GetAddressOf())) ||
                !createBrush(red, green, blue, alpha, brush.GetAddressOf()))
                return;

            sink->BeginFigure(
                D2D1::Point2F(static_cast<float>(x1), static_cast<float>(y1)),
                D2D1_FIGURE_BEGIN_FILLED
            );
            const D2D1_POINT_2F points[] = {
                D2D1::Point2F(static_cast<float>(x2), static_cast<float>(y2)),
                D2D1::Point2F(static_cast<float>(x3), static_cast<float>(y3))
            };
            sink->AddLines(points, 2);
            sink->EndFigure(D2D1_FIGURE_END_CLOSED);
            if (SUCCEEDED(sink->Close()))
                renderTarget->FillGeometry(geometry.Get(), brush.Get());
        }

        int loadTexture(const ::String& path)
        {
            if (renderTarget == nullptr)
                return -1;

            Texture texture;
            texture.path = toWide(path);
            if (texture.path.empty() || !createBitmap(texture))
                return -1;

            const int id = nextTexture++;
            textures.emplace(id, std::move(texture));
            return id;
        }

        int loadTextureBytes(const ::Array<unsigned char>& bytes, int length)
        {
            if (renderTarget == nullptr || bytes == null() || length <= 0 ||
                static_cast<size_t>(length) > bytes->size())
                return -1;

            Texture texture;
            const char* data = bytes->GetBase();
            if (data == nullptr)
                return -1;
            texture.data.assign(data, data + length);
            if (!createBitmap(texture))
                return -1;

            const int id = nextTexture++;
            textures.emplace(id, std::move(texture));
            return id;
        }

        int loadTexturePixels(const ::Array<unsigned char>& bytes, int length, int width, int height)
        {
            if (renderTarget == nullptr || bytes == null() || width <= 0 || height <= 0 ||
                length <= 0 ||
                static_cast<uint64_t>(width) * static_cast<uint64_t>(height) * 4 !=
                    static_cast<uint64_t>(length) ||
                static_cast<size_t>(length) > bytes->size())
                return -1;
            const char* data = bytes->GetBase();
            if (data == nullptr)
                return -1;

            Texture texture;
            const auto properties = D2D1::BitmapProperties(
                D2D1::PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_IGNORE)
            );
            if (FAILED(renderTarget->CreateBitmap(
                D2D1::SizeU(static_cast<UINT32>(width), static_cast<UINT32>(height)),
                data,
                static_cast<UINT32>(width * 4),
                properties,
                texture.bitmap.GetAddressOf()
            )))
                return -1;

            const int id = nextTexture++;
            textures.emplace(id, std::move(texture));
            return id;
        }

        bool updateTexturePixels(int id, const ::Array<unsigned char>& bytes, int length,
            int width, int height)
        {
            const auto found = textures.find(id);
            if (renderTarget == nullptr || found == textures.end() || found->second.bitmap == nullptr ||
                bytes == null() || width <= 0 || height <= 0 || length <= 0 ||
                static_cast<uint64_t>(width) * static_cast<uint64_t>(height) * 4 !=
                    static_cast<uint64_t>(length) ||
                static_cast<size_t>(length) > bytes->size())
                return false;
            const char* data = bytes->GetBase();
            if (data == nullptr)
                return false;

            const D2D1_SIZE_U size = found->second.bitmap->GetPixelSize();
            if (size.width != static_cast<UINT32>(width) ||
                size.height != static_cast<UINT32>(height))
            {
                found->second.bitmap.Reset();
                const auto properties = D2D1::BitmapProperties(
                    D2D1::PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_IGNORE)
                );
                if (FAILED(renderTarget->CreateBitmap(
                    D2D1::SizeU(static_cast<UINT32>(width), static_cast<UINT32>(height)),
                    data,
                    static_cast<UINT32>(width * 4),
                    properties,
                    found->second.bitmap.GetAddressOf()
                )))
                    return false;
                return true;
            }

            return SUCCEEDED(found->second.bitmap->CopyFromMemory(
                nullptr, data, static_cast<UINT32>(width * 4)
            ));
        }

        bool drawTexture(int id, double x, double y, double width, double height, double alpha)
        {
            const auto found = textures.find(id);
            if (!readyToDraw() || found == textures.end() || found->second.bitmap == nullptr)
                return false;

            renderTarget->DrawBitmap(
                found->second.bitmap.Get(),
                D2D1::RectF(
                    static_cast<float>(x), static_cast<float>(y),
                    static_cast<float>(x + width), static_cast<float>(y + height)
                ),
                std::max(0.0f, std::min(static_cast<float>(alpha), 1.0f)),
                D2D1_BITMAP_INTERPOLATION_MODE_LINEAR
            );
            return true;
        }

        void unloadTexture(int id)
        {
            textures.erase(id);
        }

        double textureWidth(int id) const
        {
            const auto found = textures.find(id);
            return found == textures.end() || found->second.bitmap == nullptr
                ? 0
                : found->second.bitmap->GetSize().width;
        }

        double textureHeight(int id) const
        {
            const auto found = textures.find(id);
            return found == textures.end() || found->second.bitmap == nullptr
                ? 0
                : found->second.bitmap->GetSize().height;
        }

        int loadFont(const ::String& path, const ::String& family)
        {
            const std::wstring widePath = toWide(path);
            Font font;
            font.family = toWide(family);
            if (writeFactory == nullptr || widePath.empty() || font.family.empty())
                return -1;

            ComPtr<IDWriteFactory3> factory3;
            ComPtr<IDWriteFontSetBuilder> builder;
            ComPtr<IDWriteFontSetBuilder1> builder1;
            ComPtr<IDWriteFontFile> fontFile;
            ComPtr<IDWriteFontSet> fontSet;
            ComPtr<IDWriteFontCollection1> collection;
            if (FAILED(writeFactory.As(&factory3)) ||
                FAILED(factory3->CreateFontSetBuilder(builder.GetAddressOf())) ||
                FAILED(factory3->CreateFontFileReference(
                    widePath.c_str(), nullptr, fontFile.GetAddressOf()
                )) ||
                FAILED(builder.As(&builder1)) ||
                FAILED(builder1->AddFontFile(fontFile.Get())) ||
                FAILED(builder->CreateFontSet(fontSet.GetAddressOf())) ||
                FAILED(factory3->CreateFontCollectionFromFontSet(
                    fontSet.Get(), collection.GetAddressOf()
                )))
                return -1;

            font.collection = collection;
            const int id = nextFont++;
            fonts.emplace(id, std::move(font));
            return id;
        }

        void unloadFont(int id)
        {
            fonts.erase(id);
        }

        bool drawText(const ::String& text, double x, double y, double width, double height,
            double size, int red, int green, int blue, int alpha, int fontId,
            int weight, int style, int stretch, int textAlignment, int paragraphAlignment)
        {
            if (!readyToDraw() || size <= 0 || width <= 0 || height <= 0 ||
                weight < 1 || weight > 999 ||
                style < DWRITE_FONT_STYLE_NORMAL || style > DWRITE_FONT_STYLE_ITALIC ||
                stretch < DWRITE_FONT_STRETCH_ULTRA_CONDENSED ||
                stretch > DWRITE_FONT_STRETCH_ULTRA_EXPANDED ||
                textAlignment < DWRITE_TEXT_ALIGNMENT_LEADING ||
                textAlignment > DWRITE_TEXT_ALIGNMENT_JUSTIFIED ||
                paragraphAlignment < DWRITE_PARAGRAPH_ALIGNMENT_NEAR ||
                paragraphAlignment > DWRITE_PARAGRAPH_ALIGNMENT_FAR)
                return false;

            const std::wstring wideText = toWide(text);
            const auto font = fonts.find(fontId);
            if (fontId >= 0 && font == fonts.end())
                return false;

            const wchar_t* family = fontId < 0
                ? L"Segoe UI"
                : font->second.family.c_str();
            IDWriteFontCollection* collection = fontId < 0
                ? nullptr
                : font->second.collection.Get();
            ComPtr<IDWriteTextFormat> format;
            ComPtr<ID2D1SolidColorBrush> brush;
            if (FAILED(writeFactory->CreateTextFormat(
                family,
                collection,
                static_cast<DWRITE_FONT_WEIGHT>(weight),
                static_cast<DWRITE_FONT_STYLE>(style),
                static_cast<DWRITE_FONT_STRETCH>(stretch),
                static_cast<float>(size),
                L"",
                format.GetAddressOf()
            )) || FAILED(format->SetTextAlignment(
                static_cast<DWRITE_TEXT_ALIGNMENT>(textAlignment)
            )) || FAILED(format->SetParagraphAlignment(
                static_cast<DWRITE_PARAGRAPH_ALIGNMENT>(paragraphAlignment)
            )) || !createBrush(red, green, blue, alpha, brush.GetAddressOf()))
                return false;

            renderTarget->DrawText(
                wideText.c_str(),
                static_cast<UINT32>(wideText.size()),
                format.Get(),
                D2D1::RectF(
                    static_cast<float>(x),
                    static_cast<float>(y),
                    static_cast<float>(x + width),
                    static_cast<float>(y + height)
                ),
                brush.Get()
            );
            return true;
        }

        void setTransform(double scaleX, double scaleY, double rotation, double x, double y)
        {
            if (!readyToDraw())
                return;
            renderTarget->SetTransform(
                D2D1::Matrix3x2F::Scale(
                    static_cast<float>(scaleX),
                    static_cast<float>(scaleY)
                ) *
                D2D1::Matrix3x2F::Rotation(static_cast<float>(rotation)) *
                D2D1::Matrix3x2F::Translation(static_cast<float>(x), static_cast<float>(y))
            );
        }

        void resetTransform()
        {
            if (readyToDraw())
                renderTarget->SetTransform(D2D1::Matrix3x2F::Identity());
        }

        void updateInput()
        {
            for (DWORD index = 0; index < 4; ++index)
            {
                XINPUT_STATE state{};
                gamepadIsConnected[index] = XInputGetState(index, &state) == ERROR_SUCCESS;
                gamepadState[index] = gamepadIsConnected[index] ? state : XINPUT_STATE{};
            }
        }

        bool isKeyDown(int keyCode) const
        {
            return window != nullptr && GetForegroundWindow() == window &&
                keyCode >= 0 && keyCode <= 255 &&
                (GetAsyncKeyState(keyCode) & 0x8000) != 0;
        }

        int mouseX() const
        {
            if (window == nullptr)
                return 0;
            POINT point{};
            if (!GetCursorPos(&point) || !ScreenToClient(window, &point))
                return 0;
            return point.x;
        }

        int mouseY() const
        {
            if (window == nullptr)
                return 0;
            POINT point{};
            if (!GetCursorPos(&point) || !ScreenToClient(window, &point))
                return 0;
            return point.y;
        }

        bool isMouseButtonDown(int button) const
        {
            if (window == nullptr || GetForegroundWindow() != window)
                return false;
            const int virtualKey = button == 0 ? VK_LBUTTON :
                button == 1 ? VK_RBUTTON : button == 2 ? VK_MBUTTON : 0;
            return virtualKey != 0 && (GetAsyncKeyState(virtualKey) & 0x8000) != 0;
        }

        int takeMouseWheel()
        {
            const int delta = mouseWheel;
            mouseWheel = 0;
            return delta;
        }

        bool gamepadConnected(int index) const
        {
            return index >= 0 && index < 4 && gamepadIsConnected[index];
        }

        int gamepadButtons(int index) const
        {
            return gamepadConnected(index) ? gamepadState[index].Gamepad.wButtons : 0;
        }

        double gamepadAxisX(int index) const
        {
            return gamepadConnected(index) ? normalizeStick(gamepadState[index].Gamepad.sThumbLX) : 0.0;
        }

        double gamepadAxisY(int index) const
        {
            return gamepadConnected(index) ? -normalizeStick(gamepadState[index].Gamepad.sThumbLY) : 0.0;
        }

        double gamepadAxisRX(int index) const
        {
            return gamepadConnected(index) ? normalizeStick(gamepadState[index].Gamepad.sThumbRX) : 0.0;
        }

        double gamepadAxisRY(int index) const
        {
            return gamepadConnected(index) ? -normalizeStick(gamepadState[index].Gamepad.sThumbRY) : 0.0;
        }

        double gamepadLeftTrigger(int index) const
        {
            return gamepadConnected(index)
                ? static_cast<double>(gamepadState[index].Gamepad.bLeftTrigger) / 255.0
                : 0.0;
        }

        double gamepadRightTrigger(int index) const
        {
            return gamepadConnected(index)
                ? static_cast<double>(gamepadState[index].Gamepad.bRightTrigger) / 255.0
                : 0.0;
        }

        static double normalizeStick(SHORT value)
        {
            return value < 0
                ? static_cast<double>(value) / 32768.0
                : static_cast<double>(value) / 32767.0;
        }

        bool isOpen() const { return opened && window != nullptr; }
        bool isVisible() const { return window != nullptr && IsWindowVisible(window); }
        int width() const { return currentWidth; }
        int height() const { return currentHeight; }

        ::String title() const
        {
            const int length = WideCharToMultiByte(
                CP_UTF8, 0, currentTitle.c_str(), -1, nullptr, 0, nullptr, nullptr
            );
            if (length <= 0)
                return ::String("");

            std::string result(length, char{});
            WideCharToMultiByte(
                CP_UTF8, 0, currentTitle.c_str(), -1, &result[0], length, nullptr, nullptr
            );
            return ::String(result.c_str());
        }

        static bool pollEvents()
        {
            MSG message{};
            while (PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE))
            {
                if (message.message == WM_QUIT)
                    return false;
                TranslateMessage(&message);
                DispatchMessageW(&message);
            }
            return true;
        }
    };
}
}

#endif
