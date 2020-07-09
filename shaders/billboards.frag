#version 330

uniform sampler2D texVolume;
uniform sampler2D test;

in vec2 ouv;

out vec4 outColor;

void main()
{
    vec4 color = texture(test,ouv);
    outColor = vec4(0,0,1,1);
}