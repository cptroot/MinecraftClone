import std.stdio;
import std.typecons;

version(CLIENT)
import derelict.opengl.gl;

import rectangle;

void DrawAARect(Rectangle rect, float depth) {
  version(CLIENT) {
  glBegin(GL_QUADS);
  glVertex3f(rect.Left, rect.Top, depth);
  glVertex3f(rect.Left, rect.Bottom, depth);
  glVertex3f(rect.Right, rect.Bottom, depth);
  glVertex3f(rect.Right, rect.Top, depth);
  glEnd();
  }
}