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

struct AppContext {
    Window* window;
    Renderer* renderer;
    TextEditor* textEditor;
        
    TTF_Font* font_n = nullptr;
    TTF_Font* font_b = nullptr;
    TTF_Font* font_i = nullptr;
    TTF_Font* font_bi = nullptr;

    std::string text;

    
};

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

bool loadFonts(AppContext* ctx, int size) {
    ctx->font_n = TTF_OpenFont("assets/FreeSans.ttf", size);
    if (!ctx->font_n) {
        SDL_Log("Normal Font load error: %s", SDL_GetError());
        return false;
    }
    ctx->font_b = TTF_OpenFont("assets/FreeSansBold.ttf", size);
    if (!ctx->font_b) {
        SDL_Log("Bold Font load error: %s", SDL_GetError());
        return false;
    }
    ctx->font_i = TTF_OpenFont("assets/FreeSansOblique.ttf", size);
    if (!ctx->font_i) {
        SDL_Log("Oblique Font load error: %s", SDL_GetError());
        return false;
    }
    ctx->font_bi = TTF_OpenFont("assets/FreeSansBoldOblique.ttf", size);
    if (!ctx->font_bi) {
        SDL_Log("Bold Oblique Font load error: %s", SDL_GetError());
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

    AppContext* ctx = new AppContext();
    *appstate = ctx;

    ctx->window = new Window(win);
    ctx->renderer = new Renderer(rend);
    ctx->textEditor = new TextEditor();

    if (!loadFonts(ctx, 24)) {
        return SDL_APP_FAILURE;
    }

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event) {
    if (appstate) {
        AppContext* ctx = (AppContext*)appstate;
        return ctx->textEditor->handleEvent(*event);
    }
    return SDL_APP_FAILURE;
}

SDL_AppResult SDL_AppIterate(void *appstate) {
    if (!appstate) return SDL_APP_FAILURE;
    AppContext* ctx = (AppContext*)appstate;
    SDL_Color white = {255, 255, 255, 255};
    SDL_Surface *surface = TTF_RenderText_Blended(ctx->font_n, "Hello, SDL3!", 0, white);
    SDL_Texture *texture = SDL_CreateTextureFromSurface(ctx->renderer->get(), surface);
    SDL_DestroySurface(surface);

    float tw, th;
    SDL_GetTextureSize(texture, &tw, &th);
    SDL_FRect dst = {100.0f, 100.0f, tw, th};

    SDL_SetRenderDrawColor(ctx->renderer->get(), 30, 30, 30, 255);
    SDL_RenderClear(ctx->renderer->get());

    SDL_RenderTexture(ctx->renderer->get(), texture, NULL, &dst);
    SDL_RenderPresent(ctx->renderer->get());
    

    SDL_DestroyTexture(texture);
    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, SDL_AppResult result) {
    if (appstate) {
        AppContext* ctx = (AppContext*)appstate;
        
        TTF_CloseFont(ctx->font_n);
        TTF_CloseFont(ctx->font_b);
        TTF_CloseFont(ctx->font_i);
        TTF_CloseFont(ctx->font_bi);
        
        delete ctx;
    }
    SDL_DestroyRenderer(rend);
    SDL_DestroyWindow(win);
    TTF_Quit();
    SDL_Quit();
}