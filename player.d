module player;

import std.typecons;
import std.algorithm;
import std.stdio;

import derelict.sdl2.sdl;

import engine;
import component;
import error;

import camera;
import matrix;
import input;

class Player : Component, Updateable {
  @property int ID() { return 0; }

  Camera camera;

  auto keyboard = new Keyboard();

  //auto screenSize;

  this() {
    camera = new Camera();
    iEngine.AddComponent(camera);

    iEngine.AddComponent(keyboard);

    position = Vector3(0.0f, 1.0f, 0.0f);
  }

  private bool result;

  private auto position = Vector3();
  private auto rotation = SphereRot();

  private int x, y;
  bool Update(SDL_Event[] events) {
    result = false;

    if (keyboard.KeyPressed(SDLK_ESCAPE)) 
      return true;

    auto keys = ["a": keyboard.KeyDown(SDLK_a),
      "d": keyboard.KeyDown(SDLK_d),
      "w": keyboard.KeyDown(SDLK_w),
      "s": keyboard.KeyDown(SDLK_s)];
    if (keys["w"]) {
      position = position + camera.forward * .1f;
    }

    if (keys["s"]) {
      position = position - camera.forward * .1f;
    }

    if (keys["a"]) {
      position = position + camera.left * .1f;
    }

    if (keys["d"]) {
      position = position - camera.left * .1f;
    }

    camera.position = position;

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