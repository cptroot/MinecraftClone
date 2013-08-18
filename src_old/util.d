import std.stdio;
import std.file;
import std.conv;

import derelict.sdl.sdl;
import derelict.opengl.gl;
import derelict.openal.al;

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