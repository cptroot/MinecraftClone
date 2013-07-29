module camera;

import derelict.opengl.gl;

import singleton;
import component;

class Camera : Component {
	mixin Singleton;

  @property override int ID() {
    return 0;
  }
	public {
		float xpos = 0;
		float ypos = 0;
	}
	
	void SetWorldMatrix() {
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glTranslatef(xpos, ypos, 0);
	}
}