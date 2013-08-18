import std.stdio;
import std.conv;
import std.typecons;

import component;
import rectangle;

class SpawnZone : Component {
  int id;
  static int maxID = 0;

  @property override int ID() {
    return id;
  }

  Rectangle rect;

  byte team;

  this() {
    id = maxID++;
  }

  this(string[] lines) {
    rect.pos = tuple(to!float(lines[0]),
         to!float(lines[1]));
    rect.size = tuple(to!float(lines[2]),
         to!float(lines[3]));
    team = to!byte(lines[4]);
    this();
  }

  this(Tuple!(float, float) pos, Tuple!(float, float) size, byte team) {
    this.team = team;
    this(pos, size);
  }

  this(Tuple!(float, float) pos, Tuple!(float, float) size) {
    rect = Rectangle(pos, size);
    this();
  }
}