import std.stdio;
import std.socket;
import std.datetime;
import core.thread;
import std.concurrency;
import std.typecons;
import std.string;
import std.conv;
import std.algorithm;

import derelict.opengl.gl;
import derelict.openal.al;
import derelict.sdl.sdl;

import udpnames;
import udpio;
import clientListener;
import component;
import camera;
import error;
import input;
import font;
import player;
import bullet;
import rope;
import level;
import player_list;
import resolution;

alias Client Engine;

void main() {
  ushort port = 19863;

  write("Address: ");
  string address = readln();
  if (address == "\n") address = "127.0.0.1";
  try {
    InternetAddress inet = new InternetAddress(address, port);
  } catch (Exception e) {
    writeln(address, " is not a valid IP address");
    assert(0, address ~ " is not a valid IP address");
    return;
  }
  immutable InternetAddress inet = cast(immutable) (new InternetAddress(address, port));
  writeln(inet.toString());

  write("Username: ");

  string username = readln();
  if (username == "\n") username = "hi";
  else username = username[0..$ - 1];

  DerelictSDL.load();
  DerelictGL.load();
  DerelictAL.load();
  SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 1);
  SDL_Surface* surface = SDL_SetVideoMode(640, 480, 32, SDL_OPENGL);
  writeln("Loaded");

  Tid listenThread = spawn(&listen, thisTid(), inet, username);
  Client client;
  try {client = new Client(listenThread);}
  catch (Exception e) {
    writeln(e);
    return;
  }
  client.Run();
}

class Client {
  static Client instance;

  Component[int][string] components;
  Updateable[int][string] updateList;
  Drawable[int][string] drawList;
  Drawable[] drawOrder;

  Tuple!(int, string)[] removal = [];
  byte[] packet;

  string title = "";

  Camera camera;

  bool paused = false;

  Tid listenerThread;

  void AddComponent(T)(T component) 
    if (is(T:Component)) {
      //if (typeid(T).toString() !in components) components[typeid(T).toString()] = new Component[string];
      components[typeid(T).toString()][component.ID] = component;
      if (is(T:Drawable)) {
        //if (typeid(T).toString() !in drawList) drawList[typeid(T).toString()] = [];
        drawList[typeid(T).toString()][component.ID] = cast(Drawable)component;
        if (drawOrder.length > 0) {
          int i = 0;
          Drawable d = cast(Drawable)component;
          while (i < drawOrder.length && drawOrder[i].Depth < d.Depth) i++;
          drawOrder = drawOrder[0..i] ~ d ~ drawOrder[i..$];
        } else {
          drawOrder ~= cast(Drawable)component;
        }
      }
      if (is(T:Updateable)) {
        //if (typeid(T).toString() !in updateList) updateList[typeid(T).toString()] = [];
        updateList[typeid(T).toString()][component.ID] = cast(Updateable)component;
      }
    }

  Component[int] GetComponents(T)()
    if (is(T:Component)) {
      if (typeid(T).toString() in components) return components[typeid(T).toString()];
      return null;
    }

  T GetComponent(T)()
    if (is(T:Component)) {
      if (typeid(T).toString() in components) return cast(T)components[typeid(T).toString()][components[typeid(T).toString()].keys[0]];
      return null;
    }

  T GetComponent(T)(int id) 
    if (is(T:Component)) {
      if (typeid(T).toString() in components && id in components[typeid(T).toString()]) return cast(T)components[typeid(T).toString()][id];
      return null;
    }

  void RemoveComponent(T)(int id)
    if (is(T:Component)) {
      removal ~= tuple(id, typeid(T).toString());
    }

