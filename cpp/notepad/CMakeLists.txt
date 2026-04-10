cmake_minimum_required(VERSION 3.16)
project(Notepad)

set(CMAKE_CXX_STANDARD 17)

find_package(SDL2 REQUIRED)
find_package(SDL2_ttf REQUIRED)

add_executable(app main.cpp)

target_link_libraries(app
    SDL2::SDL2
    SDL2_ttf::SDL2_ttf
)