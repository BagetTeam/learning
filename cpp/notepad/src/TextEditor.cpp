#include <include/TextEditor.hpp>
#include <cstdio>

namespace Editor
{
    SDL_AppResult TextEditor::handleEvent(const SDL_Event& event) {
        if (event.type == SDL_EVENT_QUIT) return SDL_APP_FAILURE;
        if (event.type == SDL_EVENT_KEY_DOWN) {
            SDL_Keycode key = event.key.key;
            
            if (key == SDLK_ESCAPE) {
                return SDL_APP_FAILURE;
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
        if (event.type == SDL_EVENT_WINDOW_RESIZED) {
            onResize(event.window.data1, event.window.data2);
        }
        return SDL_APP_CONTINUE;
    }

    void TextEditor::onResize(int w, int h) {

    }
} // namespace Editor
