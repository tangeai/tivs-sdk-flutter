cmake_minimum_required(VERSION 3.14)

include("${CMAKE_CURRENT_SOURCE_DIR}/prepare.cmake")

if(NOT EXISTS "${RAPID_WINDOWS_SDK_ROOT}")
  message(FATAL_ERROR "Bundled Windows libraries are missing ! \n")
endif()

set(PROJECT_NAME "rapid_kit")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

set(PLUGIN_NAME "rapid_kit_plugin")

list(APPEND PLUGIN_SOURCES
  "rapid_kit_plugin.cpp"  
  "rapid_kit_texture.cpp"
)

add_library(${PLUGIN_NAME} SHARED
"include/rapid_kit/rapid_kit_plugin.h"
  "include/rapid_kit/rapid_kit_plugin_c_api.h"
  "include/rapid_kit/rapid_kit_texture.h"
  "rapid_kit_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

include_directories(
"${CMAKE_CURRENT_SOURCE_DIR}/include"
"${RAPID_WINDOWS_SDK_ROOT}/core/include"
"${RAPID_WINDOWS_SDK_ROOT}/media/include"
"${RAPID_WINDOWS_SDK_ROOT}/sdl/include"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${RAPID_WINDOWS_SDK_ROOT}/core/include"
  "${RAPID_WINDOWS_SDK_ROOT}/media/include"
  "${RAPID_WINDOWS_SDK_ROOT}/sdl/include"
  )
target_link_libraries(${PLUGIN_NAME} flutter flutter_wrapper_plugin)


add_library(libRapidCore SHARED IMPORTED)
set_target_properties(libRapidCore PROPERTIES 
IMPORTED_LOCATION "${RAPID_WINDOWS_SDK_ROOT}/lib/libRapidCore.dll"
IMPORTED_IMPLIB "${RAPID_WINDOWS_SDK_ROOT}/lib/libRapidCore.dll.a"
)
add_library(libRapidMedia SHARED IMPORTED)
set_target_properties(libRapidMedia PROPERTIES 
IMPORTED_LOCATION "${RAPID_WINDOWS_SDK_ROOT}/lib/libRapidMedia.dll"
IMPORTED_IMPLIB "${RAPID_WINDOWS_SDK_ROOT}/lib/libRapidMedia.dll.a"
)
add_library(libRapidSDL SHARED IMPORTED)
set_target_properties(libRapidSDL PROPERTIES 
IMPORTED_LOCATION "${RAPID_WINDOWS_SDK_ROOT}/lib/libRapidSDL.dll"
IMPORTED_IMPLIB "${RAPID_WINDOWS_SDK_ROOT}/lib/libRapidSDL.dll.a"
)
target_link_libraries(${PLUGIN_NAME} libRapidCore)
target_link_libraries(${PLUGIN_NAME} libRapidMedia)
target_link_libraries(${PLUGIN_NAME} libRapidSDL)

set(rapid_kit_bundled_libraries
  ""
  PARENT_SCOPE
)

if (${include_${PROJECT_NAME}_tests})
set(TEST_RUNNER "${PROJECT_NAME}_test")
enable_testing()

include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/release-1.11.0.zip
)
# Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
# Disable install commands for gtest so it doesn't end up in the bundle.
set(INSTALL_GTEST OFF CACHE BOOL "Disable installation of googletest" FORCE)
FetchContent_MakeAvailable(googletest)

# The plugin's C API is not very useful for unit testing, so build the sources
# directly into the test binary rather than using the DLL.

apply_standard_settings(${TEST_RUNNER})
target_include_directories(${TEST_RUNNER} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(${TEST_RUNNER} PRIVATE flutter_wrapper_plugin)
target_link_libraries(${TEST_RUNNER} PRIVATE gtest_main gmock)
# flutter_wrapper_plugin has link dependencies on the Flutter DLL.
add_custom_command(TARGET ${TEST_RUNNER} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
  "${FLUTTER_LIBRARY}" $<TARGET_FILE_DIR:${TEST_RUNNER}>
)

# Enable automatic test discovery.
include(GoogleTest)
gtest_discover_tests(${TEST_RUNNER})
endif()

file(GLOB RAPID_WINDOWS_BUNDLED_LIBRARIES "${RAPID_WINDOWS_SDK_ROOT}/lib/*.dll")
set(rapid_kit_bundled_libraries ${RAPID_WINDOWS_BUNDLED_LIBRARIES} PARENT_SCOPE)
