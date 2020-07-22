#version 330

uniform sampler2D texVolume;
uniform sampler2D test;
uniform vec4 particleColor;
uniform float particleAlpha;
uniform vec3 lightDir;

in vec2 ouv;
in vec3 normal;
in float type;

out vec4 outColor;

void main()
{
    float t = type;
    vec3 color = particleColor.xyz;
    //If its not a particle, change color (slightly)
    if (type > 0)
    {
        color = color/t;
    }

    vec3 ldir   = normalize(-lightDir);
    vec3 ambient = color * 0.2; // ambient
    vec3 diffuse = color * 0.8; // diffuse

    outColor = vec4(ambient + diffuse * max(0, dot(normal, ldir)), particleAlpha);
}