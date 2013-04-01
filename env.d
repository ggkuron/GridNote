import derelict.sdl2.sdl;

// どっかで管理されるべき値達
//  を列挙していってる

string appname = "slite";
ubyte alpha_master_value =255;
int windowWidth = 960;
int windowHeight = 640;
int gridSpace = 40;

immutable int Tipsize = 64;
immutable ubyte Frames = 60;

SDL_Scancode MOVE_L_KEY = SDL_SCANCODE_H;
SDL_Scancode MOVE_R_KEY = SDL_SCANCODE_L;
SDL_Scancode MOVE_U_KEY = SDL_SCANCODE_K;
SDL_Scancode MOVE_D_KEY = SDL_SCANCODE_J;
SDL_Scancode EXIT_KEY = SDL_SCANCODE_Q;
SDL_Scancode DELETE_KEY = SDL_SCANCODE_X;

string control_deco = "decoration/deco.bmp";
