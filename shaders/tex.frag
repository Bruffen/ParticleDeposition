#version 330

uniform sampler2D texVolume;

in vec2 uv;

out vec4 outColor;

void main()
{
    outColor = texture(texVolume, uv);
}