module triangle;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import std.conv;
import std.typecons;
import std.math : sin, cos, PI;

import component;
import gl_shader;

class Triangle : Drawable, Component, Updateable {
  const float vertexData[] = [
    0.0f,    0.5f, 0.0f, 1.0f,
    0.5f, -0.366f, 0.0f, 1.0f,
   -0.5f, -0.366f, 0.0f, 1.0f,
    1.0f,    0.0f, 0.0f, 1.0f,
    0.0f,    1.0f, 0.0f, 1.0f,
    0.0f,    0.0f, 1.0f, 1.0f,
  ];

  uint positionBufferObject;
  uint shader;
  uint offsetLocation;

  Tuple!(float, float) offset;
  float time = 0;
  const float loopLength = 5f;

  @property float Depth() { return 1; };

  this() {
    LoadResources();
  }

  void LoadResources() {
    glGenBuffers(1, &positionBufferObject);

    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glBufferData(GL_ARRAY_BUFFER, to!int(vertexData.length * float.sizeof),
                 vertexData.ptr, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    shader = LoadProgram(["./triangle_shader.vert", "./triangle_shader.frag"], 
                         [GL_VERTEX_SHADER, GL_FRAGMENT_SHADER]);
    
    offsetLocation = glGetUniformLocation(shader, "offset");
  }

  @property int ID() { return 1; };

  bool Update(SDL_Event[] events) {
    time += .016f;
    if (time >= loopLength) time -= loopLength;

    offset[0] = .3 * sin(time / loopLength * 2 * PI);
    offset[1] = .3 * cos(time / loopLength * 2 * PI);

    return false;
  }

  void Draw() {
    glUseProgram(shader);

    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);

    glUniform2f(offsetLocation, offset[0], offset[1]);

    glVertexAttribPointer(0u, 4, GL_FLOAT, GL_FALSE, 0, cast(int*)0);
    glVertexAttribPointer(1u, 4, GL_FLOAT, GL_FALSE, 0, cast(int*)48);

    glDrawArrays(GL_TRIANGLES, 0, 3);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glUseProgram(0);
  }
}