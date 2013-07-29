import std.stdio;
import std.array;
import std.conv;
import std.typecons;
import std.file;
import std.string;

import derelict.opengl.gl;

import util;
import component;

//For use with the BMFont program.

class Font : Component, Drawable {
  Character[int] font;

  int lineHeight, scaleW, scaleH;

  string[] fileNames;
  uint[] textures;

  int id;
  static int maxID;

  static string[int] names;

  @property override int ID() {
    return id;
  }
  @property float Depth() { return -1f; };

  this(string fileName) {
    id = maxID++;
    names[id] = fileName;

    File fnt = File(fileName, "r");
    string[] args;
    int[] values;
    foreach (line; fnt.byLine()) {
      args = to!(string[])(split(line));
      values = [];
      int i = 0;
      foreach (arg; args) {
        if (i == 0) {
          i++;
          continue;
        }
        string[] halves = split(arg, "=");
        if (halves.length > 1 && isNumeric(halves[1]))
          values ~= parse!int(split(arg, "=")[1]);
      }
      switch(line[0..5]) {
        case "char ":
          font[values[0]] = Character(values[1], values[2], values[3], values[4], values[5], values[6], values[7]);
          break;
        case "commo":
          lineHeight = values[0];
          scaleW = values[2];
          scaleH = values[3];
          break;
        case "page ":
          fileNames ~= "images\\" ~ removechars(split(args[2], "=")[1], "\"");
        case "info ":
          names[id] = to!string(split(line, "\"")[1]);
        default:
          break;
      }
    }
    LoadResources();
  }

  void LoadResources() {
    textures = [];
    foreach (name; fileNames) {
      textures ~= 0;
      LoadGLTextures(name, textures[$-1], GL_LINEAR, GL_NEAREST);
    }
  }

  int stringWidth(string text) {
    int result;
    foreach (i, c; text) {
      if (i != text.length - 1) result += font[c].xadvance;
      else result += font[c].width;
    }
    return result;
  }
  
  void Draw() {};

  void Draw(string text, Tuple!(int, int) pos, int width, bool absolute = true) {
    Tuple!(int, int) current = pos;

    glPushMatrix();
    if (absolute) { glLoadIdentity();
    glTranslatef(-320, -240, 0); };
    glEnable(GL_TEXTURE_2D);
    
    glBindTexture(GL_TEXTURE_2D, textures[0]);

    glBegin(GL_QUADS);
    foreach (i, c; text) {
      if (current[0] + font[c].width > width + pos[0]) {
        current[0] = pos[0];
        current[1] += lineHeight;
      }
      glTexCoord2f(cast(float)font[c].x / scaleW, cast(float)font[c].y / scaleH); glVertex3f(current[0] + font[c].xoffset, current[1] + font[c].yoffset, -1);
      glTexCoord2f(cast(float)(font[c].x + font[c].width) / scaleW, cast(float)font[c].y / scaleH); glVertex3f(current[0] + font[c].xoffset + font[c].width, current[1] + font[c].yoffset, -1);
      glTexCoord2f(cast(float)(font[c].x + font[c].width) / scaleW, cast(float)(font[c].y + font[c].height) / scaleH); glVertex3f(current[0] + font[c].xoffset + font[c].width, current[1] + font[c].yoffset + font[c].height, -1);
      glTexCoord2f(cast(float)font[c].x / scaleW, cast(float)(font[c].y + font[c].height) / scaleH); glVertex3f(current[0] + font[c].xoffset, current[1] + font[c].yoffset + font[c].height, -1);
      current[0] += font[c].xadvance;
    }
    glEnd();
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
  }
}

struct Character {
  int x, y, width, height, xoffset, yoffset, xadvance;
}