#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <iostream>
#include <thread>


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

// SDL3Renderer::SDL3Renderer(SDL_Window* window) {
//     this->window = window;
// }

// void SDL3Renderer::drawText(std::string text, int x, int y) {
//     SDL_Surface* surface = TTF_RenderText_Solid(font, text.c_str(), color);
//     SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
//     SDL_Rect rect = {x, y, surface->w, surface->h};
//     SDL_RenderCopy(renderer, texture, NULL, &rect);
//     SDL_DestroyTexture(texture);
//     SDL_FreeSurface(surface);
// }

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
        int a = 5;
    }

    SDL_Color white = {255, 255, 255, 255};
    SDL_Surface *surface = TTF_RenderText_Blended(font, "Hello, SDL3!", 0, white);
    SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_DestroySurface(surface);

    float tw, th;
    SDL_GetTextureSize(texture, &tw, &th);
    SDL_FRect dst = {100.0f, 100.0f, tw, th};

    // Main loop
    bool running = true;
    SDL_Event event;
    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) running = false;
            if (event.type == SDL_EVENT_KEY_DOWN) {
                SDL_Keycode key = event.key.key;
                
                if (key == SDLK_ESCAPE) {
                    running = false;
                }
                
                if (key == SDLK_W) {
                    printf("W pressed\n");
                }
            }
            if (event.type == SDL_EVENT_KEY_UP) {
                SDL_Keycode key = event.key.key;
                
                if (key == SDLK_W) {
                    printf("W released\n");
                }
            }
        }
        SDL_SetRenderDrawColor(renderer, 30, 30, 30, 255);
        SDL_RenderClear(renderer);

        SDL_RenderTexture(renderer, texture, NULL, &dst);

        SDL_RenderPresent(renderer);
    }

    SDL_DestroyTexture(texture);
    TTF_CloseFont(font);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    TTF_Quit();
    SDL_Quit();
    return 0;
}
