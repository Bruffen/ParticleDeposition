#version 440
layout(points) in;
layout(triangle_strip, max_vertices=200) out;

uniform mat4 m_model;
uniform mat4 m_pv;
uniform float width;
uniform float height;
uniform int particlesActive;
uniform float radius;

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


mat3 AngleAxis3x3(float anglex, float angley, vec3 axis)
{
	float c, s;
	c = cos(anglex);
	s = sin(angley);

	float t = 1 - c;
	float x = axis.x;
	float y = axis.y;
	float z = axis.z;

	return mat3(
		t * x * x + c, t * x * y - s * z, t * x * z + s * y,
		t * x * y + s * z, t * y * y + c, t * y * z - s * x,
		t * x * z - s * y, t * y * z + s * x, t * z * z + c
		);
}

float random( float x ) { return floatConstruct(hash(floatBitsToUint(x))); }

out vec2 ouv;

void main()
{ 
    ouv = i[0].uv;

    vec4 p = i[0].pos;

    float w = /*random(i[0].id) */ width + 0.01;
    float h = /*random(i[0].id) */ height + 0.01;

    float x = dot(vec3(0,1,0), vec3(1,0,0));
    float y = dot(vec3(0,1,0), vec3(0,0,1));

    mat3 directionMatrix = AngleAxis3x3(x,y, vec3(1,0,1));

    if (particlesActive == 1)
    {
        vec4 v[14];
        vec2 uv_array[14];
        v[0] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	- (width/2), 1.0f);
        uv_array[0] = vec2(0,1);
        v[1] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	- (width/2), 1.0f);
        uv_array[1] = vec2(1,1);
        v[2] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	- (height/2), i[0].pos.z	- (width/2), 1.0f);
        uv_array[2] = vec2(0,0);
        v[3] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	- (height/2), i[0].pos.z	- (width/2), 1.0f);
        uv_array[3] = vec2(1,0);

        v[4] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	- (height/2), i[0].pos.z	+ (width/2), 1.0f);
        uv_array[4] = vec2(0,0);
        v[5] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	- (width/2), 1.0f);
        uv_array[5] = vec2(0,1);
        v[6] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	+ (width/2), 1.0f);
        uv_array[6] = vec2(1,1);
        v[7] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	- (width/2), 1.0f);
        uv_array[7] = vec2(0,1);

        v[8] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	+ (width/2), 1.0f);
        uv_array[8] = vec2(1,1);
        v[9] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	- (height/2), i[0].pos.z	- (width/2), 1.0f);
        uv_array[9] = vec2(0,0);
        v[10] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	- (height/2), i[0].pos.z	+ (width/2), 1.0f);
        uv_array[10] = vec2(1,0);
        v[11] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	- (height/2), i[0].pos.z	+ (width/2), 1.0f);
        uv_array[11] = vec2(0,0);

        v[12] = vec4(i[0].pos.x	- (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	+ (width/2), 1.0f);
        uv_array[12] = vec2(1,0);
        v[13] = vec4(i[0].pos.x	+ (width/2), i[0].pos.y	+ (height/2), i[0].pos.z	+ (width/2), 1.0f);
        uv_array[13] = vec2(1,0);

        for(int i = 0;i<14;i++)
        {
            ouv = uv_array[i];
            GenerateVertex(v[i]);
        }

        EndPrimitive();
    }

    if (i[0].id == 0)
    {
        vec4 circlepos = vec4(0,50,0,1);  //introduce a single vertex at the origin
        //circlepos = i[0].pos;  //translate it to where our model is
                                                            //ideally do this step outside the shader
        float r = sqrt(radius);
        for(float i = 2 * 3.1415; i >= 0 ; i-=2 * 3.1415/20)  //generate vertices at positions on the circumference from 0 to 2*pi
        {
            GenerateVertex(vec4(circlepos.x+r*cos(i),circlepos.y,circlepos.z+r*sin(i),1.0));   //circle parametric equation
            GenerateVertex(vec4(circlepos.x,circlepos.y,circlepos.z,1.0));
        }
        GenerateVertex(vec4(circlepos.x+r*cos(0),circlepos.y,circlepos.z+r*sin(0),1.0));
    }
    

    //gl_Position = pos;
}