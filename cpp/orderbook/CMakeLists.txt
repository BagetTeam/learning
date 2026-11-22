cmake_minimum_required(VERSION 3.16)
project(orderbook LANGUAGES CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Fix policy warning about timestamps
if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()

include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.17.0.zip
)
# For Windows/MSVC compatibility
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)


add_executable(orderbook
    src/main.cpp
)

target_include_directories(orderbook PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include/orderbook
)

target_compile_features(orderbook PRIVATE cxx_std_17)

add_executable(run_tests
    tests/test.cpp
)

target_link_libraries(run_tests PRIVATE gtest_main)

target_include_directories(run_tests PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include/orderbook
)

target_compile_features(run_tests PRIVATE cxx_std_17)

# Lets `ctest` (and VS Code's Testing panel via CMake Tools) find each TEST individually
enable_testing()
include(GoogleTest)
gtest_discover_tests(run_tests)
