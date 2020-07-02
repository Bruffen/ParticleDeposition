#version 440

uniform mat4 m_model;

//in float size;
in vec4 position;
in vec2 texCoord0;
layout( std430, binding=1 ) buffer Directions
{
	//vec4 particlePos[];
    vec4 particleDir[];
};



out data{
    vec2 uv;
    vec4 pos;
    uint id;
    vec4 dir;
	//float size;
    //vec4 pos;
}o;

void main()
{
    o.pos = m_model * position;//particlePos[gl_VertexID];
    o.uv = texCoord0;
    o.id = gl_VertexID;
    o.dir = particleDir[gl_VertexID];
	//o.size = size;
}