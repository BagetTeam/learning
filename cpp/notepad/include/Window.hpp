#include <SDL3/SDL.h>

namespace Editor {
    class Window {
    public:
        explicit Window(SDL_Window* win) : window(win) {}
        void getSize(int& w, int& h) const;
        void setSize(int w, int h);
        SDL_Window* get() const { return window; }
        ~Window() = default;
    private:
        SDL_Window* window;
    };
}