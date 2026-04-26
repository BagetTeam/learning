#include <include/Window.hpp>

namespace Editor {     
    void Window::getSize(int& w, int& h) const {
        SDL_GetWindowSize(window, &w, &h);
    }
    
    void Window::setSize(int w, int h) {
        SDL_SetWindowSize(window, w, h);
    }
}