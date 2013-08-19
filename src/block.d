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
     .5f,  .5f,  .5f,
     .5f,  .5f,  .5f,

     .5f,  .5f, -.5f,
     .5f,  .5f, -.5f,
     .5f,  .5f, -.5f,

     .5f, -.5f, -.5f,
     .5f, -.5f, -.5f,
     .5f, -.5f, -.5f,

     .5f, -.5f,  .5f,
     .5f, -.5f,  .5f,
     .5f, -.5f,  .5f,

    -.5f, -.5f,  .5f,
    -.5f, -.5f,  .5f,
    -.5f, -.5f,  .5f,

    -.5f, -.5f, -.5f,
    -.5f, -.5f, -.5f,
    -.5f, -.5f, -.5f,

    -.5f,  .5f, -.5f,
    -.5f,  .5f, -.5f,
    -.5f,  .5f, -.5f,

    -.5f,  .5f,  .5f,
    -.5f,  .5f,  .5f,
    -.5f,  .5f,  .5f,
  ];

  static const float normalData[] = [
     1f,  0f,  0f,
     0f,  1f,  0f,
     0f,  0f,  1f,
               
     1f,  0f,  0f,
     0f,  1f,  0f,
     0f,  0f, -1f,
               
     1f,  0f,  0f,
     0f, -1f,  0f,
     0f,  0f, -1f,
               
     1f,  0f,  0f,
     0f, -1f,  0f,
     0f,  0f,  1f,
               
    -1f,  0f,  0f,
     0f, -1f,  0f,
     0f,  0f,  1f,
               
    -1f,  0f,  0f,
     0f, -1f,  0f,
     0f,  0f, -1f,
               
    -1f,  0f,  0f,
     0f,  1f,  0f,
     0f,  0f, -1f,
               
    -1f,  0f,  0f,
     0f,  1f,  0f,
     0f,  0f,  1f,
  ];

  static const ushort indexData[] = [
     0,  3,  6,
     6,  9,  0,

     1, 22, 19,
    19,  4,  1,

     2, 11, 14,
    14, 23,  2,

    15, 18, 21,
    21, 12, 15,

    16, 13, 10,
    10,  7, 16,

    17,  8,  5,
     5, 20, 17,
  ];

  static bool loaded = false;
  static uint shader;
  static uint blockVAO;

  static uint worldMatrixLocation;

  Tuple!(int, int, int) location = tuple(0, 0, -2);
  float[] worldMatrix;

  @property float Depth() { return 1; };

  this() {
    id = id_iter++;
  }

  this(int x, int y, int z) {
    location = tuple(x, y, z);
    this();
  }

  void LoadResources() {
    if (!loaded) {
      // Generate block buffer object
      uint blockBufferObject;
      glGenBuffers(1, &blockBufferObject);

      glBindBuffer(GL_ARRAY_BUFFER, blockBufferObject);
      glBufferData(GL_ARRAY_BUFFER, to!int(vertexData.length * float.sizeof),
                   vertexData.ptr, GL_STATIC_DRAW);

      // Generate normal buffer object
      uint normalBufferObject;
      glGenBuffers(1, &normalBufferObject);

      glBindBuffer(GL_ARRAY_BUFFER, normalBufferObject);
      glBufferData(GL_ARRAY_BUFFER, to!int(normalData.length * float.sizeof),
                   normalData.ptr, GL_STATIC_DRAW);

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
      glBindBuffer(GL_ARRAY_BUFFER, normalBufferObject);
      glEnableVertexAttribArray(1);
      glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(int*)0);
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferObject);

      glBindVertexArray(0);

      loaded = true;

      Component[int] cameras = iEngine.GetComponents!Camera();

      foreach (cCamera; cameras) {
        Camera camera = cast(Camera)cCamera;
        camera.AddShader(shader);
      }
    }

    worldMatrix = matrix.translationMatrix(true, location[0], location[1], location[2]);
  }

  static int id_iter = 0;
  int id;
  @property int ID() { return id; };

  void Draw() {
    glBindVertexArray(blockVAO);

    glUniformMatrix4fv(worldMatrixLocation, 1, true, worldMatrix.ptr);

    glDrawElements(GL_TRIANGLES, indexData.length, GL_UNSIGNED_SHORT, cast(int*)0);

    glBindVertexArray(0);
  }
}