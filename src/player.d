import std.stdio;
import std.conv;
import std.typecons;
import std.math;
import std.random;

import derelict.sdl.sdl;
version(CLIENT)
  import derelict.opengl.gl;

import input;
import component;
import draw;
import rectangle;
import wall;
version(CLIENT)
import font;
import bullet;
import rope;
import spawnZone;
import killZone;
import udpio;
import udpnames;

version(CLIENT)
import client;
version(SERVER)
import server;

enum State {
  in_air,
  on_ground,
  on_wall,
  climbing_corner,
  ninja_rope
}

class Player : Component, Updateable, Drawable {

  @property override float Depth() {
    return -1;
  }

  @property override int ID() {
    return id;
  }

  int id = 0;
  bool isPlayer = false;

  Rectangle rect;
  Tuple!(float, float) velocity;

  State state = State.in_air;
  int animationCounter;
  float[] animationParameters;

  bool dead = false;
  bool floor;
  bool wall;
  int wallSide;
  Rope rope;
  int health = 100;
  int respawn = 0;
  string username;

  int Health(int h) {
    health = h;
    if (health <= 0)
      dead = true;
    return health;
  }

  Keyboard keys;
  Mouse mouse;

  const float gravity = .8f;
  const float jumpForce = 14f;
  const float moveSpeed = 8.0f;
  const float airMoveSpeed = .4f;
  const float horizAccel = .8f;

  this() {
    rect = Rectangle(tuple(-10f, -20f), tuple(20f, 40f));
    velocity = tuple(0, 0);
  }

  this(int ID, string username) {
    this.username = username;
    id = ID;
    this();
  }

  this(int ID, bool isPlayer, string username) {
    this.isPlayer = isPlayer;
    if (isPlayer) dead = true;
    id = ID;
    this.username = username;
    this();
  }

  void LoadResources() {};

  void AttachRope(int id) {
    state = State.ninja_rope;
    rope = Engine.instance.GetComponent!Rope(id);
  }

  void Damage(int damage) {
    version(CLIENT) {
    health -= damage;
    if (health <= 0) {
      dead = true;
      health = 0;
      respawn = 120;
      byte[] packet;
      packet ~= UDP.die;
      packet ~= to!byte(id);
      Engine.instance.AddPacket(packet);
    }
    }
    version(SERVER) {
    //writeln("damage");
    byte[] packet;
    packet ~= UDP.damage;
    packet ~= writeInt(damage);
    Engine.instance.AddPacket(packet, id);
    }
  }

  void spawn() {
    if (!isPlayer) return;
    Component[int] components = Engine.instance.GetComponents!SpawnZone();
    if (components is null) return;
    writeln("Spawn: ", components.keys.length);
    int index = uniform(0, components.keys.length);
    SpawnZone s = cast(SpawnZone)components[components.keys[index]];
    float x = uniform(0, s.rect.size[0] - 20) + s.rect.pos[0];
    float y = uniform(0, s.rect.size[1] - 40) + s.rect.pos[1];
    rect.pos = tuple(x, y);
    state = State.in_air;
    if (rope !is null){
      rope.Kill();
      byte[] packet;
      packet ~= UDP.disconnect_ninja_rope;
      packet ~= writeInt(rope.ID);
      Engine.instance.AddPacket(packet);
    }

    health = 100;

    version(CLIENT) {
      Engine.instance.camera.xpos = -rect.pos[0] - rect.size[0] / 2;
      Engine.instance.camera.ypos = -rect.pos[1] - rect.size[1] / 2;
    }

    dead = false;
    Engine.instance.AddPacket([cast(byte)UDP.respawn, to!byte(id)]);
  }

