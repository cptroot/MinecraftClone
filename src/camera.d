module camera;

import std.typecons;
import std.math : isNaN;

import derelict.opengl3.gl3;

import component;
import matrix;

public alias Tuple!(float, "x", float, "y", float, "z") Vector3;
public alias Tuple!(float, "theta", float, "phi") SphereRot;

class Camera : Component, Drawable {
  @property override int ID() {
    return 0;
  }

  static Matrix perspectiveMatrix;

  Matrix cameraMatrix;
  private Vector3 _position = tuple(0.0f, 0.0f, 0.0f);
  private SphereRot _rotation = tuple(0.0, 0.0);

  @property Vector3 position() { return _position; }
  @property void position(Vector3 pos) {
    if (pos != _position) {
      _position = pos;
      changed = true;
    }
  }
  @property void position(Tuple!(float, float, float) pos) {
    if (pos != _position) {
      _position = pos;
      changed = true;
    }
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

  @property float Depth() { return float.min; };

	public {
		float xpos = 0;
		float ypos = 0;
	}

  uint perspectiveMatrixUnif;

  this() {
    if (isNaN(perspectiveMatrix[0])) {
      float fFrustumScale = 1.0f; float fzNear = 0.5f; float fzFar = 3.0f;

      perspectiveMatrix = new float[16];

      foreach (ref value; perspectiveMatrix) value = 0;

      perspectiveMatrix[0] = fFrustumScale;
      perspectiveMatrix[5] = fFrustumScale;
      perspectiveMatrix[10] = (fzFar + fzNear) / (fzNear - fzFar);
      perspectiveMatrix[11] = (2 * fzFar * fzNear) / (fzNear - fzFar);
      perspectiveMatrix[14] = -1.0f;

      cameraMatrix = identityMatrix.dup;
    }
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
      foreach (shader; shaders) {
        glUseProgram(shader);
        glUniformMatrix4fv(perspectiveMatrixUnif, 1, true, mat.ptr);
      }
      glUseProgram(0);
    }
  };
}