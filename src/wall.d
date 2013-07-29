import std.stdio;
import std.typecons;
import std.conv;

version(CLIENT)
import derelict.opengl.gl;

import component;
import rectangle;
import draw;

class Wall : Component, Drawable {
  int id;
  static int maxID = 0;

  @property override int ID() {
    return id;
  }

  @property override float Depth() {
    return -2;
  }

  Rectangle rect;

  this() {
    id = maxID++;
  }

  this(Tuple!(float, float) pos, Tuple!(float, float) size) {
    rect = Rectangle(pos, size);
    this();
  }

  this(float x, float y, float width, float height) {
    rect = Rectangle(tuple(x, y), tuple(width, height));
    this();
  }

  this(Rectangle rectangle) {
    rect = rectangle;
    this();
  }

  this(string[] lines) {
    this(to!float(lines[0]),
    to!float(lines[1]),
    to!float(lines[2]),
    to!float(lines[3]));
  }

  void LoadResources() {};

  override void Draw() {
    version(CLIENT) {
    glColor4f(0, 0, 0, 1);
    DrawAARect(rect, -2);
    }
  }
}