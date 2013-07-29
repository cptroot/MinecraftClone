import std.stdio;
import std.typecons;
import std.conv;

import derelict.sdl.sdl;

import client;
import component;
import input;

class Resolution : Component, Updateable {
  bool isFullScreen = false;
  Tuple!(ushort, ushort) resolution;
  Tuple!(ushort, ushort)[] resolutions;
  @property int ID() { return 0; };

  this() {
    SDL_Rect** temp = SDL_ListModes(null, SDL_FULLSCREEN);
    SDL_Rect[] rects;
    for (int i = 0; temp[i]; i++) {
      rects ~= *temp[i];
    }
    foreach (rect; rects) {
      resolutions ~= tuple(rect.w, rect.h);
    }
  }

  bool Update(SDL_Event[] events) {
    if ((Engine.instance.GetComponent!Keyboard()).KeyPressed(SDLK_F11)) {
      isFullScreen = !isFullScreen;
      uint flags = SDL_OPENGL;
      if (isFullScreen) {
        flags |= SDL_FULLSCREEN;
        //resolution = resolutions[0];
      } else {
        resolution = tuple(to!ushort(640u), to!ushort(480u));
      }
      
      if (SDL_SetVideoMode(resolution[0], resolution[1], 32, flags) is null) throw new Exception("WTF?");;
      string error;
      error = to!string(SDL_GetError());
      writeln(error);
      Engine.instance.LoadGL();
      foreach (dList; Engine.instance.drawList) {
        foreach (d; dList) {
          d.LoadResources();
        }
      }

      writeln("Done reloading.");
    }
    return false;
  }
}