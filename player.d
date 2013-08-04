module player;

import std.typecons;
import std.algorithm;
import std.stdio;

import derelict.sdl2.sdl;

import engine;
import component;
import error;

import camera;

class Player : Component, Updateable {
  @property int ID() { return 0; }

  Camera camera;

  auto rotation = SphereRot();

  //auto screenSize;

  this() {
    camera = new Camera();
    iEngine.AddComponent(camera);


  }

  private bool result;

  private int x, y;
  bool Update(SDL_Event[] events) {
    result = false;

    foreach (event; events) {
      switch (event.type) {
        case SDL_KEYDOWN:
          if (event.key.keysym.sym == SDLK_ESCAPE)
            result = true;
        default:
          break;
      }
    }

    SDL_GetMouseState(&x, &y);

    x = 320 - x;
    y = 240 - y;

    rotation = camera.rotation;
    rotation[0] += x * .0015f;
    rotation[1] += y * .0015f;
    camera.rotation = rotation;

    if (x != 0 || y != 0)
      SDL_WarpMouseInWindow(iEngine.window, 320, 240);

    return result;
  }
}