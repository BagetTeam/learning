cmake_minimum_required(VERSION 3.16)

project(orderbook LANGUAGES CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(orderbook
    src/main.cpp
)

target_include_directories(orderbook PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include/orderbook
)

target_compile_features(orderbook PRIVATE cxx_std_17)
