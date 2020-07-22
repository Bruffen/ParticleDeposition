#version 440
layout(points) in;
layout(triangle_strip, max_vertices=300) out;

uniform mat4 m_model;
uniform mat4 m_pv;
uniform mat3 normalMatrix;
uniform float width;
uniform float height;
uniform int particlesActive;
uniform float radius;
uniform vec3 windDir;
uniform float gravity;
uniform float speed;
uniform vec3 spawnPos;
uniform float maxY;
uniform float minY;
uniform int wholeMap;

uniform float sceneHt; // max y bound
uniform float sceneRt; // max x bound
uniform float sceneLf; // min x bound
uniform float sceneUp; // max z bound
uniform float sceneDw; // min z bound

in data{
    vec2 uv;
    vec4 pos;
    uint id;
    vec4 dir;
    //float size;
    //vec4 pos;
}i[1];


out vec3 normal;
out float type;

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


vec4 setAxisAngle (vec3 axis, float rad) {
  rad = rad * 0.5;
  float s = sin(rad);
  return vec4(s * axis[0], s * axis[1], s * axis[2], cos(rad));
}

vec3 xUnitVec3 = vec3(1.0, 0.0, 0.0);
vec3 yUnitVec3 = vec3(0.0, 1.0, 0.0);

vec4 rotationTo (vec3 a, vec3 b) {
  float vecDot = dot(a, b);
  vec3 tmpvec3 = vec3(0);
  if (vecDot < -0.999999) {
    tmpvec3 = cross(xUnitVec3, a);
    if (length(tmpvec3) < 0.000001) {
      tmpvec3 = cross(yUnitVec3, a);
    }
    tmpvec3 = normalize(tmpvec3);
    return setAxisAngle(tmpvec3, 3.1415);
  } else if (vecDot > 0.999999) {
    return vec4(0,0,0,1);
  } else {
    tmpvec3 = cross(a, b);
    vec4 _out = vec4(tmpvec3[0], tmpvec3[1], tmpvec3[2], 1.0 + vecDot);
    return normalize(_out);
  }
}

vec4 multQuat(vec4 q1, vec4 q2) {
  return vec4(
    q1.w * q2.x + q1.x * q2.w + q1.z * q2.y - q1.y * q2.z,
    q1.w * q2.y + q1.y * q2.w + q1.x * q2.z - q1.z * q2.x,
    q1.w * q2.z + q1.z * q2.w + q1.y * q2.x - q1.x * q2.y,
    q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
  );
}

vec3 rotateVector( vec4 quat, vec3 vec ) {
  // https://twistedpairdevelopment.wordpress.com/2013/02/11/rotating-a-vector-by-a-quaternion-in-glsl/
  vec4 qv = multQuat( quat, vec4(vec, 0.0) );
  return multQuat( qv, vec4(-quat.x, -quat.y, -quat.z, quat.w) ).xyz;
}

float random( float x ) { return floatConstruct(hash(floatBitsToUint(x))); }


void GenerateCircle(float circleY)
{
  vec4 circlepos = vec4(spawnPos,1);  //introduce a single vertex at the origin
  circlepos.y = circleY;

  float r = sqrt(radius);
  for(float i = 2 * 3.1415; i >= -1 ; i-=2 * 3.1415/20)  //generate vertices at positions on the circumference from 0 to 2*pi
  {
    GenerateVertex(vec4(circlepos.x+r*cos(i),circlepos.y,circlepos.z+r*sin(i),1.0));   //circle parametric equation
    GenerateVertex(vec4(circlepos.x,circlepos.y,circlepos.z,1.0));
  }

  //GenerateVertex(vec4(circlepos.x+r*cos(0),circlepos.y,circlepos.z+r*sin(0),1.0));

  EndPrimitive();
}


void GenerateSquare(float circleY)
{
    vec4 center = vec4(spawnPos,1);
    center.y = circleY;

    vec4 vert1 = vec4(center.x + sceneLf,center.y, center.z + sceneDw,1);
    vec4 vert2 = vec4(center.x + sceneRt,center.y, center.z + sceneDw,1);
    vec4 vert3 = vec4(center.x + sceneLf,center.y, center.z + sceneUp,1);
    vec4 vert4 = vec4(center.x + sceneRt,center.y, center.z + sceneUp,1);

    //Looking Down face
    GenerateVertex(vert4);
    GenerateVertex(vert3);
    GenerateVertex(vert2);
    GenerateVertex(vert1);

    EndPrimitive();

    //Looking Up face
    GenerateVertex(vert3);
    GenerateVertex(vert4);
    GenerateVertex(vert1);
    GenerateVertex(vert2);

    EndPrimitive();
}

