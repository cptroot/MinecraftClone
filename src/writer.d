import std.stdio;
import std.typecons;
import std.conv;

import engine;
import font;
import ai;

class TextWriter {
  string[] textToWrite;

  this() {
    textToWrite = [/*"Today was a day like any other.",
    "I was making my commute north, alone, again.", 
    "The tunnel was long, and there was no end in sight for the boring job that paid me.",
    "What I didn't know was that this day was different.",
    "I thought I was alone, but was I?",*/ ""];

  }

  int frame;
  int count;
  int delay = 0;
  int line;
  int character = 0;
  int state = 0;

  bool init = false;

  void Update() {
    if (init) AI.instance.Update();
    if (textToWrite[line] == "" && !init) { AI.init(); init = true; }
    if (line >= textToWrite.length) return;
    
    switch (state) {
      case 0:
        count++;
        if (count == 1) {
          frame++;
          character++;
          count = 0;
        }
        if (character == textToWrite[line].length) state = 1;
        break;
      case 1:
        delay++;
        if (delay == 120) {
          character = 0;
          line++;
          state = 2;
          delay = 0;
        }
        break;
      case 2:
        delay++;
        if (delay == 60) {
          delay = 0;
          state = 0;
        }
      default:
        break;
    }
  }

  void Draw() {
    if (line >= textToWrite.length) return;
    if (textToWrite[line].length == 0) return;
    Font.instance.Draw(textToWrite[line][0..character], tuple(50, 50), 540);
  }
}