#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <iostream>


class Renderer {
    public:
        virtual void drawText(std::string text, int x, int y) = 0;
        virtual void clearScreen() = 0;
        virtual void drawCursor(int x, int y, int height) = 0;
        virtual void drawSelection(int x, int y, int width, int height) = 0;
        ~Renderer() = default;
    };
}

class SDL2Renderer : public Renderer {
    public:
        SDL2Renderer(SDL_Window* window);
        void drawText(std::string text, int x, int y) override;
        void clearScreen() override;
        void drawCursor(int x, int y, int height) override;
        void drawSelection(int x, int y, int width, int height) override;
    private:
        SDL_Window* window;
};

SDL2Renderer::SDL2Renderer(SDL_Window* window) {
    this->window = window;
}

void SDL2Renderer::drawText(std::string text, int x, int y) {
    SDL_Surface* surface = TTF_RenderText_Solid(font, text.c_str(), color);
    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_Rect rect = {x, y, surface->w, surface->h};
    SDL_RenderCopy(renderer, texture, NULL, &rect);
    SDL_DestroyTexture(texture);
    SDL_FreeSurface(surface);
}

int main(int argc, char* argv[]) {
    SDL_Init(SDL_INIT_VIDEO);
    TTF_Init();
    SDL_Window* window = SDL_CreateWindow("Notepad", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 800, 600, SDL_WINDOW_SHOWN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    SDL_Surface* surface = TTF_RenderText_Solid(font, "Hello World", color);
    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_Rect rect = {0, 0, surface->w, surface->h};
    SDL_RenderCopy(renderer, texture, NULL, &rect);
    SDL_DestroyTexture(texture);
    SDL_FreeSurface(surface);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    TTF_Quit();
    SDL_Quit();
    return 0;
}