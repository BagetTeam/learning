cmake_minimum_required(VERSION 3.16)
project(Notepad)

set(CMAKE_CXX_STANDARD 17)

find_package(SDL3 REQUIRED)
find_package(SDL3_ttf REQUIRED)

add_executable(app src/main.cpp)

target_link_libraries(app
    SDL3::SDL3
    SDL3_ttf::SDL3_ttf
)

configure_file(
    ${CMAKE_SOURCE_DIR}/assets/FreeSans.ttf
    ${CMAKE_BINARY_DIR}/assets/FreeSans.ttf
    COPYONLY
)