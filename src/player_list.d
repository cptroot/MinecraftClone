import std.stdio;
import std.typecons;
import std.conv;

import derelict.sdl.sdl;

import util;
import component;
import client;
import input;
import font;
import player;

class PlayerList : Component, Updateable, Drawable {
  @property int ID() { return 0; }

  @property float Depth() {
    return -1;
  }

  Keyboard keys;

  string[] players;
  bool display = false;

  Font font;

  void LoadResources() {};

  bool Update(SDL_Event[] events) {
    if (keys is null) {
      keys = Engine.instance.GetComponent!Keyboard();
    }

    if (keys.KeyDown(SDLK_BACKSLASH)) {
      display = true;
    } else { display = false; }

    if (display) {
      players = [];
      foreach (c; Engine.instance.GetComponents!Player()) {
        Player p = cast(Player)c;
        players ~= p.username;
      }
    }
    return false;
  }

  void Draw() {
    if (! display) return;
    if (font is null) font = Engine.instance.GetComponent!Font();
    foreach (i, username; players) {
      font.Draw(username, tuple(200, 50 + 40 * to!int(i)), 240);
    }
  }
}