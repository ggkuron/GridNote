module input.input;

pragma(lib,"/usr/local/lib/libDerelictUtil.a");
pragma(lib,"/usr/local/lib/libDerelictSDL2.a");

import std.stdio;
import derelict.sdl2.sdl;

class KeyInput{
    SDL_Event event;
    ubyte* keyState;
    SDL_Keymod keyMod;
    bool done;
    bool first_flg = true;
    string editing;
    string composition;
    int selection_len;
    int line;
    int cursor;
    private void keys_update(){
        SDL_WaitEvent(&event);
        keyState = SDL_GetKeyboardState(null);
        keyMod = SDL_GetModState();
    }
    bool writing(){
        keys_update();
        if(first_flg) start_input();
        else inputing();
        return done;
    }
    void start_input(){
        SDL_SetTextInputRect(null);
        SDL_StartTextInput();
        {
            switch(event.type)
            {
                case SDL_TEXTINPUT: // non IME text-input
                    first_flg = false;
                    editing ~= event.text.text[0];
                    break;
                case SDL_TEXTEDITING:   // composition is changed or started
                    composition = cast(string)event.edit.text;
                    cursor = event.edit.start;
                    selection_len = event.edit.length;
                    break;
                default:
                    writeln("which 1 am without concern");
                    break;
            }
        }
        return;
    }
    void inputing(){
        // SDL_WaitEvent(&event);
        switch(event.type)
        {
            case SDL_TEXTINPUT: // non IME text-input
                    editing ~= event.text.text[0];
                    ++cursor;
                if(event.text.text[0] == 'q') done = true;
                break;
            case SDL_TEXTEDITING:   // composition is changed or started
                writeln("in editing");
                composition = cast(string)event.edit.text;
                cursor = event.edit.start;
                selection_len = event.edit.length;
                break;
            default:
                writeln("which 2 am without concern");
                break;
        }
        if(done) SDL_StopTextInput();
    }
}

immutable int start_size_w = 960;
immutable int start_size_h = 640;

void main(){
   
    DerelictSDL2.load();
    if(SDL_Init(SDL_INIT_EVERYTHING)) assert(0);
    SDL_Window* window;
    SDL_Renderer* renderer;
    window = SDL_CreateWindow("test",
             SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,
             start_size_w,start_size_h,SDL_WINDOW_SHOWN);
    renderer = SDL_CreateRenderer(window,-1,SDL_RENDERER_ACCELERATED);
 
    KeyInput ki = new KeyInput();
    while(!ki.writing()){
        writeln(ki.editing);
        writeln(ki.composition);
    }
}



