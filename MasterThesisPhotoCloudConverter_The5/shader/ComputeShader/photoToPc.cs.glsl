#version 430

#define PI 3.141592653589793

struct posColor {
	vec4 position;
	vec4 color;
};

layout(local_size_x = 128, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba32f) uniform image2D outputTexture;

layout(std430, binding = 4) buffer Pos
{
    posColor PosCol[];
};

uniform int width;
uniform int height;

void main() {
	//Position
	vec3 pos = PosCol[ gl_GlobalInvocationID.x ].position.xyz;
	vec3 col = PosCol[ gl_GlobalInvocationID.x ].color.xyz;
	
	float r = length(pos);
	float lon = atan(pos.z, pos.x);
	float lat = acos(pos.y / r);
	const vec2 radsToUnit = vec2(1.0 / (PI * 2.0), 1.0 / PI);
	vec2 sphereCoords = vec2(lon, lat) * radsToUnit;
	sphereCoords = vec2(fract(sphereCoords.x), 1.0-sphereCoords.y);
	
	/*
	pos = pos - vec3(0.0, 0.1, 0.0);
	PosCol[ gl_GlobalInvocationID.x ].position.xyzw = vec4(pos, 1.0);
	*/

	PosCol[ gl_GlobalInvocationID.x ].color = vec4(1.0, 0.0, 0.0, 1.0);

	vec3 withoutRed = vec3(0.0, col.y, col.z);
	imageStore(outputTexture, ivec2( int(sphereCoords.x * width), int(sphereCoords.y * height) ), vec4(withoutRed, 1.0));
}