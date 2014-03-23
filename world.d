module world;

import std.file;
import std.random;

import engine;
import component;
import block;

class World : Component {
  Block[] blocks;

  auto world_size = tuple(17, 17, 17);

  @property int ID() { return 1; }

  this() {
    blocks.length = world_size[0] * world_size[1] * world_size[2];
  }

  void Generate() {
    Random rand = new Random();
    float[] values;
    values.length = world_size[0] * world_size[1] * world_size[2];

  }
}