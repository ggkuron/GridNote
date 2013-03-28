import derelict.sdl2.sdl;

string appname = "slite";
ubyte alpha_master_value =255;
int windowWidth = 960;
int windowHeight = 640;
int gridSpace = 40;
int emphasizedLineWidth = 2;
SDL_Color grid_color = {48,48,48};
SDL_Color emphasizedLineColor = {255,0,0};
SDL_Color focused_grid_color = {255,0,0};
ubyte grid_alpha = 255;

immutable int Tipsize = 64;
immutable ubyte Frames = 60;

SDL_Scancode MOVE_L_KEY = SDL_SCANCODE_H;
SDL_Scancode MOVE_R_KEY = SDL_SCANCODE_L;
SDL_Scancode MOVE_U_KEY = SDL_SCANCODE_K;
SDL_Scancode MOVE_D_KEY = SDL_SCANCODE_J;
SDL_Scancode EXIT_KEY = SDL_SCANCODE_Q;
