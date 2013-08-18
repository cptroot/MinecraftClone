import std.stdio;
import std.typecons;
import std.math;

import derelict.sdl.sdl;
version(CLIENT)
import derelict.opengl.gl;

import component;
import player;
import bullet;
import rectangle;
import draw;

version(CLIENT)
import client;
version(SERVER)
import server;

class Rope : Bullet {
  bool moving = true;
  Player player;

  this(Tuple!(float, float) pos, Tuple!(float, float) velocity, Player player) {
    this.player = player;
    super(pos, velocity, cast(byte)player.ID);
  }

  this(Tuple!(float, float) pos, Tuple!(float, float) velocity, int ID) {
    int pID = ID >> 24;
    player = Engine.instance.GetComponent!Player(pID);
    if (player is null) {
      player = new Player(pID, "");
      Engine.instance.AddComponent(player);
    }
    super(pos, velocity, ID);
  }

  static int getID(int playerID) {
    return typeof(super).getID(playerID);
  }

  void Kill() {
    Engine.instance.RemoveComponent!Rope(ID);
  }

  override void Collide() {
    if (moving) {
      velocity = tuple(0f, 0f);
      player.AttachRope(id);
      moving = false;
    }
  }

  override void Draw() {
    version(CLIENT) {
    glColor4f(0, 0, 0, 1);
    DrawAARect(rect, -1.5f);

    auto unitVector = tuple(rect.pos[0] - player.rect.pos[0], rect.pos[1] - player.rect.pos[1]);
    float length = unitVector[0] * unitVector[0] + unitVector[1] * unitVector[1];
    length = sqrt(length);
    unitVector = tuple(unitVector[0] / length, unitVector[1] / length);

    glColor4f(.3f, .3f, .5f, 1f);

    glBegin(GL_QUADS);
    glVertex3f(rect.Center[0] - unitVector[1] * 2, rect.Center[1] + unitVector[0] * 2, -1.6f);
    glVertex3f(rect.Center[0] + unitVector[1] * 2, rect.Center[1] - unitVector[0] * 2, -1.6f);
    glVertex3f(player.rect.Center[0] + unitVector[1] * 2, player.rect.Center[1] - unitVector[0] * 2, -1.6f);
    glVertex3f(player.rect.Center[0] - unitVector[1] * 2, player.rect.Center[1] + unitVector[0] * 2, -1.6f);
    glEnd();
    }
  }
}