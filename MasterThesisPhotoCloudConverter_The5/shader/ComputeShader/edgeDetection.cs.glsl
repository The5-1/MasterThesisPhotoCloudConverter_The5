#version 430
#define RED vec4(1.0, 0.0, 0.0, 1.0)
#define gid gl_GlobalInvocationID.xy				// = gl_WorkGroupID * gl_WorkGroupSize + gl_LocalInvocationID. 

layout(local_size_x = 32, local_size_y = 32) in;

layout(binding = 1, rgba32f) uniform image2D outputValue;

uniform int type;
uniform sampler2D inputValue;
uniform ivec2 res;

//|----||----||----|
//|-00-||-01-||-02-|
//------------------
//|----||----||----|
//|-10-||-11-||-12-|
//------------------
//|----||----||----|
//|-20-||-21-||-22-|
//------------------
void main() {
	//Texture-Coordinates
	vec2 tc00 = vec2(float(gid.x - 1) / res.x, float(gid.y - 1) / res.y);
	vec2 tc01 = vec2(float(gid.x) / res.x, float(gid.y - 1) / res.y);
	vec2 tc02 = vec2(float(gid.x + 1) / res.x, float(gid.y - 1) / res.y);

	vec2 tc10 = vec2(float(gid.x - 1) / res.x, float(gid.y) / res.y);
	vec2 center = vec2(float(gid.x) / res.x, float(gid.y) / res.y);
	vec2 tc12 = vec2(float(gid.x + 1) / res.x, float(gid.y) / res.y);

	vec2 tc20 = vec2(float(gid.x - 1) / res.x, float(gid.y + 1) / res.y);
	vec2 tc21 = vec2(float(gid.x) / res.x, float(gid.y + 1) / res.y);
	vec2 tc22 = vec2(float(gid.x + 1) / res.x, float(gid.y + 1) / res.y);

	//Minimum DepthDifference
	float epsilon = 0.005;



	//Colors
	//First row
	if(type == 1){
		if(abs( texture2D(inputValue, tc00).a - texture2D(inputValue, center).a) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		if(abs( texture2D(inputValue, tc01).a - texture2D(inputValue, center).a) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		if(abs( texture2D(inputValue, tc02).a - texture2D(inputValue, center).a) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		//Second row
		if(abs( texture2D(inputValue, tc10).a - texture2D(inputValue, center).a) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		if(abs( texture2D(inputValue, tc12).a - texture2D(inputValue, center).a) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		//Third row
		if(abs( texture2D(inputValue, tc20).a - texture2D(inputValue, center).a) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		if(abs( texture2D(inputValue, tc21).a - texture2D(inputValue, center).a) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		if(abs( texture2D(inputValue, tc22).a - texture2D(inputValue, center).a) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}
	}
//Colors
	//First row
	if(type == 0){
		if(abs( texture2D(inputValue, tc00).r - texture2D(inputValue, center).r) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		if(abs( texture2D(inputValue, tc01).r - texture2D(inputValue, center).r) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		if(abs( texture2D(inputValue, tc02).r - texture2D(inputValue, center).r) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		//Second row
		if(abs( texture2D(inputValue, tc10).r - texture2D(inputValue, center).r) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		if(abs( texture2D(inputValue, tc12).r - texture2D(inputValue, center).r) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		//Third row
		if(abs( texture2D(inputValue, tc20).r - texture2D(inputValue, center).r) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		if(abs( texture2D(inputValue, tc21).r - texture2D(inputValue, center).r) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}

		if(abs( texture2D(inputValue, tc22).r - texture2D(inputValue, center).r) > epsilon){
			imageStore(outputValue, ivec2(gid), RED);
			return;
		}
	}

	//Default
	vec4 color = texture2D(inputValue, center).rgba;
	vec4 col4 = vec4(color.rgb, 1.0);
	//vec4 col4 = vec4(color.a, color.a, color.a, 1.0);

	imageStore(outputValue, ivec2(gid), col4);
		
}

