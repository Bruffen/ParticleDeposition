#version 330

uniform sampler2D texRender;    // World height map
uniform sampler2D texVolume;    // World height map + particles heights

uniform vec4  position;
uniform vec3  view;
uniform float fov;
uniform vec2  screenSize;

in vec2 uv;

out vec4 color;

vec3 rayDir()
{
    float aspectRatio = 16.0/9.0;     // assuming 16:9 aspect ratio

    vec2 screenCoords = uv * 2.0 - 1.0;
    float height = tan(radians(fov) * 0.5);

    vec3 right = normalize(cross(view, vec3(0.0, 1.0, 0.0)));
    vec3 up = normalize(cross(right, view));
    vec3 rayDir = view + (right * height * aspectRatio * screenCoords.x) + (up * height * screenCoords.y);
    return normalize(rayDir);
}

vec4 rayMarching(vec3 rayPos, vec3 rayDir)
{
    for (int i = 0; i < 100; i++)
    {
        vec3 pos = rayPos + rayDir * i * 0.05;
        if (pos.y < 0.0) return vec4(0.0);
        
        float volumeHeight = sin(pos.x) + cos(pos.z);
        if (pos.y < volumeHeight)
        {
            return vec4(0.2, 0.3, 1.0, 1.0);
        }
    }
    return vec4(0.0);
}

/*
 * Plano:
 * Intersetar raio com plano para saber se há interseção
 ** se não houver, descarta
 ** se houver, fazer ray marching do ponto para a câmara
 *** pode ser feito passo a passo
 *** ou ir verificando o meio
 */

vec4 rayPlane(vec3 rayPos, vec3 rayDir)
{
    // Plane properties
    vec3 center = vec3(0, 0, 0);
    vec3 normal = vec3(0, 1, 0);
    vec2 size   = vec2(10, 10);

    // Ray-plane projections
    vec3  rayToCenter = center - rayPos;
    float dist = dot(rayToCenter, normal) / dot(rayDir, normal); // distance away from plane in ray direction
    vec3  position = rayPos + dist * rayDir;

    if (dist >= 0) {
        if (position.x > -size.x && position.x < size.x &&
            position.z > -size.y && position.z < size.y) {
            return vec4(1.0);
        }
    }
    return vec4(0.0);
}

vec4 marchToCamera(vec3 initialPos, vec3 direction)
{

    return vec4(1.0);
}

void main()
{
    color = texture(texRender, uv);

    vec3 rayDir = rayDir();
    vec3 rayPos = position.xyz;
    //vec4 rayM = rayMarching(rayPos, rayDir);
    //color = mix(color, rayM, 0.5);
    vec4 green = vec4(0.3, 0.7, 0.1, 1.0);

    color = mix(color, rayPlane(rayPos, rayDir) * green, 0.5);
}