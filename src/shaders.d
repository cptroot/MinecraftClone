module shaders;

import derelict.opengl3.gl3;

import component;

class Shaders : Component {
  uint[] shaders;

  @property int ID() { return 0; };

  uint PushShader(uint shader) {
    glUseProgram(shader);

    shaders ~= shader;
    return shader;
  }

  uint PopShader() {
    uint shader = shaders[$ - 1];
    shaders = shaders[0..$ - 1];

    if (shaders.length != 0)
      glUseProgram(shaders[$ - 1]);
    else
      glUseProgram(0);

    return shader;
  }
}