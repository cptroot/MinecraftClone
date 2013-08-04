import std.stdio;
import std.typecons;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import engine;
import block;
import camera;
import error;

class Game : Engine {
  this(SDL_Window* window) {
    title = "Uprising";

    super(window);

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CW);

    Camera camera = new Camera();
    AddComponent(camera);

    camera.position = tuple(1.0f, 1.0f, 0.0f);
    camera.rotation = tuple(0.3f, 0.1f);

    auto block = new Block();
    block.LoadResources();
    this.AddComponent(block);
  }
}