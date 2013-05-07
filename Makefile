# Makefile

PROJECTDIR = ./
SRC 	= env.d init.d gui/*.d misc/*.d  manip.d cell/*.d  command/*.d  text/*.d shape/* input_method.d
FLAGS	= -L-L/usr/local/lib -L-lgtk-3 -L-lgtkd-2   -L-lpthread -L-lfreetype  -L-lcairo -version=CairoHasPngFunctions -unittest -debug=cell -debug=manip -debug=cmd -debug=text -debug=gui
OUT		= exe

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
