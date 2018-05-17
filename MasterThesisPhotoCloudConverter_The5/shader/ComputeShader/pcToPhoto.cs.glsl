#version 430

#define PI 3.141592653589793
#define RED vec3(1.0, 0.0, 0.0)
#define GREEN vec3(0.0, 1.0, 0.0)
#define BLUE vec3(0.0, 0.0, 1.0)

struct posColor {
	vec4 position;
	vec4 color;
};

layout(local_size_x = 128, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba32f) uniform image2D outputTexture;
//layout(binding = 1, rgba32f) uniform image2D outputTextureLarge;

layout(std430, binding = 4) buffer Pos
{
    posColor PosCol[];
};

uniform int width;
uniform int height;
uniform int widthLarge;
uniform int heightLarge;

void main() {
	//Position
	vec3 pos = PosCol[ gl_GlobalInvocationID.x ].position.xyz;
	vec3 col = PosCol[ gl_GlobalInvocationID.x ].color.xyz;
	
	float r = length(pos);
	float lon = atan(pos.z, pos.x);
	float lat = acos(pos.y / r);
	const vec2 radsToUnit = vec2(1.0 / (PI * 2.0), 1.0 / PI);
	vec2 sphereCoords = vec2(lon, lat) * radsToUnit;

	//Rotated
	//sphereCoords = vec2(fract(sphereCoords.x), 1.0-sphereCoords.y);

	//Not Rotated
	sphereCoords = vec2(fract(sphereCoords.x), sphereCoords.y);

	

	float alphaDistance = r / 20.0;
	imageStore(outputTexture, ivec2( int(sphereCoords.x * width), int(sphereCoords.y * height) ), vec4(col, alphaDistance));
	//imageStore(outputTextureLarge, ivec2( int(sphereCoords.x * widthLarge), int(sphereCoords.y * heightLarge) ), vec4(col, alphaDistance));




	//Distance from camerapoint
	//vec4 alphaColor = vec4(r, r/20.0, r/50.0, r/100.0);
	//imageStore(outputTexture, ivec2( int(sphereCoords.x * width), int(sphereCoords.y * height) ), alphaColor);
}
