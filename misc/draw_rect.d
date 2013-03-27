module misc.draw_rect;
import derelict.sdl2.sdl;
import std.string;

SDL_Texture* createTexture(SDL_Renderer* rend,string image_path)
{
    auto img = SDL_LoadBMP(image_path.toStringz);

    assert(img != null);
    auto texture = SDL_CreateTextureFromSurface(rend,img);
    SDL_FreeSurface(img);
    return texture;
}

void drawRect(SDL_Renderer* rend, SDL_Texture* tex,const SDL_Rect rect)
{
    SDL_RenderCopy(rend,tex,null,&rect);
}
