import std.stdio;
import std.typecons;

import derelict.sdl.sdl;

import component;

class Keyboard : Component, Updateable {
  bool[int] keys;
  bool[int] oldKeys;

  @property override int ID() {
    return 0;
  }

  bool Update(SDL_Event[] events) {
    oldKeys = keys.dup;
    foreach (event; events) {
      switch (event.type) {
        case SDL_KEYDOWN:
          keys[event.key.keysym.sym] = true;
          break;
        case SDL_KEYUP:
          keys[event.key.keysym.sym] = false;
          break;
        default:
          break;
      }
    }
    return false;
  }

  bool KeyDown(int keySymbol) { return GetKey(keySymbol); }

  bool KeyUp(int keySymbol) { return !GetKey(keySymbol); }

  private bool GetKey(int keySymbol) {
    if (keySymbol !in keys) {
      keys[keySymbol] = false;
      oldKeys[keySymbol] = false;
    }
    return keys[keySymbol];
  }

  bool KeyPressed(int keySymbol) {
    if (!GetKey(keySymbol)) return false;
    if (oldKeys[keySymbol] == false) return true;
    return false;
  }

  bool KeyReleased(int keySymbol) {
    if (GetKey(keySymbol)) return false;
    if (!oldKeys[keySymbol] == false) return true;
    return false;
  }
}

class Mouse : Component, Updateable {
  Tuple!(int, int) pos;

  bool[int] buttons;
  bool[int] oldButtons;

  @property override int ID() {
    return 0;
  }

  bool Update(SDL_Event[] events) {
    oldButtons = buttons.dup;
    foreach (event; events) {
      switch (event.type) {
        case SDL_MOUSEMOTION:
          pos[0] = event.motion.x;
          pos[1] = event.motion.y;
          break;
        case SDL_MOUSEBUTTONDOWN:
          buttons[event.button.button] = true;
          break;
        case SDL_MOUSEBUTTONUP:
          buttons[event.button.button] = false;
          break;
        default:
          break;
      }
    }
    return false;
  }

  private bool GetButton(int buttonSymbol) {
    if (buttonSymbol !in buttons) {
      buttons[buttonSymbol] = false;
      oldButtons[buttonSymbol] = false;
    }
    return buttons[buttonSymbol];
  }

  bool ButtonPressed(int buttonSymbol) {
    if (!GetButton(buttonSymbol)) return false;
    if (oldButtons[buttonSymbol] == false) return true;
    return false;
  }

  bool ButtonReleased(int buttonSymbol) {
    if (GetButton(buttonSymbol)) return false;
    if (!oldButtons[buttonSymbol] == false) return true;
    return false;
  }
}