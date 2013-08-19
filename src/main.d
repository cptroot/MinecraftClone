module main;

import core.runtime;
import core.sys.windows.windows;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;
import derelict.openal.al;
import std.stdio;
import std.file;
import std.conv;

import game;
import constants;

int main(string[] args) {
  version (OSX)
  {
    writeln(args[0]);
    size_t i;
    for (i = args[0].length - 1; i > 0; i--) {
      if (args[0][i] == '/') {
        break;
      }
    }
    chdir(args[0][0..i]);
  }

  DerelictSDL2.load();
  DerelictGL3.load();
  DerelictAL.load();
 
  if (SDL_Init(SDL_INIT_VIDEO) < 0) { /* Initialize SDL's Video subsystem */
    writeln("Unable to initialize SDL"); /* Or die on error */
    SDL_Quit();
    return 1;
  }
 
  /* Request opengl 3.2 context.
   * SDL doesn't have the ability to choose which profile at this time of writing,
   * but it should default to the core profile */
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
  //SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1);
  //SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_DEBUG_FLAG);

  /* Turn on double buffering with a 24bit Z buffer.
   * You may need to change this to 16 or 32 for your system */
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
  auto mainwindow = SDL_CreateWindow("Derelict Test", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                     width, height, SDL_WINDOW_OPENGL);
  auto maincontext = SDL_GL_CreateContext(mainwindow);
    SDL_GL_SetSwapInterval(1);

  //writeln(to!(string)(glGetString(GL_VERSION)));
  GLVersion glver = DerelictGL3.reload();
  //writeln(glver);


  scope(exit) {
	  SDL_Quit();
  }

  auto game = new Game(mainwindow);

	game.Run();
  return 0;

  writeln("Hello World");

}