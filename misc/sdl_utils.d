module misc.sdl_utils;
import derelict.sdl2.sdl;

void SetRenderColor(SDL_Renderer* rend,SDL_Color color,ubyte alpha){
    SDL_SetRenderDrawColor(rend,color.r,color.g,color.b,alpha);
}
void RenderLine(SDL_Renderer* rend,SDL_Point start,SDL_Point end){
    SDL_RenderDrawLine(rend,start.x,start.y,end.x,end.y);
}
