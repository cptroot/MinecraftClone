#version 330

layout(location = 0) in vec2 v_coord;
uniform sampler2D fbo_texture;
 
void main(void) {
  gl_Position = vec4(v_coord, 0.0, 1.0);
}