  override bool Update(SDL_Event[] events) {
    if (dead) {
      if (respawn < 0) {
        spawn();
      } else {
        respawn--;
      }
      return false;
    }
    //writeln("Player Update");
    if (keys is null) keys = Engine.instance.GetComponent!Keyboard();
    if (mouse is null) mouse = Engine.instance.GetComponent!Mouse();

    if (keys.KeyPressed(SDLK_r)) {
      dead = true;
      respawn = 120;
      return false;
    }

    switch (state) {
      case State.ninja_rope: 
        if (keys.KeyPressed(SDLK_UP) ||
          keys.KeyPressed(SDLK_SPACE) ||
          keys.KeyPressed(SDLK_w)) {
          state = State.in_air;
          rope.Kill();
          byte[] packet;
          packet ~= UDP.disconnect_ninja_rope;
          packet ~= writeInt(rope.ID);
          Engine.instance.AddPacket(packet);
        }

        //writeln("Case 0");
        velocity[1] += gravity;

        if (keys.KeyDown(SDLK_LEFT) || keys.KeyDown(SDLK_a)) {
          velocity[0] += -airMoveSpeed;
          if (velocity[0] < -moveSpeed) velocity[0] = -moveSpeed;
        } else if (keys.KeyDown(SDLK_RIGHT) || keys.KeyDown(SDLK_d)) {
          velocity[0] += airMoveSpeed;
          if (velocity[0] > moveSpeed) velocity[0] = moveSpeed;
        }

        auto unitVector = tuple(rect.pos[0] - rope.rect.pos[0], rect.pos[1] - rope.rect.pos[1]);
        /*float length = unitVector[0] * unitVector[0] + unitVector[1] * unitVector[1];
        length = sqrt(length);
        unitVector = tuple(unitVector[0] / length, unitVector[1] / length);
        length -= 40f;
        if (length < 0) length = 0;
        length /= 1000;
        length *= 1.5f;
        if (length > 0)
          length += .8f;
        unitVector = tuple(unitVector[0] * length, unitVector[1] * length);*/

        float ropeLength = 60;

        float length = unitVector[0] * unitVector[0] + unitVector[1] * unitVector[1];
        length = sqrt(length);
        unitVector = tuple(unitVector[0] / length, unitVector[1] / length);

        float dotProduct = velocity[0] * unitVector[0] + velocity[1] * unitVector[1];
        //writeln(length, " ", dotProduct);
        //dotProduct /= sqrt(velocity[0] * velocity[0] + velocity[1] * velocity[1]);
        if (length > ropeLength + .1f) {
          length = 20f + dotProduct;
          if (length > 3) length = 3;
        } else {
          if (dotProduct >= 0 && dotProduct + length > ropeLength) {
            float diff = ropeLength - length - dotProduct;
            velocity[0] += diff * unitVector[0];
            velocity[1] += diff * unitVector[1];
            //writeln(velocity);
          }
          length = 0;
        }
        if (length <= 0) {
          unitVector = tuple(0f, 0f);
        } else {
          unitVector = tuple(unitVector[0] * length, unitVector[1] * length);
        }

        velocity[0] -= unitVector[0];
        velocity[1] -= unitVector[1];

        velocity[0] *= .98f;
        //velocity[1] *= .98f;
        break;
      case State.in_air:
        //writeln("Case 0");
        velocity[1] += gravity;

        if (keys.KeyDown(SDLK_LEFT) || keys.KeyDown(SDLK_a)) {
          velocity[0] += -airMoveSpeed;
          if (velocity[0] < -moveSpeed) velocity[0] = -moveSpeed;
        } else if (keys.KeyDown(SDLK_RIGHT) || keys.KeyDown(SDLK_d)) {
          velocity[0] += airMoveSpeed;
          if (velocity[0] > moveSpeed) velocity[0] = moveSpeed;
        }

        break;
      case State.on_ground:
        //writeln("Case 1");
        velocity[1] = .1f;
        if (keys.KeyPressed(SDLK_UP) ||
            keys.KeyPressed(SDLK_SPACE) ||
            keys.KeyPressed(SDLK_w)) {
              velocity[1] = -jumpForce;
              state = State.in_air;
            }
        if (keys.KeyDown(SDLK_LEFT) || keys.KeyDown(SDLK_a)) {
          velocity[0] -= horizAccel;
          if (velocity[0] < -moveSpeed) velocity[0] = -moveSpeed;
        } else if (keys.KeyDown(SDLK_RIGHT) || keys.KeyDown(SDLK_d)) {
          velocity[0] += horizAccel;
          if (velocity[0] > moveSpeed) velocity[0] = moveSpeed;
        } else {
          if (velocity[0] < 0) {
            velocity[0] += horizAccel;
            if (velocity[0] > 0) velocity[0] = 0;
          } else if (velocity[0] > 0) {
            velocity[0] -= horizAccel;
            if (velocity[0] < 0) velocity[0] = 0;
          }
        }
        break;
      case State.on_wall:
        if (velocity[1] < 0)
          velocity[1] += gravity / 2f;
        else
          velocity[1] += gravity / 4f;

        if (keys.KeyDown(SDLK_LEFT) || keys.KeyDown(SDLK_a)) {
          velocity[0] = -moveSpeed;
        } else if (keys.KeyDown(SDLK_RIGHT) || keys.KeyDown(SDLK_d)) {
          velocity[0] = moveSpeed;
        } else velocity[0] = wallSide;

        if (keys.KeyPressed(SDLK_UP) ||
            keys.KeyPressed(SDLK_SPACE) ||
            keys.KeyPressed(SDLK_w)) {
          velocity[1] = -jumpForce;
          velocity[0] = moveSpeed * -wallSide;
          state = State.in_air;
        }
        break;
      case State.climbing_corner:
        //writeln(rect.pos, animationParameters);
        if (rect.pos[1] <= animationParameters[2]) {
          velocity = tuple(wallSide * animationParameters[0], 0f);
        } else {
          velocity = tuple(wallSide * .01f, -animationParameters[0]);
        }
        animationCounter++;
        if (wallSide * rect.pos[0] >= wallSide * animationParameters[1] &&
            rect.pos[1] <= animationParameters[2]) {
          state = State.on_ground;
        }
        break;
      default:
        break;
    }

    /*if (keys.KeyPressed(SDLK_ESCAPE)) {
      Engine.instance.paused = true;
    }*/

    if (mouse.ButtonPressed(SDL_BUTTON_LEFT) && isPlayer) {
      auto bulletPos = tuple(rect.pos[0] + 5, rect.pos[1] + 5);
      auto bulletVelocity = tuple(mouse.pos[0] - 320f - 5 + 5, mouse.pos[1] - 240f - 5 + 10);
      float length = sqrt(bulletVelocity[0] * bulletVelocity[0] + bulletVelocity[1] * bulletVelocity[1]) / 22f;
      bulletVelocity[0] /= length;
      bulletVelocity[1] /= length;
      int bid = Bullet.getID(id);
      /*Engine.instance.AddComponent(new Bullet(bulletPos, bulletVelocity, id));*/
      Engine.instance.AddPacket(UDP.fire_shot ~ writeInt(bid) ~ 
                                writeFloat(bulletPos[0]) ~ writeFloat(bulletPos[1]) ~
                                writeFloat(bulletVelocity[0]) ~ writeFloat(bulletVelocity[1]));
      //writeln(bid);
    }

    if (mouse.ButtonPressed(SDL_BUTTON_RIGHT) && isPlayer) {
      if (rope !is null) {
        rope.Kill();
        byte[] packet;
        packet ~= UDP.disconnect_ninja_rope;
        packet ~= writeInt(rope.ID);
        Engine.instance.AddPacket(packet);
      }
      foreach (c; Engine.instance.GetComponents!Rope()) {
        if (c.ID >> 24 == ID) {
          (cast(Rope)c).Kill();
          byte[] packet;
          packet ~= UDP.disconnect_ninja_rope;
          packet ~= writeInt(c.ID);
          Engine.instance.AddPacket(packet);
        }
      }
      auto ropePos = tuple(rect.pos[0] + 5, rect.pos[1]);
      auto ropeVelocity = tuple(mouse.pos[0] - 5 - 320f, mouse.pos[1] - 5 - 240f);
      float length = sqrt(ropeVelocity[0] * ropeVelocity[0] + ropeVelocity[1] * ropeVelocity[1]) / 22f;
      ropeVelocity[0] /= length;
      ropeVelocity[1] /= length;
      Engine.instance.AddPacket(UDP.fire_ninja_rope ~ writeInt(Rope.getID(id)) ~  
                                writeFloat(ropePos[0]) ~ writeFloat(ropePos[1]) ~
                                writeFloat(ropeVelocity[0]) ~ writeFloat(ropeVelocity[1]));
    }
    //writeln("EndInput");

    Tuple!(float, int)[] result;
    float tmin = float.max;
    int dir = -1;
    floor = false;
    wall = false;
    float remaining = 1;

    Tuple!(byte, Wall)[] colliders;

    while (remaining > 0) {
      tmin = float.max;
      Wall minWall;
      foreach (c; Engine.instance.GetComponents!Wall()) {
        Wall w = cast(Wall) c;
        result = Collision(rect, velocity, w.rect);
        foreach (r; result) {
          if (r[0] < tmin && r[0] >= -0.000001) {
            tmin = r[0];
            dir = r[1];
            minWall = w;
          }
        }
      }
      byte direction;
      if (tmin <= remaining) {
        if (dir == 1) {
          if (velocity[1] >= 0) {
            floor = true;
            direction = -2;
          } else direction = 0;
          rect.pos[0] += tmin * velocity[0];
          rect.pos[1] += tmin * velocity[1];
          velocity[1] = 0;
        } else {
          wall = true;
          if (velocity[0] > 0) wallSide = 1;
          else wallSide = -1;
          rect.pos[0] += tmin * velocity[0];
          rect.pos[1] += tmin * velocity[1];
          velocity[0] = 0;
          direction = to!byte(wallSide);
        }
        remaining -= tmin;
        colliders ~= tuple(direction, minWall);
      } else {
        rect.pos[0] += remaining * velocity[0];
        rect.pos[1] += remaining * velocity[1];
        remaining = 0;
      }
    }
    
    if (state != State.ninja_rope && state != State.climbing_corner) {
      if (floor) state = State.on_ground;
      else if (wall) {
        if (state != State.climbing_corner) {
          state = State.on_wall;
          animationParameters = [0f, 0f, float.max];
          foreach (wall; colliders) {
            if (wall[0] == wallSide) {
              if (rect.Top > wall[1].rect.Top || rect.Bottom < wall[1].rect.Top) continue;
              if (wallSide == 1) {
                if (rect.Right == wall[1].rect.Left) {
                  if (wall[1].rect.Top < animationParameters[2]) {
                    animationParameters[1] = wall[1].rect.pos[0];
                    animationParameters[2] = wall[1].rect.Top - 40;
                  }
                }
              } else {
                if (rect.Left == wall[1].rect.Right) {
                  if (wall[1].rect.Top < animationParameters[2]) {
                    animationParameters[1] = wall[1].rect.Right - 20;
                    animationParameters[2] = wall[1].rect.Top - 40;
                  }
                }
              }
            }
          }
          if (animationParameters[2] < float.max) {
            if (PathClear(rect.pos, tuple(0f, animationParameters[2] - rect.pos[1])) == -1){
              float xVel = PathClear(tuple(rect.pos[0], animationParameters[2]), tuple(animationParameters[1] - rect.pos[0], 0f));
              if (xVel == -1 || xVel > 0) {
                if (xVel != -1) animationParameters[1] = rect.pos[0] * (1 - xVel) + xVel * animationParameters[1];
                if (velocity[1] < -4f)
                  animationParameters[0] = -velocity[1] * .5f;
                else 
                  animationParameters[0] = 4;
                state = State.climbing_corner;
              }
            }
          }
        }
      }
      else state = State.in_air;
    }

version (CLIENT) {
    if (isPlayer) {
      foreach (c; Engine.instance.GetComponents!KillZone()) {
        KillZone kz = cast(KillZone)c;
        if (kz.rect.Collides(rect)) { Damage(health + 1); break; }
      }
      Engine.instance.camera.xpos = -rect.pos[0] - rect.size[0] / 2;
      Engine.instance.camera.ypos = -rect.pos[1] - rect.size[1] / 2;
    }
}

    //writeln("EndPlayer Update");
    return false;
  }
  override void Draw() {
    version(CLIENT) {
    glColor4f(0, 0, 0, 1);
    Font font = Engine.instance.GetComponent!Font();
    if (isPlayer) {
      glColor4f(1, 1, 1, 1);
      font.Draw(to!string(state), tuple(100, 100), 400);
      font.Draw(to!string(health), tuple(520, 460), 40);
      if (respawn > 0) {
        font.Draw(to!string(respawn / 60 + 1), tuple(320 - font.stringWidth(to!string(respawn / 60 + 1)) / 2, 240), 40);
      }
    } else {
      auto width = font.stringWidth(username);
      writeln(width);
      Tuple!(int, int) pos;
      pos[0] = to!int(round(rect.pos[0]));
      pos[1] = to!int(round(rect.pos[1]));
      pos[0] += 10f;
      pos[0] -= width / 2;
      pos[1] -= 20;
      font.Draw(username, pos, width + 1, false);
    }
    glColor4f(1, 1, 1, 1);
    if (!dead) DrawAARect(rect, -1);
    }
  }
}

float PathClear(Tuple!(float, float) pos, Tuple!(float, float) velocity) {
  Component[int] walls = Engine.instance.GetComponents!Wall();
  Rectangle r = Rectangle(pos, tuple(20f, 40f));
  Wall w;
  float tMin = float.max;
  foreach (c; walls) {
    w = cast(Wall)c;

    foreach (collision; Collision(r, velocity, w.rect)) {
      if (collision[0] < tMin && collision[0] >= 0) tMin = collision[0];
    }
  }
  //writeln(tMin);
  if (tMin < 1) return tMin;
  else return -1;
}