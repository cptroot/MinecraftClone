import std.stdio;
import std.typecons;

import derelict.sdl2.sdl;

interface Component {
  @property int ID();
}

interface Drawable {
  @property float Depth();
  void LoadResources();
  void Draw();
}

interface Updateable {
  bool Update(SDL_Event[] events);
}

interface Entity {
  @property Tuple!(float, float) Position();
  @property Tuple!(float, float) Velocity();

}