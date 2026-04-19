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

class SDL3Renderer : public Renderer {
    public:
        SDL3Renderer(SDL_Window* window);
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
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        std::cout << "SDL_Init Error: " << SDL_GetError() << std::endl;
        return SDL_APP_FAILURE;
    }

    if (!TTF_Init()) {
        std::cout << "TTF_Init Error: " << SDL_GetError() << std::endl;
        return SDL_APP_FAILURE;
    }

    SDL_Window *window = NULL;
    SDL_Renderer *renderer = NULL;

    if (!SDL_CreateWindowAndRenderer("SDL3 Keyboard", 800, 600, 0, &window, &renderer)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    TTF_Font *font = TTF_OpenFont("FreeSans.ttf", 24);
    if (!font) {
        SDL_Log("Font load error: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // SDL_Window* window = SDL_CreateWindow("SDL3 is Working!", 640, 480, 0);    
    // if (!window) {
    //     std::cout << "Window Error: " << SDL_GetError() << std::endl;
    //     return 1;
    // }
    // SDL_Delay(10000);

    // SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    // SDL_Surface* surface = TTF_RenderText_Solid(font, "Hello World", color);
    // SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    // SDL_Rect rect = {0, 0, surface->w, surface->h};
    // SDL_RenderCopy(renderer, texture, NULL, &rect);
    // SDL_DestroyTexture(texture);
    // SDL_FreeSurface(surface);
    // SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    TTF_Quit();
    return 0;
}
