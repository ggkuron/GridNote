# Makefile

PROJECTDIR = ./
SRC 	= env.d init.d gui/*.d   manip.d cell/*.d  command/*.d  text/*.d shape/*.d util/*.d
FLAGS	= -L-L/usr/local/lib -L-lgtk-3 -L-lgtkd-2   -L-lpthread -L-lfreetype  -L-lcairo -version=CairoHasPngFunctions -unittest  -debug=collec -debug=cb -debug=cmd -debug=manip
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
