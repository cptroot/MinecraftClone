import std.stdio;
import std.conv;
import std.string;
import std.array;
import std.file;
import std.typecons;

version(CLIENT) {
import derelict.sdl.sdl;
import derelict.opengl.gl;
}

version(CLIENT) {
import game;
import client;
}
version(SERVER)
import server;

import component;
import wall;
import spawnZone;
import killZone;
import udpio;
import udpnames;

class Level : Component {
  int id;
  @property int ID() {
    return id;
  }
  int maxId = 0;

  Component[] entities;
  byte[] types;

  byte[][] packets;

  this(string fileName) {
    id = maxId++;

    string[] objects = split(readText(fileName), ";");
    
    foreach (o; objects) {
      if (o == "") continue;
      string[] lines = split(removechars(removechars(o, "\r"), " "), "\n");
      switch (lines[0]) {
        case "Wall":
          Wall w = new Wall(lines[1..$]);
          Engine.instance.AddComponent!Wall(w);
          entities ~= w;
          types ~= 1;
          break;
        case "SpawnZone":
          SpawnZone s = new SpawnZone(lines[1..$]);
          Engine.instance.AddComponent!SpawnZone(s);
          entities ~= s;
          types ~= 2;
          break;
        case "KillZone":
          KillZone kz = new KillZone(lines[1..$]);
          Engine.instance.AddComponent!KillZone(kz);
          entities ~= kz;
          types ~= 3;
          break;
        default:
          break;
      }
    }

    byte[] packet;
    foreach (i, e; entities) {
      switch (types[i]) {
        case 1:
          packet ~= types[i];
          Wall w = cast(Wall)e;
          packet ~= writeFloat(w.rect.pos[0]);
          packet ~= writeFloat(w.rect.pos[1]);
          packet ~= writeFloat(w.rect.size[0]);
          packet ~= writeFloat(w.rect.size[1]);
          writeln(w.rect);
          break;
        case 2:
          packet ~= types[i];
          SpawnZone s = cast(SpawnZone)e;
          packet ~= writeFloat(s.rect.pos[0]);
          packet ~= writeFloat(s.rect.pos[1]);
          packet ~= writeFloat(s.rect.size[0]);
          packet ~= writeFloat(s.rect.size[1]);
          packet ~= s.team;
          writeln("Spawn Zone: ", s.rect);
          break;
        case 3:
          packet ~= types[i];
          KillZone kz = cast(KillZone)e;
          packet ~= writeFloat(kz.rect.pos[0]);
          packet ~= writeFloat(kz.rect.pos[1]);
          packet ~= writeFloat(kz.rect.size[0]);
          packet ~= writeFloat(kz.rect.size[1]);
          writeln("Kill Zone: ", kz.rect);
          break;
        default:
          break;
      }
    }
    int packetsLength = 0;

    byte packetNum = to!byte(packet.length / 996);
    if (packet.length % 996 != 0) packetNum++;

    packets ~= [UDP.map, -1, packetNum];

    while(packetsLength < packet.length) {
      if (packetsLength + 996 >= packet.length) {
        packets ~= [cast(byte)UDP.map, to!byte(packets.length - 1)] ~ packet[packetsLength..$];
        packetsLength = packet.length;
      } else {
        packets ~= [cast(byte)UDP.map, to!byte(packets.length - 1)] ~ packet[packetsLength..packetsLength + 996];
        packetsLength += 996;
      }
    }
  }

  this(immutable(byte[]) map) {
    writeln("create map");
    //writeln(map);
    uint index = 0;
    while (index < map.length && map[index] != 0) {
      switch(map[index]) {
        case 1:
          index++;
          Wall w = new Wall(tuple(readFloat(map, index), readFloat(map, index)),
                            tuple(readFloat(map, index), readFloat(map, index)));
          writeln("Wall: ", w.rect);
          Engine.instance.AddComponent(w);
          entities ~= w;
          break;
        case 2:
          index++;
          SpawnZone s = new SpawnZone(tuple(readFloat(map, index), readFloat(map, index)),
                                      tuple(readFloat(map, index), readFloat(map, index)), map[index]);
          writeln("Spawn Zone: ", s.rect);
          index++;
          Engine.instance.AddComponent(s);
          entities ~= s;
          break;
        case 3:
          index++;
          KillZone kz = new KillZone(tuple(readFloat(map, index), readFloat(map, index)),
                            tuple(readFloat(map, index), readFloat(map, index)));
          writeln("Kill Zone: ", kz.rect);
          Engine.instance.AddComponent(kz);
          writeln(Engine.instance.components);
          entities ~= kz;
          break;
        default:
          index++;
          break;
      }
    }
  }
}