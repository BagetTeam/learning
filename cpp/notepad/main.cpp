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