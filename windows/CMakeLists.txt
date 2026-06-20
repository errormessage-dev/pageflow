cmake_minimum_required(VERSION 3.14)
project(pageflow LANGUAGES CXX)

set(BINARY_NAME "pageflow")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Configure build options.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Release" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()

set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use colored output when supported.
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.15.0")
  option(CMAKE_COLOR_MAKEFILE ON)
endif()

# Use unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_definitions(-DWIN32_LEAN_AND_MEAN)
add_definitions(-DNOMINMAX)

# Application build
add_executable(${BINARY_NAME} WIN32
  "runner/main.cpp"
  "runner/utils.cpp"
  "runner/win32_window.cpp"
  "runner/flutter_window.cpp"
  "runner/plugin_registrant.cc"
  "runner/plugin_registrant.h"
  "runner/CMakeLists.txt"
  "runner/flutter/generated_plugin_registrant.cc"
  "runner/flutter/generated_plugin_registrant.h"
  "runner/flutter/generated_plugins.cmake"
  "runner/Runner.rc"
  "runner/runner.exe.manifest"
  "runner/data/icudtl.dat"
  "runner/flutter_windows.dll"
  "runner/flutter_windows.dll.lib"
  "runner/flutter_windows.dll.pdb"
)

# Apply a standard set of build settings. This can be removed for apps that
# want full control over build settings.
apply_standard_settings(${BINARY_NAME})

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE
  NOMINMAX
  WIN32_LEAN_AND_MEAN
)

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE
  FLUTTER_VERSION=\"1.0.0\"
  FLUTTER_VERSION_MAJOR=1
  FLUTTER_VERSION_MINOR=0
  FLUTTER_VERSION_PATCH=0
  FLUTTER_VERSION_BUILD=0
)

# Disable string conversion warnings, as they would be triggered by
# FLUTTER_ASSERT_NOT_IMPLEMENTED macro usage.
target_compile_options(${BINARY_NAME} PRIVATE /wd4996)

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble) 