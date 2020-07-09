#version 330

uniform sampler2D texVolume;
uniform sampler2D test;
uniform vec4 particleColor;

in vec2 ouv;

out vec4 outColor;

void main()
{
    vec4 color = texture(test,ouv);
    outColor = particleColor;//vec4(0,0,1,1);
}