  private void DestroyComponent(int id, string type) {
    if (type in components && id in components[type]) {
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
      if (type in updateList) {
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
      if (PollMessages()) quitting = true;
      if (quitting) {
        prioritySend(listenerThread, true);
        return;
      }
      SendPackets();
      Draw();
			SDL_GL_SwapBuffers();
      string s = GLError();
      if (s != "") throw new Exception(s);
      s = error.ALError();
      if (s != "") throw new Exception(s);
      taken = SDL_GetTicks() - oldTicks;
      if (taken < 16)
        SDL_Delay(16 - taken);
    }
  }

  this(Tid thread) {
    ALCdevice* ALDevice = alcOpenDevice(null); // select the "preferred device"
    ALCcontext* ALContext = alcCreateContext(ALDevice, null);
    alcMakeContextCurrent(ALContext);
    alListener3f(AL_POSITION, 0, 0, 0);
    alListener3f(AL_VELOCITY, 0, 0, 0);

    LoadGL();

    SDL_WM_SetCaption(toStringz(title), null);

    camera = new Camera();

    AddComponent(new Keyboard());
    AddComponent(new Mouse());

    Font f = new Font("images\\Font.fnt");
    AddComponent(f);

    AddComponent(new PlayerList());

    AddComponent(new Resolution());

    listenerThread = thread;

    instance = this;
  }

  void LoadGL() {
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_BLEND);
    //glEnable(GL_STENCIL_TEST);
    //glEnable(GL_TEXTURE_2D);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glMatrixMode(GL_PROJECTION);

    glClearColor(.2f, .2f, .2f, 1);
		glLoadIdentity();

    //0 to 10 for depth, 0 is front, 10 is the back.
		glOrtho(-320, 320, 240, -240, -1, 11);
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

  int playerID;

  bool PollMessages() {
    bool result;
    bool returnVal = false;
    do {
      result = receiveTimeout(dur!"usecs"(1),
      (UDP type, byte id, Tuple!(float, float) pos, Tuple!(float, float) vel) {
        Player p = GetComponent!Player(id);
        if (p is null) {
          p = new Player(id, "");
          p.rect.pos = pos;
          p.velocity = vel;
          AddComponent(p);
          AddPacket([cast(byte)UDP.player_list, cast(byte)playerID]);
        } else {
          p.rect.pos = pos;
          p.velocity = vel;
        }
      },
      (UDP type, int id, Tuple!(float, float) pos, Tuple!(float, float) vel) {
        Player p = GetComponent!Player(id << 24);
        switch (type) {
          case UDP.fire_shot:
            Bullet b = GetComponent!(Bullet)(id);
            if (b is null) {
              b = new Bullet(pos, vel, id);
              AddComponent(b);
            } else {
              b.rect.pos = pos;
              b.velocity = vel;
            }
            break;
          case UDP.fire_ninja_rope:
            Rope r = GetComponent!Rope(id);
            if (r is null) {
              r = new Rope(pos, vel, id);
              AddComponent(r);
            } else {
              r.rect.pos = pos;
              r.velocity = vel;
            }
            break;
          default:
            break;
        }
      },
      (UDP type, int id) {
        switch (type) {
          case UDP.disconnect:
            writeln("disconnect");
            returnVal = true;
            break;
          case UDP.damage:
            Player p = GetComponent!Player(playerID);
            p.Damage(id);
            break;
          case UDP.disconnect_ninja_rope:
            Rope r = GetComponent!Rope(id);
            if (r !is null) {
              r.Kill();
              r.player.state = State.in_air;
            }
            break;
          default:
            break;
        }
      },
      (UDP type, byte id, string username) {
        switch (type) {
          case UDP.connect:
            writeln("connect");
            AddComponent(new Player(id, true, username));
            playerID = id;
            break;
          default:
            break;
        }
      },
      (UDP type, byte id) {
        switch (type) {
          case UDP.die:
            GetComponent!Player(id).dead = true;
            break;
          case UDP.respawn:
            GetComponent!Player(id).dead = false;
            break;
          default:
            break;
        }
      },
      (UDP type, immutable(int)[] ids, immutable(string)[] usernames) {
        writeln("Player_List");
        foreach (id; GetComponents!Player().keys) {
          writeln(id);
          if (id != playerID && !canFind(ids, id)) RemoveComponent!Player(id);
        }
        foreach (i, id; ids) {
          if (!canFind(GetComponents!Player().keys, id)) 
            AddComponent(new Player(id, usernames[i]));
        }
        foreach (i, username; usernames) {
          GetComponent!Player(i).username = username;
        }
      },
      (immutable(byte[]) map) {
        writeln("map");
        AddComponent(new Level(map));
      },
      (string msg) {
        writeln("new message ", msg);
        if (msg == "stop") {
          returnVal = true;
          prioritySend(listenerThread, true);
        }
      }
      );
    } while (result == true && returnVal == false);
    return returnVal;
  }

  void AddPacket(byte[] packet) {
    this.packet ~= packet;
  }

  void SendPackets() {
    Player p = GetComponent!Player(playerID);
    if (p is null) return;
    packet ~= UDP.movement;
    packet ~= to!byte(p.ID);
    packet ~= writeFloat(p.rect.pos[0]);
    packet ~= writeFloat(p.rect.pos[1]);
    packet ~= writeFloat(p.velocity[0]);
    packet ~= writeFloat(p.velocity[1]);
    /*foreach (c; GetComponents!Bullet()) {
      Bullet b = cast(Bullet)c;
      packet ~= UDP.fire_shot;
      packet ~= writeInt(b.ID);
      packet ~= writeFloat(b.rect.pos[0]);
      packet ~= writeFloat(b.rect.pos[1]);
      packet ~= writeFloat(b.velocity[0]);
      packet ~= writeFloat(b.velocity[1]);
    }*/
    /*foreach (c; GetComponents!Rope()) {
      Bullet b = cast(Bullet)c;
      packet ~= UDP.fire_ninja_rope;
      packet ~= writeInt(b.ID);
      packet ~= writeFloat(b.rect.pos[0]);
      packet ~= writeFloat(b.rect.pos[1]);
      packet ~= writeFloat(b.velocity[0]);
      packet ~= writeFloat(b.velocity[1]);
    }*/
    send(listenerThread, packet.idup);
    packet = [];
  }

  void Draw() {
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT/* | GL_STENCIL_BUFFER_BIT*/);
    camera.SetWorldMatrix();
    foreach (d; drawOrder) {
      d.Draw();
    }
  }
}