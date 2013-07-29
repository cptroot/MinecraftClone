import derelict.opengl3.gl3;
import derelict.openal.al;

//string s = GLError();
//if (s != "") throw new Exception(s);

string GLError() {
  uint err = glGetError();
  while (err != GL_NO_ERROR) {
    if (err == GL_INVALID_ENUM) return "GL_INVALID_ENUM";
    if (err == GL_INVALID_VALUE) return "GL_INVALID_VALUE";
    if (err == GL_INVALID_OPERATION) return "GL_INVALID_OPERATION";
    // if (err == GL_INVALID_FRAMEBUFFER_OPERATION) return "GL_INVALID_FRAMEBUFFER_OPERATION");
  }
  return "";
}
string ALError() {
  uint err = alGetError();
  while (err != AL_NO_ERROR) {
    if (err == AL_INVALID_NAME) return "AL_INVALID_NAME";
    if (err == AL_INVALID_ENUM) return "AL_INVALID_ENUM";
    if (err == AL_INVALID_VALUE) return "AL_INVALID_VALUE";
    if (err == AL_INVALID_OPERATION) return "AL_INVALID_OPERATION";
  }
  return "";
}