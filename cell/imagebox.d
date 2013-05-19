module cell.imagebox;

import cell.cell;
import cell.contentbox;
import cell.table;
import shape.shape;
import shape.drawer;
import cairo.Context;

import gui.pageview;

class ImageBOX : ContentBOX{
   // imageは実際には生成しない
   // Model であって Viewでない
    PageView pv;
    Image image;
    Rect frame;
    string filename;
    
    this(BoxTable table,string filepath)
        out{
        assert(pv);
        }
    body{
        super(table);
    }
    public Image get_image(){
        return image;
    }
    public void set_image(Rect frame)
        in{
        assert(frame);
        assert(filename);
        }
        out{
        assert(image);
        }
    body{
        image = new Image(filename,frame);
    }
    override bool is_to_spoil(){
        return false;
        // tobe implement
    }
}
