import std.stdio;
import std.typecons;
import std.string;
import std.datetime;
import core.memory;

import derelict.opengl3.gl3;
import derelict.openal.al;
import derelict.sdl2.sdl;

import component;
import error;

public alias Engine.instance iEngine;

class Engine {
  static Engine instance;
  SDL_Window* window;

  Component[int][string] components;
  Updateable[int][string] updateList;
  Drawable[int][string] drawList;
  Drawable[] drawOrder;

  Tuple!(int, string)[] removal = [];

  string title = "Game";

  bool paused = false;

  void AddComponent(T)(T component) 
    if (is(T:Component)) {
    string type = typeid(T).toString();
    //if (type !in components) components[typeid(T).toString()] = new Component[string];
    components[type][component.ID] = component;
    if (is(T:Drawable)) {
      Drawable temp;
      if (type in drawList && component.ID in drawList[type])
        temp = drawList[type][component.ID];
      drawList[type][component.ID] = cast(Drawable)component;
      if (drawOrder.length > 0) {
        int i = 0;
        Drawable d = cast(Drawable)component;
        while (i < drawOrder.length && drawOrder[i] !is temp && drawOrder[i].Depth < d.Depth) i++;
        if (i < drawOrder.length && temp is drawOrder[i])
          drawOrder[i] = d;
        else 
          drawOrder = drawOrder[0..i] ~ d ~ drawOrder[i..$];
      } else {
        drawOrder ~= cast(Drawable)component;
      }
    }
    if (is(T:Updateable)) {
      //if (typeid(T).toString() !in updateList) updateList[typeid(T).toString()] = [];
      updateList[type][component.ID] = cast(Updateable)component;
    }
  }

  Component[int] GetComponents(T)()
    if (is(T:Component)) {
    if ((typeid(T).toString() in components)) return components[typeid(T).toString()];
    return null;
  }

  T GetComponent(T)()
    if (is(T:Component)) {
    if ((typeid(T).toString() in components)) return cast(T)components[typeid(T).toString()][components[typeid(T).toString()].keys[0]];
    return null;
  }

  T GetComponent(T)(int id) 
    if (is(T:Component)) {
    if ((typeid(T).toString() in components) && (id in components[typeid(T).toString()])) return cast(T)components[typeid(T).toString()][id];
    return null;
  }

  void RemoveComponent(T)(int id)
    if (is(T:Component)) {
    removal ~= tuple(id, typeid(T).toString());
  }

  private void DestroyComponent(int id, string type) {
    if ((type in components) && (id in components[type])) {
      components[type].remove(id);
      if (type in drawList) {
        Drawable r = drawList[type][id];
        drawList[type].remove(id);
        foreach (i, d; drawOrder) {
          if (d is r) {
            drawOrder = drawOrder[0..i] ~ drawOrder[i + 1..$];
            break;
          }
        }
      }
      if ((type in updateList)) {
        updateList[type].remove(id);
      }
    }
  }

  void Run() {
    uint oldTicks = SDL_GetTicks();
    uint currentTicks = SDL_GetTicks();
    uint elapsed = 16;
    uint taken = 0;
    bool quitting = false;
    while (!quitting) {
      elapsed = SDL_GetTicks() - oldTicks;
      oldTicks = SDL_GetTicks();
      quitting = Update();
      if (quitting) return;
      Draw();
			SDL_GL_SwapWindow(window);
      GC.collect();
      taken = SDL_GetTicks() - oldTicks;
      if (taken < 16)
        SDL_Delay(16 - taken);
    }
  }

  this(SDL_Window* window) {
    ALCdevice* ALDevice = alcOpenDevice(null); // select the "preferred device"
    ALCcontext* ALContext = alcCreateContext(ALDevice, null);
    alcMakeContextCurrent(ALContext);
    alListener3f(AL_POSITION, 0, 0, 0);
    alListener3f(AL_VELOCITY, 0, 0, 0);

    SDL_SetWindowTitle(window, toStringz(title));

    glClearColor(0, 0, 0, 0);

    this.window = window;

    instance = this;
  }

  this(SDL_Window* window, string title) {
    this.title = title;
    this(window);
  }

  bool Update() {
    SDL_Event event;
    SDL_Event[] events;
    bool result = false;
    while (SDL_PollEvent(&event)) {
      events ~= event;
      if (event.type == SDL_QUIT) result = true;
    }
	  if (!paused) {
      foreach (uList; updateList) {
        foreach (u; uList) {
          result |= u.Update(events);
        }
      }
	  }

    foreach (id; removal) {
      DestroyComponent(id[0], id[1]);
    }
    removal = [];
    return result;
  }

  void Draw() {
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    PreProcess();
    foreach (d; drawOrder) {
      d.Draw();
    }
    PostProcess();
  }

  void PreProcess() {};
  void PostProcess() {};
}