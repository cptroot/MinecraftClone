module triangle;

import derelict.opengl3.gl3;

import std.conv;

import component;
import gl_shader;

class Triangle : Drawable, Component {
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
  }

  @property int ID() { return 1; };

  void Draw() {
    glUseProgram(shader);

    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(0u, 4, GL_FLOAT, GL_FALSE, 0, cast(int*)0);
    glVertexAttribPointer(1u, 4, GL_FLOAT, GL_FALSE, 0, cast(int*)48);

    glDrawArrays(GL_TRIANGLES, 0, 3);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glUseProgram(0);
  }
}