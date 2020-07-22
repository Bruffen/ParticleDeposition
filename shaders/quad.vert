#version 330

uniform mat4 m_pvm;

in vec4 position;
in vec2 texCoord0;

out vec2 uv;

void main() {
	gl_Position = position;
	uv = texCoord0;
}
