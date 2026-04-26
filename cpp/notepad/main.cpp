#define SDL_MAIN_USE_CALLBACKS 1

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <iostream>
#include <thread>
#include <include/Window.hpp>
#include <include/Renderer.hpp>
#include <include/TextEditor.hpp>

using namespace Editor; 
Window window;
Renderer renderer;
TextEditor textEditor;
SDL_Window *win = NULL;
SDL_Renderer *rend = NULL;

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

#define WINDOW_WIDTH 800
#define WINDOW_HEIGHT 600

bool loadFonts(int size) {
    TTF_Font *font_n = TTF_OpenFont("assets/FreeSans.ttf", size);
    TTF_Font *font_b = TTF_OpenFont("assets/FreeSansBold.ttf", size);
    
    if (!font) {
        SDL_Log("Font load error: %s", SDL_GetError());
        return false;
    }
    return true;
}

SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[]) {
    SDL_SetAppMetadata("Notepad app for learning", "1.0", "Notepad.ewen.inc");

    if (!SDL_Init(SDL_INIT_VIDEO)) {
        std::cout << "SDL_Init Error: " << SDL_GetError() << std::endl;
        return SDL_APP_FAILURE;
    }

    if (!TTF_Init()) {
        std::cout << "TTF_Init Error: " << SDL_GetError() << std::endl;
        return SDL_APP_FAILURE;
    }

    if (!SDL_CreateWindowAndRenderer("Notepad ewen", WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_RESIZABLE, &win, &rend)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    SDL_SetRenderLogicalPresentation(rend, WINDOW_WIDTH, WINDOW_HEIGHT, SDL_LOGICAL_PRESENTATION_LETTERBOX);

    window = Window(win);
    renderer = Renderer(rend);
    textEditor = TextEditor();

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event) {
    return textEditor.handleEvent(*event);
}

SDL_AppResult SDL_AppIterate(void *appstate) {
    SDL_Color white = {255, 255, 255, 255};
    SDL_Surface *surface = TTF_RenderText_Blended(font, "Hello, SDL3!", 0, white);
    SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_DestroySurface(surface);

    float tw, th;
    SDL_GetTextureSize(texture, &tw, &th);
    SDL_FRect dst = {100.0f, 100.0f, tw, th};

    // Main loop
    TextEditor editor = TextEditor();
    bool running = true;
    SDL_Event event;
    while (running) {
        while (SDL_PollEvent(&event)) {
            editor.handleEvent(event);
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
