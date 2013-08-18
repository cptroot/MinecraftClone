module block;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import std.conv;
import std.typecons;
import std.math : sin, cos, PI;

import engine;
import error;
import camera;
import component;
import gl_shader;

import matrix;

class Block : Drawable, Component {

  static const float vertexData[] = [
      .5f,  .5f,  .5f,
      .5f,  .5f, -.5f,
      .5f, -.5f, -.5f,
      .5f, -.5f,  .5f,

    -.5f, -.5f,  .5f,
    -.5f, -.5f, -.5f,
    -.5f,  .5f, -.5f,
    -.5f,  .5f,  .5f,
  ];

  static const ushort indexData[] = [
    0, 1, 2,
    2, 3, 0,

    4, 3, 2,
    2, 5, 4,

    4, 5, 6,
    6, 7, 4,

    5, 2, 1,
    1, 6, 5,

    1, 0, 7,
    7, 6, 1,

    0, 3, 4,
    4, 7, 0,
  ];

  static bool loaded = false;
  static uint shader;
  static uint blockVAO;

  static uint worldMatrixLocation;

  Tuple!(int, int, int) location = tuple(1, -1, -2);
  float[] worldMatrix;

  @property float Depth() { return 1; };

  this() {
  }

  void LoadResources() {
    if (!loaded) {
      // Generate block buffer object
      uint blockBufferObject;
      glGenBuffers(1, &blockBufferObject);

      glBindBuffer(GL_ARRAY_BUFFER, blockBufferObject);
      glBufferData(GL_ARRAY_BUFFER, to!int(vertexData.length * float.sizeof),
                   vertexData.ptr, GL_STATIC_DRAW);
      glBindBuffer(GL_ARRAY_BUFFER, 0);

      // Generate index buffer object
      uint indexBufferObject;
      glGenBuffers(1, &indexBufferObject);

      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferObject);
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, to!int(indexData.length * ushort.sizeof),
                   indexData.ptr, GL_STATIC_DRAW);
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

      // Bind them into the vertex array
      glGenVertexArrays(1, &blockVAO);
      glBindVertexArray(blockVAO);

      glBindBuffer(GL_ARRAY_BUFFER, blockBufferObject);
      glEnableVertexAttribArray(0);
      glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(int*)0);
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferObject);

      glBindVertexArray(0);

      shader = LoadProgram(["./triangle_shader.vert", "./triangle_shader.frag"], 
                           [GL_VERTEX_SHADER, GL_FRAGMENT_SHADER]);

      worldMatrixLocation = glGetUniformLocation(shader, "worldMatrix");

      glUseProgram(shader);
      glUniformMatrix4fv(worldMatrixLocation, 1, false, matrix.identityMatrix.ptr);
      glUseProgram(0);

      loaded = true;

      Component[int] cameras = iEngine.GetComponents!Camera();

      foreach (cCamera; cameras) {
        Camera camera = cast(Camera)cCamera;
        camera.AddShader(shader);
      }
    }

    worldMatrix = matrix.translationMatrix(true, location[0], location[1], location[2]);
  }

  @property int ID() { return 1; };

  void Draw() {
    glUseProgram(shader);
    glBindVertexArray(blockVAO);

    glUniformMatrix4fv(worldMatrixLocation, 1, true, worldMatrix.ptr);

    glDrawElements(GL_TRIANGLES, indexData.length, GL_UNSIGNED_SHORT, cast(int*)0);

    glBindVertexArray(0);
    glUseProgram(0);
  }
}