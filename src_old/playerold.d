import std.stdio;
import std.typecons;
import std.math;

import derelict.opengl.gl;
import derelict.openal.al;

import component;
import engine;

class Player : Component {
  auto pos = tuple(0., 0.);
  bool animating;
  int direction = 0;
  int frame;
  int maxFrame = 25;
  double move = 1;
  uint[] textures;
  uint[] buffers;
  uint[] sources;

  int nextDirection = -1;

  float height() {
    return (-cos(frame * 2 * PI / maxFrame) + 1) * 2;
  }

  this() {
    animating = false;
    textures = new uint[4];
    buffers = new uint[1];
    sources = new uint[1];
    alGenBuffers(1, buffers.ptr);
    alGenSources(1, sources.ptr);
    LoadGLTextures("images\\PlayerBack.bmp", textures[2], GL_LINEAR, GL_NEAREST);
    LoadGLTextures("images\\PlayerRight.bmp", textures[1], GL_LINEAR, GL_NEAREST);
    LoadGLTextures("images\\PlayerLeft.bmp", textures[3], GL_LINEAR, GL_NEAREST);
    LoadGLTextures("images\\PlayerFront.bmp", textures[0], GL_LINEAR, GL_NEAREST);
    LoadALWAV("sounds\\Walk.wav", buffers[0]);
    alSourcei(sources[0], AL_BUFFER, buffers[0]);
    alSourcef(sources[0], AL_PITCH, 1.0f);
    alSourcef(sources[0], AL_MAX_GAIN, 1.0f);
    alSourcef(sources[0], AL_GAIN, 8.0f);
    float[] temp = [0, 0, 0];
    alSourcefv(sources[0], AL_POSITION, temp.ptr);
    alSourcefv(sources[0], AL_VELOCITY, temp.ptr);
  }

  override void Update() {
    if (animating) {
      if (frame == 0) {
        if ((pos[0] == 50 && direction == 1) || (pos[0] == -50 && direction == 3)) {
          animating = false;
          return;
        }
      }
      frame++;
      switch (direction) {
        case 0:
          pos[1] -= move;
          break;
        case 1:
          pos[0] += move;
          break;
        case 2:
          pos[1] += move;
          break;
        case 3:
          pos[0] -= move;
          break;
        default:
          break;
      }

      if (frame == maxFrame) {
        if (nextDirection == -1) {
          animating = false;
        } else {
          direction = nextDirection;
        }
        frame = 0;
        alSourcePlay(sources[0]);
      }
    }
    nextDirection = -1;
  }

  override void Draw() {
    double offset = height;
    switch(direction) {
      case 0:
        glBindTexture(GL_TEXTURE_2D, textures[0]);
        break;
      case 1:
        glBindTexture(GL_TEXTURE_2D, textures[1]);
        break;
      case 2:
        glBindTexture(GL_TEXTURE_2D, textures[2]);
        break;
      case 3:
        glBindTexture(GL_TEXTURE_2D, textures[3]);
        break;
      default:
        break;
    }
    glBegin(GL_QUADS);
    glTexCoord2f(0, 0);glVertex3f(pos[0] - 64, pos[1] - 64 - offset, 0);
    glTexCoord2f(1, 0);glVertex3f(pos[0] + 64, pos[1] - 64 - offset, 0);
    glTexCoord2f(1, 1);glVertex3f(pos[0] + 64, pos[1] + 64 - offset, 0);
    glTexCoord2f(0, 1);glVertex3f(pos[0] - 64, pos[1] + 64 - offset, 0);
    glEnd();
  }

  void Move(int direction) {
    if (animating){
      nextDirection = direction;
      return;
    }
    animating = true;
    this.direction = direction;
  }
  void StopMove() {
    nextDirection = -1;
  }
}