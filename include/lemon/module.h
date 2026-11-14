#ifndef LEMON_MODULE_H
#define LEMON_MODULE_H

#include <stdint.h>

#if defined(_WIN32)
    #if defined(LEMON_MODULE_BUILD)
        #define LEMON_MODULE_EXPORT __declspec(dllexport)
    #else
        #define LEMON_MODULE_EXPORT __declspec(dllimport)
    #endif
    #define LEMON_MODULE_CALL __cdecl
#elif defined(__GNUC__) || defined(__clang__)
    #define LEMON_MODULE_EXPORT __attribute__((visibility("default")))
    #define LEMON_MODULE_CALL
#else
    #define LEMON_MODULE_EXPORT
    #define LEMON_MODULE_CALL
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define LEMON_MODULE_ABI_MAJOR 1u
#define LEMON_MODULE_ABI_MINOR 0u

typedef struct LemonHostAPI
{
    uint32_t struct_size;
    uint32_t abi_major;
    uint32_t abi_minor;
    void* host_context;
    void (LEMON_MODULE_CALL *log)(void* host_context, int32_t level, const char* message);
} LemonHostAPI;

typedef struct LemonModuleDescriptor
{
    uint32_t struct_size;
    uint32_t abi_major;
    uint32_t abi_minor;
    uint32_t runtime_major;
    uint32_t runtime_minor;
    const char* name;
    int32_t (LEMON_MODULE_CALL *initialize)(const LemonHostAPI* host);
    void (LEMON_MODULE_CALL *update)(double elapsed_seconds);
    void (LEMON_MODULE_CALL *shutdown)(void);
} LemonModuleDescriptor;

typedef const LemonModuleDescriptor* (LEMON_MODULE_CALL *LemonModuleQueryFn)(
    uint32_t host_abi_major,
    uint32_t host_abi_minor
);

LEMON_MODULE_EXPORT const LemonModuleDescriptor* LEMON_MODULE_CALL
lemon_module_query(uint32_t host_abi_major, uint32_t host_abi_minor);

#ifdef __cplusplus
}
#endif

#endif
