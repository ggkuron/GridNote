module misc.sdl_utils;
import derelict.sdl2.sdl;

void SetRenderColor(SDL_Renderer* rend,SDL_Color color,ubyte alpha){
    SDL_SetRenderDrawColor(rend,color.r,color.g,color.b,alpha);
}

