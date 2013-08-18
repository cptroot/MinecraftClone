import std.stdio;
import std.socket;
import std.datetime;
import std.algorithm;
import std.typecons;
import std.string;
import std.concurrency;
import core.thread;
import std.conv;
import std.file;

import derelict.sdl.sdl;

import component;
import udpnames;
import udpio;
import listener;
import player;
import bullet;
import rope;
import level;
import input;

alias Server Engine;

void reads(Tid tid) {
  string result;
  while (result != "stop") {
    result = readln();
    result = removechars(result, "\n");
    prioritySend(tid, result);
  }
}


void main() {
  writeln("Level: ");
  string level = readln();
  level = level[0..$ - 1];
  if (level != "" && exists("levels\\" ~ level)) {
    level = "levels\\" ~ level;
  } else { writeln("levels\\" ~ level); level = ""; }
  Server server = new Server(level);
  spawn(&reads, thisTid);
  server.Run();
  writeln("over");
}

class Server {
  static Server instance;

  Component[int][string] components;
  Updateable[int][string] updateList;

  Tuple!(int, string)[] removal = [];

  string title = "";

  bool paused = false;

  Tid listener;

  void AddComponent(T)(T component) 
    if (is(T:Component)) {
      components[typeid(T).toString()][component.ID] = component;
      if (is(T:Updateable)) {
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
      if (type in updateList) {
        updateList[type].remove(id);
      }
    }
  }

  void Run() {
    long oldTicks = 0;
    long currentTicks = 0;
    long ticks;
    long elapsed = 16;
    long taken = 0;
    bool quitting = false;
    listener = spawn(&listen, thisTid, 16u);

    StopWatch sw = StopWatch(AutoStart.yes);

    while (!quitting) {
      sw.stop();
      ticks = sw.peek().msecs;
      sw.start();
      elapsed = ticks - oldTicks;
      oldTicks = ticks;
      quitting = Update();
      if (PollMessages()) return;
      if (quitting) return;
      SendPackets();
      sw.stop();
      taken = sw.peek().msecs - oldTicks;
      sw.start();
      if (taken < 16)
        Thread.sleep(dur!"msecs"(16 - taken));
    }
  }

  this(string map) {
    instance = this;

    if (map == "") 
      AddComponent(new Level("levels\\level1.txt"));
    else
      AddComponent(new Level(map));

    AddComponent(new Keyboard());
    AddComponent(new Mouse());
    setMaxMailboxSize(thisTid(), 0, OnCrowding.throwException);
  }

