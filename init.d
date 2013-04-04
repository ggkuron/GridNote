module init;
pragma(lib,"/usr/local/lib/libDerelictUtil.a");
pragma(lib,"/usr/local/lib/libDerelictSDL2.a");

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
// import derelict.sdl2.mixer;
// import derelict.sdl2.image;

import env;
import slite;

import std.string;
void Init()
{
    DerelictSDL2.load();
    DerelictSDL2ttf.load("/usr/local/lib/libSDL2_ttf.so");
    if(SDL_Init(SDL_INIT_VIDEO|SDL_INIT_AUDIO|SDL_INIT_TIMER) !=0)
        assert(0);
    TTF_Init();
    assert(TTF_WasInit());
}
void Quit()
{
    SDL_Quit();
    TTF_Quit();
}

void main()
{
    Init();
    Slite slite = new Slite();
    while(1){
        slite.work();
    }
    Quit();
}
