#include <include/Renderer.hpp>

namespace Editor {
    void Renderer::drawText(const std::string& text, int x, int y) const {
        
    }
    
    void Renderer::clearScreen() {
        SDL_RenderClear(m_renderer);
    }
    
    void Renderer::drawCursor(int x, int y, int height) const {
        
    }
    
    void Renderer::drawSelection(int x, int y, int width, int height) const {
        
    }
}