  bool Update() {
    bool result;
    SDL_Event[] events;
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

  bool PollMessages() {
    bool result;
    bool returnVal = false;
    do {
      result = receiveTimeout(dur!"usecs"(1),
        (UDP type, int id, Tuple!(float, float) pos, Tuple!(float, float) vel) {
          Player p = GetComponent!Player(id);
          switch (type) {
            case UDP.movement:
              p.rect.pos = pos;
              p.velocity = vel;
              break;
            case UDP.fire_shot:
              Bullet b = new Bullet(pos, vel, id);
              AddComponent(b);
              break;
            case UDP.fire_ninja_rope:
              Rope r = new Rope(pos, vel, id);
              AddComponent(r);
              break;
            default:
              break;
          }
        },
        (UDP type, byte id) {
          switch (type) {
            case UDP.disconnect:
              writeln("disconnect");
              DestroyComponent(id, typeid(Player).toString());
              foreach (rid, c; GetComponents!Rope()) {
                if (rid >> 24 == id) RemoveComponent!Rope(rid);
                byte[] packet;
                packet ~= UDP.disconnect_ninja_rope;
                packet ~= writeInt(rid);
                foreach (i, p; GetComponents!Player())
                  AddPacket(packet, i);
              }
              foreach (i, c; GetComponents!Bullet())
                if (i >> 24 == id) RemoveComponent!Bullet(i);
              RefreshPlayers();
              break;
            case UDP.player_list:
              auto players = GetComponents!Player();
              byte[] packet;
              packet ~= UDP.player_list;
              packet ~= to!byte(players.keys.length);
              foreach (i; players.keys) {
                packet ~= to!byte(i);
                packet ~= writeString((cast(Player)players[i]).username);
              }
              AddPacket(packet, id);
              break;
            case UDP.die: case UDP.respawn:
              byte[] packet;
              packet ~= type;
              packet ~= id;
              foreach (i, c; GetComponents!Player()) {
                if (i != id)
                  AddPacket(packet, i);
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
              AddComponent(new Player(id, username));
              RefreshPlayers();
              break;
            default:
              break;
          }
        },
        (UDP type, byte id, byte packetNum) {
          if (packetNum == -1) {
            Level l = GetComponent!Level();
            foreach (packet; l.packets) {
              send(listener, packet.idup, to!int(id));
            }
          } else {
            Level l = GetComponent!Level();
            send(listener, l.packets[packetNum].idup, to!int(id));
          }
        },
        (UDP type, int id) {
          Rope r = GetComponent!Rope(id);
          if (r !is null) {
            r.Kill();
          }
          Player p = GetComponent!Player(id >> 24);
          if (p !is null) {
            p.state = State.in_air;
          }
          Component[int] players = GetComponents!Player();
          byte[] packet;
          packet ~= UDP.disconnect_ninja_rope;
          packet ~= writeInt(id);
          foreach (i; players.keys) {
            AddPacket(packet, i);
          }
        },
        (string msg) {
          writeln("new message ", msg);
          if (msg == "stop") {
            returnVal = true;
            prioritySend(listener, true);
          }
        }
        );
    } while (result == true && returnVal == false);
    return returnVal;
  }

  void RefreshPlayers() {
    auto players = GetComponents!Player();
    byte[] packet;
    packet ~= UDP.player_list;
    packet ~= to!byte(players.keys.length);
    foreach (id; players.keys) {
      packet ~= to!byte(id);
      packet ~= writeString((cast(Player)players[id]).username);
    }

    foreach (id; players.keys) {
      AddPacket(packet, id);
    }
  }

  void AddPacket(byte[] packet) {
  }

  void AddPacket(byte[] packet, int player) {
    messages[player] ~= packet;
  }

  byte[][int] messages;

  void SendPackets() {
    byte[] data;

    foreach (id, c; GetComponents!Bullet()) {
      Bullet b = cast(Bullet)c;
      data ~= UDP.fire_shot;
      data ~= writeInt(id);
      data ~= writeFloat(b.rect.pos[0]);
      data ~= writeFloat(b.rect.pos[1]);
      data ~= writeFloat(b.velocity[0]);
      data ~= writeFloat(b.velocity[1]);
    }

    foreach (id, c; GetComponents!Rope()) {
      Rope r = cast(Rope)c;
      data ~= UDP.fire_ninja_rope;
      data ~= writeInt(id);
      data ~= writeFloat(r.rect.pos[0]);
      data ~= writeFloat(r.rect.pos[1]);
      data ~= writeFloat(r.velocity[0]);
      data ~= writeFloat(r.velocity[1]);
    }

    Component[int] players = GetComponents!Player();
    byte[][16] playerData;
    foreach (id, c; players) {
      Player p = cast(Player)c;
      playerData[id] ~= UDP.player;
      playerData[id] ~= to!byte(id);
      playerData[id] ~= writeFloat(p.rect.pos[0]);
      playerData[id] ~= writeFloat(p.rect.pos[1]);
      playerData[id] ~= writeFloat(p.velocity[0]);
      playerData[id] ~= writeFloat(p.velocity[1]);
    }

    byte[] packet;
    byte[] dull;
    dull ~= UDP.keep_alive;
    foreach (id, c; players) {
      packet = data;
      if (id in messages) {
        packet ~= messages[id];
        messages[id] = [];
      }
      foreach (id2, c; players) {
        if (id2 != id) 
          packet ~= playerData[id2];
      }
      if (packet.length == 0) {
        send(listener, dull.idup, id);
      } else {
        send(listener, packet.idup, id);
      }
    }

    foreach (ids; messages) {
      if (ids.length > 0) throw new Exception("AAAA");
    }
  }
}