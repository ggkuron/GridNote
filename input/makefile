# Makefile

PROJECTDIR = ./
SRC 	= demo.d
FLAGS	= -L-L/usr/local/lib -L-lDerelictUtil -L-lDerelictSDL2 -L-lSDL2 -L-lSDL2_ttf -L-lSDL2_mixer -L-lSDL2_image -L-lpthread -L-lfreetype -L-lcairo
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
