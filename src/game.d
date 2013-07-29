import std.stdio;

import derelict.opengl.gl;

import engine;
import player;
import font;
import wall;
import input;
import level;

class Game : Engine {
  this() {
    title = "Uprising";

    super();

    AddComponent(new Keyboard());
    AddComponent(new Mouse());

    AddComponent(new Player());

    Font f = new Font("images\\Font.fnt");
    AddComponent(f);

    AddComponent(new Level("levels\\level1.txt"));

    glClearColor(.2f, .2f, .2f, 1);
  }
}