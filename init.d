module init;
pragma(lib,"/usr/local/lib/libDerelictUtil.a");
pragma(lib,"/usr/local/lib/libDerelictSDL2.a");

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import derelict.sdl2.mixer;
import derelict.sdl2.image;

import env;
import slite;

import std.string;
void Init()
{
    DerelictSDL2.load();
    if(SDL_Init(SDL_INIT_VIDEO|SDL_INIT_AUDIO|SDL_INIT_TIMER) !=0)
        return;
    DerelictSDL2ttf.load("./libSDL2_ttf.so");
    TTF_Init();
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
