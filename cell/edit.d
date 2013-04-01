import cell.cellobject;
import input.input;

class CellEditor{
    int start_point;
    int cursor;
    int lines;
    Text text;
    Text insert_text(TextBOX box){
        SDL_Event event;
        char[] text = box.text;
        char[] composition;

        bool done;
        SDL_StartTextInput();
        while(!done)
        {
            if(SDL_PollEvent(&event))
            {
                switch(event.type)
                {
                    case SDL_TEXTINPUT: // non IME text-input
                        text ~= event.text.text;
                        break;
                    case SDL_TEXTEDITING:   // composition is changed or started
                        composition = event.edit.text;
                        // cursor = event.edit.start;
                        // selection_len = event.edit.length;
                        break;
                }
                box.notify(); // notify to redraw
            }
        }
        return ;
    }

    }
    // private void setBOX(TextBOX box){
    //     cursor = box.cursor;
    //     text = box.text;
    //     lines = box.lines;
    // }
