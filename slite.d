module slite;

import derelict.sdl2.sdl;
import gui.gui;
import manip;
import command.command;
import cell.cell;

class Slite{
    // 使われるもの
    Window mainWindow; // guiは全部こいつが引き受ける
    SDL_Event event;
    CellBOX focused_table;

    // 使うもの
    KeyInterpreter cmd_interpreter;
    ManipTable manip_table;
    PageView page_view;
    ControlPanel con_pane;
    
    this(){
        mainWindow = new Window();
        cmd_interpreter = new KeyInterpreter(this);
        focused_table = new CellBOX(CellBOX.table_id);
        manip_table = new ManipTable(mainWindow,focused_table,&event);
        
        con_pane = new ControlPanel(mainWindow);
        page_view = new PageView(mainWindow,focused_table,manip_table);
         
        mainWindow.attach(con_pane);
        mainWindow.attach(page_view);

        mainWindow.Redraw(); // first draw 
    }
    void work(){
        SDL_PollEvent(&event);
        cmd_interpreter.execute();
    }
}
