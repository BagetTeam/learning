cmake_minimum_required(VERSION 3.16)
project(Notepad)

set(CMAKE_CXX_STANDARD 17)

find_package(SDL3 REQUIRED)
find_package(SDL3_ttf REQUIRED)

add_executable(app
    main.cpp
    src/TextEditor.cpp
    src/Window.cpp
    src/Renderer.cpp
)

target_include_directories(app PRIVATE ${CMAKE_SOURCE_DIR})

target_link_libraries(app
    SDL3::SDL3
    SDL3_ttf::SDL3_ttf
)

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/assets)
file(COPY ${CMAKE_SOURCE_DIR}/assets/ DESTINATION ${CMAKE_BINARY_DIR}/assets)