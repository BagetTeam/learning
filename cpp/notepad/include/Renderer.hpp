#ifndef EDITOR_RENDERER_HPP
#define EDITOR_RENDERER_HPP

#include <string>
#include <SDL3/SDL.h>

namespace Editor {

    class Renderer {
    public:
        explicit Renderer(SDL_Renderer* rend) : m_renderer(rend) {}
        
        void drawText(const std::string& text, int x, int y) const;
        void clearScreen();
        void drawCursor(int x, int y, int height) const;
        void drawSelection(int x, int y, int width, int height) const;
        SDL_Renderer* get() {return m_renderer;}
        
        ~Renderer() = default;
    private:
        SDL_Renderer* m_renderer = nullptr;
    };

} 

#endif