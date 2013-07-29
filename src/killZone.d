import std.conv;
import std.typecons;  

import component;
import rectangle;

class KillZone : Component {
  int id;
  static int maxID = 0;

  @property override int ID() {
    return id;
  }

  Rectangle rect;

  this() {
    id = maxID++;
  }

  this(string[] lines) {
    rect.pos = tuple(to!float(lines[0]),
                     to!float(lines[1]));
    rect.size = tuple(to!float(lines[2]),
                      to!float(lines[3]));
    this();
  }

  this(Tuple!(float, float) pos, Tuple!(float, float) size) {
    rect = Rectangle(pos, size);
    this();
  }
}