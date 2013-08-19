module camera;

import std.typecons;
import std.math : isNaN;

import derelict.opengl3.gl3;

import component;
import matrix;
import constants;
import engine;
import shaders;
import error;

class Camera : Component, Drawable {
  @property override int ID() {
    return 0;
  }

  static Matrix perspectiveMatrix;

  Matrix cameraMatrix;
  private Vector3 _position;
  private SphereRot _rotation = tuple(0.0, 0.0);

  @property Vector3 position() { return _position; }
  @property void position(Vector3 pos) {
    if (pos != _position) {
      _position = pos;
      changed = true;
    }
  }
  /*@property void position(Tuple!(float, float, float) pos) {
    if (pos != _position) {
      _position = pos;
      changed = true;
    }
  }*/

  @property Vector3 forward() {
    Vector3 result;
    result.z = -1.0f;
    result *= rotationMatrix(false, rotation.phi, 1, 0, 0);
    result *= rotationMatrix(false, rotation.theta, 0, 1, 0);
    return result;
  }

  @property Vector3 left() {
    Vector3 result;
    result.x = -1.0f;
    result *= rotationMatrix(false, rotation.phi, 1, 0, 0);
    result *= rotationMatrix(false, rotation.theta, 0, 1, 0);
    return result;
  }

  @property SphereRot rotation() { return _rotation; }
  @property void rotation(SphereRot rot) {
    if (rot != _rotation) {
      _rotation = rot;
      changed = true;
    }
  }
  @property void rotation(Tuple!(float, float) rot) {
    if (rot != _rotation) {
      _rotation = rot;
      changed = true;
    }
  }

  float changed = true;

  uint[] shaders;

  Shaders shaderHelper;

  @property float Depth() { return float.min; };

  uint perspectiveMatrixUnif;

  this() {
    if (isNaN(perspectiveMatrix[0])) {
      float fFrustumScale = 1.0f; float fzNear = 0.2f; float fzFar = 20.0f;

      perspectiveMatrix = new float[16];

      foreach (ref value; perspectiveMatrix) value = 0;

      perspectiveMatrix[0] = fFrustumScale * height / width;
      perspectiveMatrix[5] = fFrustumScale;
      perspectiveMatrix[10] = (fzFar + fzNear) / (fzNear - fzFar);
      perspectiveMatrix[11] = (2 * fzFar * fzNear) / (fzNear - fzFar);
      perspectiveMatrix[14] = -1.0f;

      cameraMatrix = identityMatrix.dup;
    }

    shaderHelper = iEngine.GetComponent!Shaders();
  }

  void AddShader(uint shader) {
    perspectiveMatrixUnif = glGetUniformLocation(shader, "perspectiveMatrix");

    glUseProgram(shader);
    glUniformMatrix4fv(perspectiveMatrixUnif, 1, true, perspectiveMatrix.ptr);
    glUseProgram(0);

    shaders ~= shader;
  }

  void LoadResources() { };

  void Draw() { 
    if (changed) {
      cameraMatrix = identityMatrix.dup;
      cameraMatrix *= rotationMatrix(false, -rotation.phi, 1, 0, 0);
      cameraMatrix *= rotationMatrix(false, -rotation.theta, 0, 1, 0);
      cameraMatrix *= translationMatrix(false, -position.x, -position.y, -position.z);
      auto mat = perspectiveMatrix * cameraMatrix;
      changed = false;
      foreach (shader; shaders) {
        shaderHelper.PushShader(shader);
        glUniformMatrix4fv(perspectiveMatrixUnif, 1, true, mat.ptr);
        shaderHelper.PopShader();
      }
    }
  };
}