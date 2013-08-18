import std.stdio;
import std.typecons;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import engine;
import block;
import player;
import error;

class Game : Engine {
  this(SDL_Window* window) {
    title = "Uprising";

    SDL_SetWindowGrab(window, true);
    SDL_ShowCursor(false);

    super(window);

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CW);

    Player player = new Player();
    this.AddComponent(player);

    auto block = new Block();
    block.LoadResources();
    this.AddComponent(block);
  }
}