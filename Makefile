# Makefile

PROJECTDIR = ./
SRC 	= env.d init.d gui/gui.d misc/draw_rect.d  misc/sdl_utils.d misc/direct.d userview.d cell/cell.d  command/command.d command/command_op.d
FLAGS	= -L-L/usr/local/lib -L-lDerelictUtil -L-lDerelictSDL2 -L-lSDL2 -L-lSDL2_ttf -L-lSDL2_mixer -L-lSDL2_image -L-lpthread 
OUT		= m

.PHONY : all
all : 
	@dmd -of$(OUT) $(SRC) $(FLAGS) 

.d.o :
	dmd -c $<

.PHONY : run
run :
	@./$(OUT)
.PHONY : clean
clean :
	@rm *.o
