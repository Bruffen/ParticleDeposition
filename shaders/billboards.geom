#version 440
layout(points) in;
layout(triangle_strip, max_vertices=20) out;

uniform mat4 m_pv;
uniform float width;
uniform float height;

in data{
    vec2 uv;
    vec4 pos;
    uint id;
    vec4 dir;
    //float size;
    //vec4 pos;
}i[1];


void GenerateVertex(vec4 p)
{
	gl_Position = m_pv * p;
    EmitVertex();
}

uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}


float floatConstruct( uint m ) {
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                     // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                          // Add fractional part to 1.0

    float  f = uintBitsToFloat( m );       // Range [1:2]
    return f - 1.0;                        // Range [0:1]
}


float random( float x ) { return floatConstruct(hash(floatBitsToUint(x))); }

out vec2 ouv;

void main()
{ 
    ouv = i[0].uv;

    vec4 p = i[0].pos;

    float w = /*random(i[0].id) */ width + 0.01;
    float h = /*random(i[0].id) */ height + 0.01;
    // vec4 v[8];
    // v[0] = p+ vec4(-w, -h, 0, 0);
    // ouv = vec2(0,0);
    // GenerateVertex(v[0]);

    // v[1] = p + vec4(w, -h, 0, 0);
    // ouv = vec2(1,0);
    // GenerateVertex(v[1]);

    // v[2] = p + vec4(-w, +h, 0, 0);
    // ouv = vec2(0,1);
    // GenerateVertex(v[2]);

    // v[3] = p + vec4(w, + h, 0, 0);
    // ouv = vec2(1,1);
    // GenerateVertex(v[3]);

    // //Back side

    // v[4] = p+ vec4(w, -h, 0, 0);
    // ouv = vec2(0,0);
    // GenerateVertex(v[0]);

    // v[5] = p + vec4(-w, -h, 0, 0);
    // ouv = vec2(1,0);
    // GenerateVertex(v[1]);

    // v[6] = p + vec4(w, +h, 0, 0);
    // ouv = vec2(0,1);
    // GenerateVertex(v[2]);

    // v[7] = p + vec4(-w, + h, 0, 0);
    // ouv = vec2(1,1);
    // GenerateVertex(v[3]);
    vec4 v[14];
    vec2 uv_array[14];
	v[0] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	- (width/2), 1.0f);
    uv_array[0] = vec2(0,1);
	v[1] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	- (width/2), 1.0f);
    uv_array[0] = vec2(1,1);
	v[2] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	- (height/2), i[0].pos.z	- (width/2), 1.0f);
    uv_array[0] = vec2(0,0);
	v[3] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	- (height/2), i[0].pos.z	- (width/2), 1.0f);
    uv_array[0] = vec2(1,0);

	v[4] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	- (height/2), i[0].pos.z	+ (width/2), 1.0f);
    uv_array[0] = vec2(0,0);
	v[5] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	- (width/2), 1.0f);
    uv_array[0] = vec2(0,1);
	v[6] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	+ (width/2), 1.0f);
     uv_array[0] = vec2(1,1);
	v[7] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	- (width/2), 1.0f);
    uv_array[0] = vec2(0,1);

	v[8] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	+ (width/2), 1.0f);
    uv_array[0] = vec2(1,1);
	v[9] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	- (height/2), i[0].pos.z	- (width/2), 1.0f);
    uv_array[0] = vec2(0,0);
	v[10] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	- (height/2), i[0].pos.z	+ (width/2), 1.0f);
    uv_array[0] = vec2(1,0);
	v[11] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	- (height/2), i[0].pos.z	+ (width/2), 1.0f);
    uv_array[0] = vec2(0,0);

	v[12] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	+ (width/2), 1.0f);
    uv_array[0] = vec2(1,0);
	v[13] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	+ (width/2), 1.0f);
    uv_array[0] = vec2(1,0);

    for(int i = 0;i<14;i++)
    {
        ouv = uv_array[i];
        GenerateVertex(v[i]);
    }

    EndPrimitive();
    

    //gl_Position = pos;
}