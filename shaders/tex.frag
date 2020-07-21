#version 430

uniform sampler2D render;
uniform writeonly image2D depthtex;   
uniform vec4 camerapos;
uniform mat4 m_view;

in vec4 pos;
in vec2 uv;

out vec4 outColor;

void main()
{
    float dist = length(pos - (m_view * camerapos));
    vec4 c = vec4(dist,0,0,1);
    outColor = c;
}