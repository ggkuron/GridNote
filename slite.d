module slite;

import gui.gui;
import manip;
import command.command;

class Slite{
    Window mainWindow; // guiは全部こいつが引き受ける
    KeyInterpreter cmd_interpreter;
    ManipTable manip_table;
    CellTable focused_table;
    
    this(){
        mainWindow = new Window();
        cmd_interpreter = new KeyInterpreter(this);
        focused_table = new CellTable();
        manip_table = new ManipTable(focused_table);
        
        mainWindow.attach(new ControlPanel(mainWindow));
        mainWindow.attach(new PageView(mainWindow,focused_table,manip_table));

        mainWindow.Redraw(); // first draw 
    }
    void work(){
        cmd_interpreter.execute();
    }
}
