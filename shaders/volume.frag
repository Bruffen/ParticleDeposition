#version 430

/*
 * The idea is to define a bounding box representing the volume to render
 * with an height corresponding to the highest deposited particle which 
 * will be updated in real time
 *
 * If the camera is inside the box, we raymarch along the particles' texture
 * to find the nearest particle and draw it if it's found
 * However, if the camera is outside the box, we first do ray-AABB intersection
 * to check if the volume to render is in the ray's direction
 * and if it is, to find the clostest point in that box and raymarch from there
 */

uniform sampler2D texRender;    
uniform sampler2D heightMap;    // World height map
uniform sampler2D texVolume;    // World height map + particles heights
const float particleHighest = 2.0;

uniform vec3 lightDir;

uniform vec4  position;
uniform vec3  view;
uniform vec3  right;
uniform vec3  up;
uniform float fov;
uniform float sceneHt;
uniform float sceneUp;
uniform float sceneLf;
uniform float sceneRt;
uniform float sceneDw;

uniform sampler2D texRenderZ;
uniform float zNear;
uniform float zFar;
uniform vec2  windowSize;

uniform float normalOffset;
uniform float volumeAlpha;
uniform float marchingStep;
uniform int   marchingMax;

const vec3 inf = vec3(1e20, 1e20, 1e20);

in vec2 uv;

out vec4 color;

vec3 rayDir()
{
    float aspectRatio = windowSize.x / windowSize.y;

    vec2 screenCoords = uv * 2.0 - 1.0;
    float height = tan(radians(fov) * 0.5);

    //vec3 right  = normalize(cross(view, vec3(0.0, 1.0, 0.0)));
    //vec3 up     = normalize(cross(right, view));
    vec3 rayDir = view + (right * height * aspectRatio * screenCoords.x) + (up * height * screenCoords.y);
    //rayDir = vec3(0, 0, -1) + (vec3(1, 0, 0) * height * aspectRatio * screenCoords.x) + (vec3(0, 1, 0) * height * screenCoords.y);
    return normalize(rayDir);
}

/*
 * Tutorial from https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-box-intersection
 */
vec3 rayAABBIntersection(vec3 rayPos, vec3 rayDir)
{
    float tmin, tmax, tymin, tymax, tzmin, tzmax;
    vec3 invDir = 1.0 / rayDir;
    vec3 bounds[2] = { vec3(sceneLf, 0.0, sceneDw), vec3(sceneRt, particleHighest, sceneUp) };
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

    // if tmin is negative, it intersected behind the ray
    return tmin > 0.0 ? rayPos + rayDir * tmin : inf;
}

bool isInsideBoundingBox(vec3 pos)
{
    float tol = 0.01;
    return pos.x > sceneLf && pos.x < sceneRt && 
           pos.z > sceneDw && pos.z < sceneUp && 
           pos.y > 0.0 && pos.y < particleHighest;
}

// This one has tolerance on whether it's inside the box or not
// Needed because of floating point errors in rayAABB intersection
bool isInsideBoundingBoxTol(vec3 pos)
{
    float tol = 0.01;
    return pos.x > sceneLf - tol && pos.x < sceneRt + tol && 
           pos.z > sceneDw - tol && pos.z < sceneUp + tol && 
           pos.y > 0.0 - tol && pos.y < particleHighest + tol;
}


vec4 rayMarch(vec3 rayPos, vec3 rayDir)
{
    float inv_bbWidth  = -1 / (sceneLf - sceneRt);
    float inv_bbHeight = -1 / (sceneDw - sceneUp);

    // Calculate maximum depth acceptable until we hit a scene object
    float maxDepth = texture(texRenderZ, uv).r;
    // Convert Depth Buffer values to a linear format
    maxDepth = maxDepth * 2.0 - 1.0;
    maxDepth = (2.0 * zNear * zFar) / (zFar + zNear - maxDepth * (zFar - zNear));
    maxDepth = length(rayDir * maxDepth);

    for (int i = 0; i < marchingMax; i++)
    {
        //TODO calculate step of ray based on texel size and ray direction
        vec3  currentStep = rayDir * i * marchingStep;
        float currentLength = length(currentStep);
        //if (currentLength >= maxDepth)
        //    return vec4(0.0);

        vec3 current = rayPos + currentStep;
        if (!isInsideBoundingBoxTol(current)) 
            return vec4(0.0);
        
        // Normalize current position within scene bounding box to [0, 1]
        vec2 texUVs = vec2((current.x - sceneLf) * inv_bbWidth,
                           (current.z - sceneDw) * inv_bbHeight);

        float h = texture(texVolume, texUVs).r;// * sceneHt;
        float z = (1 - texture(heightMap, vec2(-texUVs.x, texUVs.y)).r) * sceneHt;
        if (current.y < h && current.y > z) // TODO will have to use new depth buffer
        {
            // Calculate shading based on crossing directions to adjacent points to get the normal
            float texel_step = 1.0/1024.0; // replace for texture sizes instead of hardcoded values
            float world_step = texel_step * (sceneLf - sceneRt);
            // Convert [0, 1] height to [0, scene height]
            float h_up = texture(texVolume, max(texUVs + vec2(0, texel_step), vec2(0))).r;// * sceneHt;
            float h_dw = texture(texVolume, max(texUVs - vec2(0, texel_step), vec2(0))).r;// * sceneHt;
            float h_rt = texture(texVolume, max(texUVs + vec2(texel_step, 0), vec2(0))).r;// * sceneHt;
            float h_lf = texture(texVolume, max(texUVs - vec2(texel_step, 0), vec2(0))).r;// * sceneHt;

            vec3 up = normalize(vec3( world_step, h_up - h, 0));
            vec3 dw = normalize(vec3(-world_step, h_dw - h, 0));
            vec3 rt = normalize(vec3(0, h_rt - h,  world_step));
            vec3 lf = normalize(vec3(0, h_lf - h, -world_step));

            vec3 normal = normalize(cross(up, lf) + cross(lf, dw) + cross(dw, rt) + cross(rt, up));
            vec3 ldir   = normalize(-lightDir);
            vec3 particleColor = vec3(1.0);
            vec3 ambient = particleColor * 0.2; // ambient
            vec3 diffuse = particleColor * 0.8; // diffuse

            return vec4(ambient + diffuse * max(0, dot(normal, ldir)), volumeAlpha);
            //return vec4(normal, 1);
        }
    }
    return vec4(0.0);
}

void main()
{
    color = texture(texRender, uv);
    vec3 rayPos = position.xyz;
    const vec3 rayDir = rayDir();

    if (!isInsideBoundingBox(rayPos))
    {
        rayPos = rayAABBIntersection(rayPos, rayDir);
    }

    vec4 particleColor = vec4(0.0);
    if (rayPos != inf)
    {
        particleColor = rayMarch(rayPos, rayDir);
        //particleColor = vec4(0, 0.7, 0, 0.5);
    }

    color = mix(color, particleColor, particleColor.a);
    
    /*
    float depth = texture(texRenderZ, uv).r;
    // have to linearize depth maybe
    depth = depth * 2.0 - 1.0;
    depth = (2.0 * zNear * zFar) / (zFar + zNear - depth * (zFar - zNear));
    vec3 worldPos = position.xyz + rayDir * depth;
    color = mix(color, vec4(worldPos, 1), 1);
    //color = vec4(depth / zFar - zNear);
    */
}