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
uniform sampler2D DepthTex;    
uniform sampler2D heightMap1;    // World height map
uniform sampler2D heightMap2;
uniform sampler2D heightMap3;
uniform sampler2D heightMap4;
uniform sampler2D texVolume1;    // Particles heights
uniform sampler2D texVolume2;
uniform sampler2D texVolume3;
uniform sampler2D texVolume4;
uniform float height1;
uniform float height2;
uniform float height3;
const   float particleHighest = 10;

uniform vec3 lightDir;
uniform mat4 m_pv;
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
uniform vec3  sceneCt;

uniform sampler2D texRenderZ;
uniform float zNear;
uniform float zFar;
uniform float derivWeight;
uniform vec2  windowSize;

uniform float normalOffset;
uniform float particleAlpha;
uniform vec3  particleColor;
uniform float marchingStep;
uniform int   marchingMax;

uniform float offsetX;
uniform float offsetY;

const vec3 inf = vec3(1e20, 1e20, 1e20);

in vec2 uv;

out vec4 color;
out float gl_FragDepth ;

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
    vec3 bounds[2] = { vec3(sceneCt.x + sceneLf, 0.0, sceneCt.z + sceneDw), 
                       vec3(sceneCt.x + sceneRt, particleHighest, sceneCt.z + sceneUp) };
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
    return pos.x > sceneCt.x + sceneLf && pos.x < sceneCt.x + sceneRt && 
           pos.z > sceneCt.z + sceneDw && pos.z < sceneCt.z + sceneUp && 
           pos.y > 0.0 && pos.y < particleHighest;
}

// This one has tolerance on whether it's inside the box or not
// Needed because of floating point errors in rayAABB intersection
bool isInsideBoundingBoxTol(vec3 pos)
{
    float tol = 0.01;
    return pos.x > sceneCt.x + sceneLf - tol && pos.x < sceneCt.x + sceneRt + tol && 
           pos.z > sceneCt.z + sceneDw - tol && pos.z < sceneCt.z + sceneUp + tol && 
           pos.y > 0.0 - tol && pos.y < particleHighest + tol;
}

// Descending order in heights for textures
vec4 textureHeight(float height, vec2 uvs)
{
    if (height > height1)
        return texture(heightMap1, uvs);
    else if (height > height2)
        return texture(heightMap2, uvs);
    else if (height > height3)
        return texture(heightMap3, uvs);
    else
        return texture(heightMap4, uvs);
}

vec4 textureVolume(float height, vec2 uvs)
{
    if (height > height1)
        return texture(texVolume1, uvs);
    else if (height > height2)
        return texture(texVolume2, uvs);
    else if (height > height3)
        return texture(texVolume3, uvs);
    else
        return texture(texVolume4, uvs);
}

