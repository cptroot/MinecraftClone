import std.stdio;
import std.conv;
import std.typecons;

struct Rectangle {
  Tuple!(float, float) pos;
  Tuple!(float, float) size;

  @property float Top() { return pos[1]; }
  @property float Bottom() { return pos[1] + size[1]; }
  @property float Left() { return pos[0]; }
  @property float Right() { return pos[0] + size[0]; }

  @property Tuple!(float, float) Min() { return pos; }
  @property Tuple!(float, float) Max() { return tuple(pos[0] + size[0], pos[1] + size[1]); }

  @property Tuple!(float, float) Center() { return tuple(pos[0] + size[0] / 2f, pos[1] + size[1] / 2f); }

  bool Collides(Rectangle r) {
    return Left <= r.Right && Right >= r.Left && Top <= r.Bottom && Bottom >= r.Top;
  }

  string toString() {
    return "[(" ~ to!string(pos[0]) ~ ", " ~ to!string(pos[1]) ~ "), (" ~ to!string(size[0]) ~ ", " ~ to!string(size[1]) ~ ")]";
  }
}

Tuple!(float, int)[] Collision(Rectangle a, Tuple!(float, float) velocity, Rectangle b) {
  float t = float.max;
  float tmin = float.max;
  Tuple!(float, int)[] result = [];
  foreach (i; 0..2) {
  }
  if (velocity[0] > 0) {
    t = (b.Min[0] - a.Max[0]) / velocity[0];
  }
  if (velocity[0] < 0) {
    t = (b.Max[0] - a.Min[0]) / velocity[0];
  }
  /*if (velocity[0] == 0) {
    if (b.Max[0] == a.Min[0] || b.Min[0] == a.Min[0]) t = 0;
  }*/
  if (a.Top + velocity[1] * t < b.Bottom && a.Bottom + velocity[1] * t > b.Top) {
    if (t == tmin) {
      result ~= [tuple(t, 0)];
    }
    if (t < tmin && t >= -0.000001) {
      tmin = t;
      result = [tuple(t, 0)];
    }
  }
  t = float.max;
  if (velocity[1] > 0) {
    t = (b.Min[1] - a.Max[1]) / velocity[1];
  }
  if (velocity[1] < 0) {
    t = (b.Max[1] - a.Min[1]) / velocity[1];
  }
  /*if (velocity[1] == 0) {
    if (b.Max[1] == a.Min[1] || b.Min[1] == a.Min[1]) t = 0;
  }*/
  if (a.Left + velocity[0] * t < b.Right && a.Right + velocity[0] * t > b.Left) {
    if (t == tmin) {
      result ~= [tuple(t, 1)];
    }
    if (t < tmin && t >= -0.000001) {
      tmin = t;
      result = [tuple(t, 1)];
    }
  }
  return result;
}