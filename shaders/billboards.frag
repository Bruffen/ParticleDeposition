#version 330

uniform sampler2D texVolume;

in vec2 ouv;

out vec4 outColor;

void main()
{
    outColor = vec4(0,0,1,1);
}