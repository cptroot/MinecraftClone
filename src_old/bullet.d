import std.stdio;
import std.typecons;
import std.conv;

import derelict.sdl.sdl;
version(CLIENT)
import derelict.opengl.gl;

import component;
import rectangle;
import wall;
import draw;
import player;

version(CLIENT)
import client;
version(SERVER)
import server;

class Bullet : Component, Drawable, Updateable {
  bool sent = false;
  Rectangle rect;
  Tuple!(float, float) velocity;

  int id = 0;
  static int maxid = 0;

  @property override int ID() {
    return id;
  }

  @property override float Depth() {
    return -1.5f;
  }

  this() {
    id = maxid++;
  }

  this(int ID) {
    this.id = ID;
  }

  static int getID(int playerID) {
    int id = playerID;
    id <<= 24;
    id += maxid++;
    if (maxid > 1 << 24) {
      maxid = 0;
    }
    return id;
  }

  bool dead = false;

  this(Tuple!(float, float) pos, Tuple!(float, float) velocity, int ID) {
    rect = Rectangle(pos, tuple(10f, 10f));
    this.velocity = velocity;
    this(ID);
  }

  void LoadResources() {};

  override bool Update(SDL_Event[] events) {
    if (dead) writeln("still Alive");
    Wall w;
    float tmin0 = float.max;
    float tmin1 = float.max;
    foreach (c; Engine.instance.GetComponents!Wall()) {
      w = cast(Wall)c;
      foreach (r; Collision(rect, velocity, w.rect)) {
        if (r[1] == 0) {
          if (r[0] >= 0 && r[0] < tmin0) {
            tmin0 = r[0];
          }
        } 
        if (r[1] == 1) {
          if (r[0] >= 0 && r[0] < tmin1) {
            tmin1 = r[0];
          }
        }
      }
    }
    Player p;
    Player minP = null;
    foreach (c; Engine.instance.GetComponents!Player()) {
      p = cast(Player)c;
      if (p.ID == ID >> 24) continue;
      foreach (r; Collision(rect, velocity, p.rect)) {
        if (r[1] == 0) {
          if (r[0] >= 0 && r[0] < tmin0) {
            tmin0 = r[0];
            if (tmin0 < tmin1)
              minP = p;
          }
        } 
        if (r[1] == 1) {
          if (r[0] >= 0 && r[0] < tmin1) {
            tmin1 = r[0];
            if (tmin1 < tmin0)
              minP = p;
          }
        }
      }
    }

    if (tmin0 < 1 || tmin1 < 1) {
      if (tmin0 < tmin1) {
        rect.pos[0] += velocity[0] * tmin0;
        rect.pos[1] += velocity[1] * tmin0;
      } else {
        rect.pos[0] += velocity[0] * tmin1;
        rect.pos[1] += velocity[1] * tmin1;
      }
      Collide();

      if (minP !is null) {
        version(SERVER)
          minP.Damage(10);
      }
    } else {
      rect.pos[0] += velocity[0];
      rect.pos[1] += velocity[1];
    }
    return false;
  }

  override void Draw() {
    version(CLIENT) {
    glColor4f(0, 0, 0, 1);
    DrawAARect(rect, -1.5f);
    }
  }

  void Collide() {
    dead = true;
    Engine.instance.RemoveComponent!Bullet(ID);
  }
}