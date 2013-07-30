module camera;

import derelict.opengl3.gl3;

import component;

class Camera : Component, Drawable {
  @property override int ID() {
    return 0;
  }

  @property float Depth() { return float.min; };

	public {
		float xpos = 0;
		float ypos = 0;
	}

  uint perspectiveMatrixUnif;

  this() {
  }

  void AddShader(uint shader) {
    perspectiveMatrixUnif = glGetUniformLocation(shader, "perspectiveMatrix");

    float fFrustumScale = 1.0f; float fzNear = 0.5f; float fzFar = 3.0f;

    float[16] matrix = new float[16];

    foreach (ref value; matrix) value = 0;

    matrix[0] = fFrustumScale;
    matrix[5] = fFrustumScale;
    matrix[10] = (fzFar + fzNear) / (fzNear - fzFar);
    matrix[14] = (2 * fzFar * fzNear) / (fzNear - fzFar);
    matrix[11] = -1.0f;

    glUseProgram(shader);
    glUniformMatrix4fv(perspectiveMatrixUnif, 1, false, matrix.ptr);
    glUseProgram(0);
  }

  void LoadResources() { };

  void Draw() { };
}