vec3 gNormals[14] =
	{
		vec3(0.0f, 0.0f, -1.0f),
		vec3(0.0f, 0.0f, -1.0f),
		vec3(0.0f, 0.0f, -1.0f),
		vec3(0.0f, 0.0f, -1.0f),

		vec3(1.0f, 0.0f,  0.0f),
		vec3(1.0f, 0.0f,  0.0f),
		vec3(1.0f, 0.0f,  0.0f),

		vec3(-1.0f, 0.0f,  0.0f),
		vec3(-1.0f, 0.0f,  0.0f),
		vec3(-1.0f, 0.0f,  0.0f),
		vec3(-1.0f, 0.0f,  0.0f),

		vec3(0.0f, 0.0f,  1.0f),
		vec3(0.0f, 0.0f,  1.0f),
		vec3(0.0f, 0.0f,  1.0f)
	};








void main()
{ 
    vec4 p = i[0].pos;

    float w = /*random(i[0].id) */ width + 0.01;
    float h = /*random(i[0].id) */ height + 0.01;

    //Real particle direction
    vec4 d = i[0].dir;// + vec4(windDir,1);
    d.x *= (speed);
    d.z *= (speed);
    d.y = (gravity);
    d.xyz += windDir.xyz * 0.1;
    d = normalize(d);

    vec3 forward = vec3(0,-1,0);

    //Quaternion with rotation
    vec4 quaternion1 = rotationTo(forward, vec3(d));
    mat3 n = mat3(m_pv * m_model);
    n = inverse(normalMatrix);
    n = transpose(normalMatrix);

    //Particle
    type = 0;

    //Generate Cube
    if (particlesActive == 1)
    {
 
        vec3 v[24];
        
        //FRONT
        v[0] = vec3(- (width/2), - (height/2), + (width/2));  
        v[1] = vec3(+ (width/2), - (height/2), + (width/2));
        v[2] = vec3(+ (width/2), + (height/2), + (width/2));
        v[3] = vec3(- (width/2), + (height/2), + (width/2));

        //BACK
        v[4] = vec3(- (width/2), - (height/2), - (width/2));
        v[5] = vec3(- (width/2), + (height/2), - (width/2));
        v[6] = vec3(+ (width/2), + (height/2), - (width/2));
        v[7] = vec3(+ (width/2), - (height/2), - (width/2));

        //TOP
        v[8] = vec3(- (width/2), + (height/2), - (width/2));
        v[9] = vec3(- (width/2), + (height/2), + (width/2));
        v[10] = vec3(+ (width/2), + (height/2), + (width/2));
        v[11] = vec3(+ (width/2), + (height/2), - (width/2));

        //BOTTOM
        v[12] = vec3(- (width/2), - (height/2), - (width/2));
        v[13] = vec3(+ (width/2), - (height/2), - (width/2));
        v[14] = vec3(+ (width/2), - (height/2), + (width/2));
        v[15] = vec3(- (width/2), - (height/2), + (width/2));

        //RIGHT
        v[16] = vec3(+ (width/2), - (height/2), - (width/2));
        v[17] = vec3(+ (width/2), + (height/2), - (width/2));
        v[18] = vec3(+ (width/2), + (height/2), + (width/2));
        v[19] = vec3(+ (width/2), - (height/2), + (width/2));
 
        //LEFT
        v[20] = vec3(- (width/2), - (height/2), - (width/2));
        v[21] = vec3(- (width/2), - (height/2), + (width/2));
        v[22] = vec3(- (width/2), + (height/2), + (width/2));
        v[23] = vec3(- (width/2), + (height/2), - (width/2));


        for(int i = 0;i<23;i+=4)
        {
            vec3 p1 = p.xyz + rotateVector(quaternion1, (m_model * vec4(v[i],1)).xyz);
            vec3 p2 = p.xyz + rotateVector(quaternion1, (m_model * vec4(v[i+1],1)).xyz);
            vec3 p3 = p.xyz + rotateVector(quaternion1, (m_model * vec4(v[i+2],1)).xyz);
            vec3 p4 = p.xyz + rotateVector(quaternion1, (m_model * vec4(v[i+3],1)).xyz);
 
            //Generate normals and vertices
            normal = normalize(cross(p2 - p1, p4 - p1));
            GenerateVertex(vec4(p1,1));

            normal = normalize(cross(p3 - p2, p1 - p2));
            GenerateVertex(vec4(p2,1));

            normal = normalize(cross(p4 - p3, p2 - p3));
            GenerateVertex(vec4(p4,1));

            normal = normalize(cross(p1 - p4, p3 - p4));
            GenerateVertex(vec4(p3,1));
            EndPrimitive();
        }


        EndPrimitive();
    }

    if (i[0].id == 0)
    {
      //Generate Squares
      if (wholeMap == 1)
      {
        type = 1;
        GenerateSquare(maxY);

        // type = 2;
        // GenerateSquare(minY);
      }
      //Generate Circle
      else if (wholeMap == 0)
      {
        //Max height circle
        type = 1;
        GenerateCircle(maxY);

        EndPrimitive();

        // //Min height circle
        // type = 2;
        // GenerateCircle(minY);

        // EndPrimitive();
      }
    }
}