vec4 rayMarch(vec3 rayPos, vec3 rayDir)
{
    float inv_bbWidth  = -1 / (sceneLf - sceneRt);
    float inv_bbHeight = -1 / (sceneDw - sceneUp);
    float texel_step = 1.0/1024.0; // replace for texture sizes instead of hardcoded values
    float world_step = texel_step * (sceneLf - sceneRt);

    // Calculate maximum depth acceptable until we hit a scene object
    float maxDepth = texture(DepthTex, uv).x;

    float lastH = 0;
    float lastZ = 0;
    for (int i = 0; i < marchingMax; i++)
    {
        //TODO calculate step of ray based on texel size and ray direction
        vec3 currentStep = rayDir * i * marchingStep;
        vec3 current = rayPos + currentStep;
        float currentLength = length(current - position.xyz);

        if (currentLength > maxDepth )
           return vec4(0);            

        if (!isInsideBoundingBoxTol(current)) 
            return vec4(0.0);
        
        // Normalize current position within scene bounding box to [0, 1]
        const float tol = 0.001;
        vec2 texUVs = clamp(vec2((current.x - sceneLf) * inv_bbWidth,
                           (current.z - sceneDw) * inv_bbHeight), 0 + tol, 1 - tol);

        vec2 offset = vec2(offsetX, offsetY);
    
      
        //TODO
        //vec4 hvec = texture(texVolume, texUVs + offset);
        //float h = hvec.r;// * sceneHt;
        //float z = hvec.g;//(1 - texture(heightMap, vec2(-texUVs.x, texUVs.y)).r) * sceneHt;

        
        float h = textureVolume(current.y, texUVs + offset).r;// * sceneHt;
        float z = (1 - textureHeight(current.y, vec2(-texUVs.x, texUVs.y)).r) * sceneHt;

        // If distances are too different, then we have a vertical disconnection between particles
        if (abs(lastH - h + lastZ - z) > 0.05)
        {
            lastH = h;
            lastZ = z;
            continue;
        }

        if (current.y < h + z && current.y > z) // TODO will have to use new depth buffer
        {
            // Calculate shading based on crossing directions to adjacent points to get the normal
            // Get uvs from 4 directions away
            vec2 uv_up = clamp(texUVs + vec2(0, texel_step), vec2(0), vec2(1));
            vec2 uv_dw = clamp(texUVs - vec2(0, texel_step), vec2(0), vec2(1));
            vec2 uv_rt = clamp(texUVs + vec2(texel_step, 0), vec2(0), vec2(1));
            vec2 uv_lf = clamp(texUVs - vec2(texel_step, 0), vec2(0), vec2(1));

            // Get heights from particles
            float h_up = textureVolume(current.y, uv_up + offset).r;
            float h_dw = textureVolume(current.y, uv_dw + offset).r;
            float h_rt = textureVolume(current.y, uv_rt + offset).r;
            float h_lf = textureVolume(current.y, uv_lf + offset).r;

            // Get heights from the scene

            //TODO
            //float z_up = texture(texVolume, uv_up + offset).g;// (1 - texture((heightMap), vec2(-uv_up.x, uv_up.y)).r) * sceneHt;
            //float z_dw = texture(texVolume, uv_dw + offset).g;// (1 - texture((heightMap), vec2(-uv_dw.x, uv_dw.y)).r) * sceneHt;
            //float z_rt = texture(texVolume, uv_rt + offset).g;// (1 - texture((heightMap), vec2(-uv_rt.x, uv_rt.y)).r) * sceneHt;
            //float z_lf = texture(texVolume, uv_lf + offset).g;// (1 - texture((heightMap), vec2(-uv_lf.x, uv_lf.y)).r) * sceneHt;

            float z_up = (1 - textureHeight(current.y, vec2(-uv_up.x, uv_up.y)).r) * sceneHt;
            float z_dw = (1 - textureHeight(current.y, vec2(-uv_dw.x, uv_dw.y)).r) * sceneHt;
            float z_rt = (1 - textureHeight(current.y, vec2(-uv_rt.x, uv_rt.y)).r) * sceneHt;
            float z_lf = (1 - textureHeight(current.y, vec2(-uv_lf.x, uv_lf.y)).r) * sceneHt;

            
            // Calculate directions with slopes
            vec3 up = normalize(vec3( world_step, (h_up + z_up) - (h + z), 0));
            vec3 dw = normalize(vec3(-world_step, (h_dw + z_dw) - (h + z), 0));
            vec3 rt = normalize(vec3(0, (h_rt + z_rt)- (h + z),  world_step));
            vec3 lf = normalize(vec3(0, (h_lf + z_lf)- (h + z), -world_step));

            // Cross all directions to get a reasonable normal for shading the current pixel
            vec3 normal = normalize(cross(up, lf) + cross(lf, dw) + cross(dw, rt) + cross(rt, up));
            vec3 ldir   = normalize(-lightDir);
            vec3 ambient = particleColor * 0.2; // ambient
            vec3 diffuse = particleColor * 0.8; // diffuse

            return vec4(ambient + diffuse * max(0, dot(normal, ldir)), particleAlpha);
            //return vec4(normal, 1);
        }
        
        lastH = h;
        lastZ = z;
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
    vec4 levelColor = vec4(0.0);

    if (rayPos != inf)
    {
        if (rayPos.y > height1)
            levelColor = vec4(1, 0, 0, 0.2);
        else if (rayPos.y > height2)
            levelColor = vec4(1, 1, 0, 0.2);
        else if (rayPos.y > height3)
            levelColor = vec4(0, 1, 0, 0.2);
        else
            levelColor = vec4(0, 0, 1, 0.2);

        particleColor = rayMarch(rayPos, rayDir);
        //particleColor = vec4(0, 0.8, 0, 0.75);
    }

    color = mix(color, particleColor, particleColor.a);
    color = mix(color, levelColor, levelColor.a);
    
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