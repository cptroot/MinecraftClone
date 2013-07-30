import std.stdio;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import engine;
import triangle;
import camera;

class Game : Engine {
  this(SDL_Window* window) {
    title = "Uprising";

    super(window);

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CW);

    AddComponent(new Camera());

    auto triangle = new Triangle();
    triangle.LoadResources();
    this.AddComponent(triangle);
  }
}