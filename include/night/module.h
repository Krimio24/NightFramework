#ifndef NIGHT_MODULE_H
#define NIGHT_MODULE_H

#include <stdint.h>

#if defined(_WIN32)
    #if defined(NIGHT_MODULE_BUILD)
        #define NIGHT_MODULE_EXPORT __declspec(dllexport)
    #else
        #define NIGHT_MODULE_EXPORT __declspec(dllimport)
    #endif
    #define NIGHT_MODULE_CALL __cdecl
#elif defined(__GNUC__) || defined(__clang__)
    #define NIGHT_MODULE_EXPORT __attribute__((visibility("default")))
    #define NIGHT_MODULE_CALL
#else
    #define NIGHT_MODULE_EXPORT
    #define NIGHT_MODULE_CALL
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define NIGHT_MODULE_ABI_MAJOR 1u
#define NIGHT_MODULE_ABI_MINOR 0u

typedef struct NightHostAPI
{
    uint32_t struct_size;
    uint32_t abi_major;
    uint32_t abi_minor;
    void* host_context;
    void (NIGHT_MODULE_CALL *log)(void* host_context, int32_t level, const char* message);
} NightHostAPI;

typedef struct NightModuleDescriptor
{
    uint32_t struct_size;
    uint32_t abi_major;
    uint32_t abi_minor;
    uint32_t runtime_major;
    uint32_t runtime_minor;
    const char* name;
    int32_t (NIGHT_MODULE_CALL *initialize)(const NightHostAPI* host);
    void (NIGHT_MODULE_CALL *update)(double elapsed_seconds);
    void (NIGHT_MODULE_CALL *shutdown)(void);
} NightModuleDescriptor;

typedef const NightModuleDescriptor* (NIGHT_MODULE_CALL *NightModuleQueryFn)(
    uint32_t host_abi_major,
    uint32_t host_abi_minor
);

NIGHT_MODULE_EXPORT const NightModuleDescriptor* NIGHT_MODULE_CALL
night_module_query(uint32_t host_abi_major, uint32_t host_abi_minor);

#ifdef __cplusplus
}
#endif

#endif
