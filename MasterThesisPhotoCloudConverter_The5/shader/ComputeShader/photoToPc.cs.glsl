#version 430

#define PI 3.141592653589793

struct posColor {
	vec4 position;
	vec4 color;
};

layout(local_size_x = 128, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 4) buffer Pos
{
    posColor PosCol[];
};

uniform sampler2D tex;

uniform int width;
uniform int height;

uniform float tc_x;
uniform float tc_y;

uniform int imageType;

void main() {
	uint gid = gl_GlobalInvocationID.x;

	//Position
	vec3 pos = PosCol[ gl_GlobalInvocationID.x ].position.xyz;
	vec3 col = PosCol[ gl_GlobalInvocationID.x ].color.xyz;
	
	float r = length(pos);
	float lon = atan(pos.z, pos.x);
	float lat = acos(pos.y / r);
	const vec2 radsToUnit = vec2(1.0 / (PI * 2.0), 1.0 / PI);
	vec2 sphereCoords = vec2(lon, lat) * radsToUnit;

	sphereCoords = vec2(fract(sphereCoords.x), sphereCoords.y);
	//sphereCoords = vec2(sphereCoords.x + tc_x, sphereCoords.y + tc_y);

	vec2 coordinates;
	if(imageType == 0){
		coordinates = vec2(fract((1.0-sphereCoords.x) + tc_x), sphereCoords.y + tc_y);
	}
	else if(imageType == 1){
		coordinates = vec2(fract((1.0-sphereCoords.x)), sphereCoords.y);
		coordinates.x = fract(1.0 - coordinates.x);
		coordinates.y = fract(1.0 - coordinates.y);
	}
	else if(imageType == 2){
		coordinates = sphereCoords;
	}

	//vec3 colTexture = texture2D(tex, sphereCoords).rgb;
	
	//vec4 colTexture = texture2D(tex, coordinates).rgba;
	vec4 colTexture = vec4(texture2D(tex, coordinates).rgb, 0.5);
	PosCol[ gl_GlobalInvocationID.x ].color = colTexture;
	//PosCol[ gl_GlobalInvocationID.x ].color = vec4(1.0, 0.0, 0.0, 1.0);
}


/*
#version 430

#define PI 3.141592653589793

struct posColor {
	vec4 position;
	vec4 color;
};

layout(local_size_x = 128, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba32f) uniform image2D texture;

layout(std430, binding = 4) buffer Pos
{
    posColor PosCol[];
};

uniform int width;
uniform int height;

void main() {
	uint gid = gl_GlobalInvocationID.x;

	//Position
	vec3 pos = PosCol[ gl_GlobalInvocationID.x ].position.xyz;
	vec3 col = PosCol[ gl_GlobalInvocationID.x ].color.xyz;
	
	float r = length(pos);
	float lon = atan(pos.z, pos.x);
	float lat = acos(pos.y / r);
	const vec2 radsToUnit = vec2(1.0 / (PI * 2.0), 1.0 / PI);
	vec2 sphereCoords = vec2(lon, lat) * radsToUnit;
	sphereCoords = vec2(fract(sphereCoords.x), 1.0-sphereCoords.y);
	ivec2 tc = ivec2( int(sphereCoords.x * width), int(sphereCoords.y * height));

	
	//pos = pos - vec3(0.0, 0.1, 0.0);
	//PosCol[ gl_GlobalInvocationID.x ].position.xyzw = vec4(pos, 1.0);
	

	vec3 colTexture = imageLoad(texture, ivec2(gid, gid)).rgb;

	PosCol[ gl_GlobalInvocationID.x ].color = vec4(colTexture, 1.0);

	vec3 withoutRed = vec3(0.0, col.y, col.z);
	
	imageStore(texture, tc, vec4(withoutRed, 1.0));
}
*/