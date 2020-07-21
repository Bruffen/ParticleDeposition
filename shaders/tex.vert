#version 330

uniform mat4 m_pvm;
uniform mat4 m_vm;

in vec4 position;
in vec2 texCoord0;

out vec2 uv;
out vec4 pos;

void main()
{
    uv = texCoord0;
    gl_Position = m_pvm * position;
    pos = m_vm * position; 
}