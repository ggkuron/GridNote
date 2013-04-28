import gdk.Keysyms;


// どっかで管理されるべき値達
//  を列挙していってる

string appname = "slite";
ubyte alpha_master_value =255;
int windowWidth = 960;
int windowHeight = 640;
// int gridSpace = 40;

immutable int Tipsize = 64;
immutable ubyte Frames = 60;

uint  MOVE_L_KEY = GdkKeysyms.GDK_h;
uint  MOVE_R_KEY = GdkKeysyms.GDK_l;
uint  MOVE_U_KEY = GdkKeysyms.GDK_k;
uint  MOVE_D_KEY = GdkKeysyms.GDK_j;
uint  EXIT_KEY = GdkKeysyms.GDK_w;
uint  DELETE_KEY = GdkKeysyms.GDK_x;
uint  INSERT_KEY = GdkKeysyms.GDK_i;

string control_deco = "decoration/decoE.png";
