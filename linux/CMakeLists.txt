cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "rapid_kit")
project(${PROJECT_NAME} LANGUAGES CXX)

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$")
  set(RAPID_LINUX_ARCH "x64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64|ARM64)$")
  set(RAPID_LINUX_ARCH "arm64")
else()
  message(FATAL_ERROR "Unsupported Linux architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/prepare.cmake")

set(PLUGIN_NAME "rapid_kit_plugin")

add_library(${PLUGIN_NAME} SHARED
  "rapid_kit_ble.cc"
  "rapid_kit_plugin.cc"
  "rapid_kit_texture.cc"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  BUILD_RPATH "$ORIGIN"
  BUILD_WITH_INSTALL_RPATH TRUE
  INSTALL_RPATH "$ORIGIN"
)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${RAPID_LINUX_SDK_ROOT}/core/include"
  "${RAPID_LINUX_SDK_ROOT}/media/include"
  "${RAPID_LINUX_SDK_ROOT}/sdl/include"
)
target_include_directories(${PLUGIN_NAME} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")

add_library(rapid_kit_core SHARED IMPORTED)
set_target_properties(rapid_kit_core PROPERTIES IMPORTED_LOCATION "${RAPID_CORE_LIBRARY}")
add_library(rapid_kit_media SHARED IMPORTED)
set_target_properties(rapid_kit_media PROPERTIES IMPORTED_LOCATION "${RAPID_MEDIA_LIBRARY}")
add_library(rapid_kit_sdl SHARED IMPORTED)
set_target_properties(rapid_kit_sdl PROPERTIES IMPORTED_LOCATION "${RAPID_SDL_LIBRARY}")

target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  PkgConfig::GTK
  rapid_kit_core
  rapid_kit_media
  rapid_kit_sdl
)

file(GLOB RAPID_LINUX_BUNDLED_LIBRARIES "${RAPID_LINUX_SDK_ROOT}/libraries/*.so*")
set(rapid_kit_bundled_libraries ${RAPID_LINUX_BUNDLED_LIBRARIES} PARENT_SCOPE)
