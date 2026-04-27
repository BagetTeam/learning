#include <include/Renderer.hpp>

namespace Editor {
    void Renderer::drawText(const std::string& text, int x, int y, TTF_Font* font, SDL_Color color) const {
        //clear screen
        SDL_SetRenderDrawColor(m_renderer, 30, 30, 30, 255);
        SDL_RenderClear(m_renderer);
        
        // drawing
        SDL_Surface* surface = TTF_RenderText_Solid(font, text.c_str(), text.length(), color);
        SDL_Texture* texture = SDL_CreateTextureFromSurface(m_renderer, surface);
        
        float tw, th;
        SDL_GetTextureSize(texture, &tw, &th);
        SDL_FRect rect = {x, y, tw, th};

        SDL_RenderTexture(m_renderer, texture, NULL, &rect);
        
        SDL_DestroyTexture(texture);
        SDL_DestroySurface(surface);
    }
    
    void Renderer::clearScreen() {
        SDL_RenderClear(m_renderer);
    }
    
    void Renderer::drawCursor(int x, int y, int height) const {
        
    }
    
    void Renderer::drawSelection(int x, int y, int width, int height) const {
        
    }
}