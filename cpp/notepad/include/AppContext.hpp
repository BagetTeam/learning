#pragma once

#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <include/Window.hpp>
#include <include/Renderer.hpp>
#include <include/TextEditor.hpp>
#include <string>

namespace Editor {
    struct AppContext {
        Window* window;
        Renderer* renderer;
        TextEditor* textEditor;
        
        TTF_Font* font_n = nullptr;
        TTF_Font* font_b = nullptr;
        TTF_Font* font_i = nullptr;
        TTF_Font* font_bi = nullptr;
        
        std::string text;
    };
}