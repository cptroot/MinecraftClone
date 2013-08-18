import std.stdio;
import std.typecons;
import std.string;
import std.conv;

import derelict.opengl.gl;
import derelict.sdl.sdl;
import derelict.openal.al;

import camera;
import player;
import error;
import font;
import walls;
import light;
import writer;
import monsters;

class Engine {
  static Engine instance;
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
      if (quitting) return;
      Draw();
			SDL_GL_SwapBuffers();
      string s = GLError();
      if (s != "") throw new Exception(s);
      s = ALError();
      if (s != "") throw new Exception(s);
      taken = SDL_GetTicks() - oldTicks;
      if (taken < 16)
        SDL_Delay(16 - taken);
    }
  }

  this() {
    ALCdevice* ALDevice = alcOpenDevice(null); // select the "preferred device"
    ALCcontext* ALContext = alcCreateContext(ALDevice, null);
    alcMakeContextCurrent(ALContext);
    alListener3f(AL_POSITION, 0, 0, 0);
    alListener3f(AL_VELOCITY, 0, 0, 0);

    player = new Player();
    wall = new Walls();
    writer = new TextWriter();
    monsters.instance;

		glEnable(GL_DEPTH_TEST);
		glEnable(GL_BLEND);
    glEnable(GL_STENCIL_TEST);
    glEnable(GL_TEXTURE_2D);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-320, 320, 240, -240, -2, 10);
    glClearColor(0f, .00f, 0f, 1f);
    instance = this;
  }

	bool[int] keys;
  auto mouse = tuple(1, 1);

  bool Update() {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
      switch (event.type) {
        case SDL_QUIT:
          return true;
          break;
        case SDL_KEYDOWN:
          keys[event.key.keysym.sym] = true;
          break;
        case SDL_KEYUP:
          keys[event.key.keysym.sym] = false;
          break;
        case SDL_MOUSEMOTION:
          mouse[0] = event.motion.x;
          mouse[1] = event.motion.y;
          break;
        case SDL_MOUSEBUTTONUP:

          break;
        default:
          break;
      }
    }
    return false;
  }

  void Draw() {
    Camera.instance.SetWorldMatrix();

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    DrawShadows(player.pos[0], player.direction, mouse[0], mouse[1], player.height);
    glStencilFunc(GL_EQUAL, 1, 0xffffffff);
    glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
    wall.Draw(player.pos[1]);
    glClear(GL_DEPTH_BUFFER_BIT);
    glStencilFunc(GL_EQUAL, 0, 0xffffffff);
    wall.Draw(player.pos[1]);
    DrawBlack();
    glStencilFunc(GL_ALWAYS, 1, 0xffffffff);
    player.Draw();
    Monsters.instance.Draw();
    writer.Draw();
  }
}

void DrawBlack() {
  glPushMatrix();
  glLoadIdentity();
  glDisable(GL_TEXTURE_2D);
  glBegin(GL_QUADS);
  glColor4f(0, 0, 0, .5f);
  glVertex3f(-320, -240, -1.5f);
  glVertex3f(320, -240, -1.5f);
  glVertex3f(320, 240, -1.5f);
  glVertex3f(-320, 240, -1.5f);
  glColor4f(1, 1, 1, 1);
  glEnd();
  glEnable(GL_TEXTURE_2D);
  glPopMatrix();
}
import std.file;

//Code from NeHe Productions
/* function to load in bitmap as a GL texture */
void LoadGLTextures(string fileName, ref uint texture, int filterMin, int filterMag)
{
  
  /* Status indicator */
  int Status = false;

  /* Create storage space for the texture */
  SDL_Surface *TextureImage; 

  /* Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit */
  if ( ( TextureImage = SDL_LoadBMP( toStringz(fileName) ) )!=null )
  {

    /* Set the status to true */
    Status = true;

    /* Create The Texture */
    glGenTextures( 1, &texture );

    /* Typical Texture Generation Using Data From The Bitmap */
    glBindTexture( GL_TEXTURE_2D, texture );

    /* Generate The Texture */
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, TextureImage.w,
                 TextureImage.h, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, TextureImage.pixels );

    /* Linear Filtering */
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filterMin );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filterMag );
  }

  /* Free up any memory we may have used */
  if ( TextureImage )
    SDL_FreeSurface( TextureImage );
  if (Status == false) throw new Exception("Could not load " ~ fileName);
}

import std.string;

void LoadALWAV(string fileName, ref uint buffer) {
  File f = File(fileName, "rb");
  FILE* file = f.getFP;
  ulong totalSize = f.size;
  char xbuffer[4];
  if (fread(xbuffer.ptr, char.sizeof, 4u, file) != 4 || cmp(xbuffer, "RIFF") != 0)
    throw new Exception(fileName ~ " is not a WAV file");

  file_read_int32_le(xbuffer, file);

  if (fread(xbuffer.ptr, char.sizeof, 4u, file) != 4 || cmp(xbuffer, "WAVE") != 0)
    throw new Exception(fileName ~ " is not a WAV file");

  if (fread(xbuffer.ptr, char.sizeof, 4u, file) != 4 || cmp(xbuffer, "fmt ") != 0)
    throw new Exception(fileName ~ " is an invalid WAV file: " ~ to!string(xbuffer));

  file_read_int32_le(xbuffer, file);
  short audioFormat = file_read_int16_le(xbuffer, file);
  short channels = file_read_int16_le(xbuffer, file);
  int sampleRate = file_read_int32_le(xbuffer, file);
  int byteRate = file_read_int32_le(xbuffer, file);
  file_read_int16_le(xbuffer, file);
  short bitsPerSample = file_read_int16_le(xbuffer, file);
  int fileSize = 44;

  /*if (audioFormat != 16) {
    writeln("extraParams: " ~ to!string(audioFormat));
    short extraParams = file_read_int16_le(xbuffer, file);
    fileSize += extraParams + 2;
    char ybuffer[128];
    while (extraParams > 0) {
      fread(ybuffer.ptr, char.sizeof, extraParams > 128 ? 128u : extraParams, file);
      extraParams -= 128;
    }
  }*/
  if (fread(xbuffer.ptr, char.sizeof, 4u, file) != 4 || cmp(xbuffer, "data") != 0)
    throw new Exception(fileName ~ " is an invalid WAV file: " ~ to!string(xbuffer));

  int dataChunkSize = file_read_int32_le(xbuffer, file);
  
  ubyte[] bufferData;
  ulong remaining = totalSize - fileSize;
  bufferData.length = cast(uint)remaining;
  ubyte* ptr = bufferData.ptr;
  while (remaining > 0) {
    fread(ptr, ubyte.sizeof, cast(uint)dataChunkSize, file);
    ptr += dataChunkSize;
    remaining -= dataChunkSize;
  } 

  float duration = cast(float)(dataChunkSize) / byteRate;
  alBufferData(buffer, channels == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16, bufferData.ptr, dataChunkSize, sampleRate);
}

int file_read_int32_le(char[] buffer, FILE* file) {
  int result = 0;
  
  if (fread(buffer.ptr, byte.sizeof, 4u, file) != 4) throw new Exception("Not enough file left");
  foreach (i; 0..4) {
    result += buffer[i] << (8 * i);
  }
  return result;
}

short file_read_int16_le(char[] buffer, FILE* file) {
  short result = 0;

  if (fread(buffer.ptr, byte.sizeof, 2u, file) != 2) throw new Exception("Not enough file left");
  foreach (i; 0..2) {
    result += buffer[i] << (8 * i);
  }
  return result;
}