import derelict.sdl2.sdl;
import deimos.cairo.cairo;
import deimos.cairo.svg;
import std.string;

enum M_PI = 3.14159265358979323846;


void draw_text(cairo_t* cr, string text, double x, double y)
{
	// save the state of the context:
	cairo_save(cr);

	// draw black text
	cairo_set_source_rgb(cr, 0, 0, 0);
	cairo_select_font_face (cr, "Sans", CairoFontSlant.Normal, CairoFontWeight.Bold);
	cairo_set_font_size (cr, 20.0);
	cairo_move_to(cr, x, y);
	cairo_show_text(cr, toStringz(text));

	cairo_restore(cr);
}

void main(){
 	int width = 256;
	int height = 256;
    SDL_Rect all = SDL_Rect(0,0,width,height);
  
    DerelictSDL2.load();
    if(SDL_Init(SDL_INIT_EVERYTHING)) assert(0);
    SDL_Window* window;
    SDL_Renderer* renderer;

    window = SDL_CreateWindow("test",
             SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,
             width,height,SDL_WINDOW_SHOWN);
    renderer = SDL_CreateRenderer(window,-1,SDL_RENDERER_ACCELERATED);

    auto sdl_srf = SDL_GetWindowSurface(window);

    auto srf = cairo_image_surface_create_for_data
        (cast(char*)sdl_srf.pixels,CairoFormat.ARGB32,width,height,sdl_srf.pitch);

	cairo_t *cr;
	cairo_pattern_t *pat;

	// surface = cairo_svg_surface_create("demo.svg", width, height);
	cr = cairo_create(srf);

	/* from http://cairographics.org/samples/ */
	pat = cairo_pattern_create_linear (0.0, 0.0,  0.0, height);
	cairo_pattern_add_color_stop_rgba (pat, 1, 0, 0, 0, 1);
	cairo_pattern_add_color_stop_rgba (pat, 0, 1, 1, 1, 1);
	cairo_rectangle (cr, 0, 0, 256, 256);
	cairo_set_source (cr, pat);
	cairo_fill (cr);
	cairo_pattern_destroy (pat);
    auto txt = SDL_CreateTextureFromSurface(renderer,sdl_srf);
    SDL_RenderCopy(renderer,txt,null,&all);
    SDL_RenderPresent(renderer);
    SDL_Delay(1000);


	auto half = height/2;
	pat = cairo_pattern_create_radial (115.2, 102.4, 25.6, 102.4, 102.4, height/2);
	cairo_pattern_add_color_stop_rgba (pat, 0, 1, 1, 1, 1);
	cairo_pattern_add_color_stop_rgba (pat, 1, 0, 0, 0, 1);
	cairo_set_source (cr, pat);
	cairo_arc (cr, half, half, 76.8, 0, 2 * M_PI);
	cairo_fill (cr);
	cairo_pattern_destroy (pat);

	cairo_show_page(cr);
    draw_text(cr, "hello svg", 80, half);
    txt = SDL_CreateTextureFromSurface(renderer,sdl_srf);
    SDL_RenderCopy(renderer,txt,null,&all);
    SDL_RenderPresent(renderer);
    SDL_Delay(1000);

	cairo_destroy(cr);

	cairo_surface_destroy(srf);
}




