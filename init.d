module init;

import gtk.Main;
import env;
import gui.gui;

import std.string;

immutable int start_size_w = 960;
immutable int start_size_h = 640;

void main(string[] args)
{
    Main.init(args);
    auto win = new Window();
    Main.run();
}
