import std.stdio;
import std.typecons;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import engine;
import block;
import player;
import error;
import gl_shader;
import shaders;
import constants;

class Game : Engine {
  uint shader, post_shader;
  uint fbo;
  uint[] fbo_textures;
  uint texture_loc, depth_loc, vertexBuffer;

  uint sampler_loc;

  const float[] vertexData = [
    1.0f, 1.0f,
    1.0f, -1.0f,
    -1.0f, 1.0f,
    -1.0f, -1.0f,
  ];

  Shaders shaders;

  this(SDL_Window* window) {
    title = "Uprising";

    SDL_SetWindowGrab(window, true);
    SDL_ShowCursor(false);

    super(window);

    //glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CW);

    glEnable(GL_DEPTH_TEST);

    // Shader
    shader = LoadProgram(["./shaders/triangle_shader.vert", "./shaders/triangle_shader.frag"], 
                         [GL_VERTEX_SHADER, GL_FRAGMENT_SHADER]);
    uint worldMatrixLocation = glGetUniformLocation(shader, "worldMatrix");
    glUseProgram(shader);
    glUniformMatrix4fv(worldMatrixLocation, 1, false, matrix.identityMatrix.ptr);
    glUseProgram(0);

    //PostProcess Shader
    post_shader = LoadProgram(["./shaders/post_process.vert", "./shaders/post_process.frag"], 
                              [GL_VERTEX_SHADER, GL_FRAGMENT_SHADER]);
    texture_loc = glGetUniformLocation(post_shader, "fbo_texture");
    depth_loc = glGetUniformLocation(post_shader, "fbo_depth");
    uint size_loc = glGetUniformLocation(post_shader, "size");
    glUseProgram(post_shader);
    glUniform2f(size_loc, width, height);
    glUseProgram(0);

    //Framebuffer for deferred rendering
    glActiveTexture(GL_TEXTURE0);
    /* Texture */
    fbo_textures = new uint[2];
    glGenTextures(2, fbo_textures.ptr);
    glBindTexture(GL_TEXTURE_2D, fbo_textures[0]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, cast(int*)0);
    glBindTexture(GL_TEXTURE_2D, 0);

    /* Depth buffer */
    glBindTexture(GL_TEXTURE_2D, fbo_textures[1]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, width, height, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, cast(int*)0);
    glBindTexture(GL_TEXTURE_2D, 0);

    /* Sampler */
    glGenSamplers(1, &sampler_loc);
    glSamplerParameteri(sampler_loc, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glSamplerParameteri(sampler_loc, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glSamplerParameteri(sampler_loc, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glSamplerParameteri(sampler_loc, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    /* Framebuffer to link everything together */
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fbo_textures[0], 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, fbo_textures[1], 0);
    GLenum status;
    if ((status = glCheckFramebufferStatus(GL_FRAMEBUFFER)) != GL_FRAMEBUFFER_COMPLETE) {
      writeln("glCheckFramebufferStatus: error ", status);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    // Vertex Buffer for Drawing texture
    glGenBuffers(1, &vertexBuffer);

    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, vertexData.length * float.sizeof, vertexData.ptr, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // Game Objects
    shaders = new Shaders();
    this.AddComponent(shaders);

    Player player = new Player();
    this.AddComponent(player);

    auto block = new Block(1, -1, -2);
    block.worldMatrixLocation = worldMatrixLocation;
    block.shader = shader;
    block.LoadResources();
    this.AddComponent(block);
    block = new Block(2, -1, -2);
    block.shader = shader;
    block.worldMatrixLocation = worldMatrixLocation;
    block.LoadResources();
    this.AddComponent(block);
    block = new Block(2, 0, -1);
    block.shader = shader;
    block.worldMatrixLocation = worldMatrixLocation;
    block.LoadResources();
    this.AddComponent(block);
  }

  override void PreProcess() {
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    shaders.PushShader(shader);
  }

  override void PostProcess() {
    shaders.PopShader();
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

    shaders.PushShader(post_shader);
    glActiveTexture(GL_TEXTURE0 + 0);
    glBindTexture(GL_TEXTURE_2D, fbo_textures[0]);
    glUniform1i(texture_loc, 0);
    glActiveTexture(GL_TEXTURE0 + 1);
    glBindTexture(GL_TEXTURE_2D, fbo_textures[1]);
    glUniform1i(depth_loc, 1);

    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, cast(int*)0);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glDisableVertexAttribArray(0);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    shaders.PopShader();
  }
}