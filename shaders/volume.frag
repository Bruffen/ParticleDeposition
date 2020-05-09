#version 430

/*
 * The idea here is to define a cube that represents the volume to render
 * with an height corresponding to the highest deposited particle which 
 * will be updated in real time
 *
 * If the camera is inside the cube, we raymarch along the particles' texture
 * to find the nearest particle and draw it if it's found
 * However, if the camera is outside the cube, we first do ray-AABB intersection
 * to check if the volume to render is in the ray's direction
 * and if it is, to find the clostest point in that cube and raymarch from there
 */

uniform sampler2D texRender;    // World height map
uniform sampler2D texVolume;    // World height map + particles heights

uniform vec4  position;
uniform vec3  view;
uniform float fov;
uniform float sceneUp;
uniform float sceneLf;
uniform float sceneRt;
uniform float sceneDw;

const vec3 inf = vec3(1e20, 1e20, 1e20);

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

/*
 * Tutorial from https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-box-intersection
 */
vec3 rayAABBIntersection(vec3 rayPos, vec3 rayDir)
{
    float tmin, tmax, tymin, tymax, tzmin, tzmax;
    vec3 invDir = 1.0 / rayDir;
    vec3 bounds[2] = { vec3(sceneLf, 0.0, sceneDw), vec3(sceneRt, 2.0, sceneUp) };
    int signs[3] = { invDir.x < 0 ? 1 : 0, invDir.y < 0 ? 1 : 0, invDir.z < 0 ? 1 : 0 };
 
    tmin  = (bounds[  signs[0]].x - rayPos.x) * invDir.x;
    tmax  = (bounds[1-signs[0]].x - rayPos.x) * invDir.x;
    tymin = (bounds[  signs[1]].y - rayPos.y) * invDir.y;
    tymax = (bounds[1-signs[1]].y - rayPos.y) * invDir.y;
 
    if ((tmin > tymax) || (tymin > tmax))
        return inf;
    if (tymin > tmin)
        tmin = tymin;
    if (tymax < tmax)
        tmax = tymax;
 
    tzmin = (bounds[  signs[2]].z - rayPos.z) * invDir.z;
    tzmax = (bounds[1-signs[2]].z - rayPos.z) * invDir.z;
 
    if ((tmin > tzmax) || (tzmin > tmax))
        return inf;
    if (tzmin > tmin)
        tmin = tzmin;
    if (tzmax < tmax)
        tmax = tzmax;

    return tmin > 0.0 ? rayPos + rayDir * tmin : inf;
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

void main()
{
    color = texture(texRender, uv);

    vec3 rayDir = rayDir();
    vec3 rayPos = position.xyz;
    vec3 intersectPos = rayAABBIntersection(rayPos, rayDir);
    vec4 green = vec4(0.0);
    if (intersectPos != inf)
        green = vec4(0.3, 0.7, 0.1, 1.0);
    //vec4 rayM = rayMarching(rayPos, rayDir);
    //color = mix(color, rayM, 0.5);

    color = mix(color, green, 0.5);
}