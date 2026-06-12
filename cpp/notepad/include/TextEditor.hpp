#pragma once

#include <SDL3/SDL.h>
#include <string>

namespace Editor {
    class TextEditor {
    public:
        SDL_AppResult handleEvent(const SDL_Event& event);
        void onResize(int w, int h);
        std::string getText();
    private: 
        std::string m_text;
    };
}
