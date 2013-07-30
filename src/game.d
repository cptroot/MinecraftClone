import std.stdio;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import engine;
import triangle;

class Game : Engine {
  this(SDL_Window* window) {
    title = "Uprising";

    super(window);

    auto triangle = new Triangle();
    triangle.LoadResources();
    this.AddComponent(triangle);
  }
}