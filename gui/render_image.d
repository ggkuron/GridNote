module gui.imagebox;

import gui.render_box;
import cell.cell;
import shape.shape;
import shape.drawer;
import gui.gui;
import cell.image_box;
import cairo.Context;

class RenderImage : RenderBOX{
    ImageDrawer drawer;
    this(PageView pv){
        super(pv);
    }
    void setBOX(ImageBOX ib){
        auto frame = get_position(ib);
        ib.set_image(frame);
        drawer = new ImageDrawer(ib.image);
    }
    void render(Context cr){
        drawer.draw(cr);
    }
}
