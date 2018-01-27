#version 430

struct posColor {
	vec4 position;
	vec4 color;
};

layout(local_size_x = 128, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 4) buffer Pos
{
    posColor PosCol[];
};

void main() {
	//Position
	vec3 pos = PosCol[ gl_GlobalInvocationID.x ].position.xyz - vec3(0.0, 0.1, 0.0);
	PosCol[ gl_GlobalInvocationID.x ].position.xyzw = vec4(pos, 1.0);
	
	//Color
	PosCol[ gl_GlobalInvocationID.x ].color.xyzw = vec4( mod(pos.x,1.0), mod(pos.y,1.0), mod(pos.z,1.0), 1.0);
}


/*
//It also works with vec3 as layout (WHY!?!?!)
#version 430

layout(local_size_x = 128, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 4) buffer Pos
{
    vec3 Position[];
};

void main() {
	
	vec3 pos = Position[ gl_GlobalInvocationID.x ].xyz - vec3(0.0, 0.1, 0.0);

	Position[ gl_GlobalInvocationID.x ].xyz = pos;
}
*/








//#extension GL_ARB_compute_shader: enable
//#extension GL_ARB_shader_storage_buffer_object: enable;

//#define gid gl_GlobalInvocationID.x				// = gl_WorkGroupID * gl_WorkGroupSize + gl_LocalInvocationID. 

/*
layout(local_size_x = 32, local_size_y = 32) in;

layout(binding=0, rgba32f) uniform image2D inputValue;
layout(binding=1, rgba32f) uniform image2D outputValue;
	
uniform ivec2 res;
uniform int type;
*/

/* ************************************************************************
void main() {

		vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

		bool alive; 
		if(imageLoad(inputValue, ivec2(gid)).r == 1.0){
			alive = true;
		}
		else{
			alive = false;
		}

		int neighbours = 0;
		
		if(imageLoad(inputValue, ivec2(gid + vec2(0, 1))).r == 1.0){
			neighbours++;
		}

		if(imageLoad(inputValue, ivec2(gid + vec2(0, -1))).r == 1.0){
			neighbours++;
		}

		if(imageLoad(inputValue, ivec2(gid + vec2(1, 0))).r == 1.0){
			neighbours++;
		}
		if(imageLoad(inputValue, ivec2(gid + vec2(-1, 0))).r == 1.0){
			neighbours++;
		}

		if(imageLoad(inputValue, ivec2(gid + vec2(1, 1))).r == 1.0){
			neighbours++;
		}

		if(imageLoad(inputValue, ivec2(gid + vec2(1, -1))).r == 1.0){
			neighbours++;
		}

		if(imageLoad(inputValue, ivec2(gid + vec2(-1, -1))).r == 1.0){
			neighbours++;
		}

		if(imageLoad(inputValue, ivec2(gid + vec2(-1, 1))).r == 1.0){
			neighbours++;
		}
		
		///////////////////////////////////////////////////////////////
		// Interesting bugged Game of life
		///////////////////////////////////////////////////////////////
		if(type == 0){
			if(neighbours < 2){
				color = vec4(0.0, 0.0, 0.0, 1.0);
			}
			else if(neighbours == 2 || neighbours == 3){
				color = vec4(1.0, 0.0, 0.0, 1.0);
			}
			else{
				color = vec4(0.0, 0.0, 0.0, 1.0);
			}
		}

		///////////////////////////////////////////////////////////////
		// Game of life
		///////////////////////////////////////////////////////////////
		if(type == 1){
			if(neighbours < 2){
				color = vec4(0.0, 0.0, 0.0, 1.0);
			}
			else if(!alive && neighbours == 3){
				color = vec4(1.0, 0.0, 0.0, 1.0);
			}
			else if(neighbours > 3){
				color = vec4(0.0, 0.0, 0.0, 1.0);
			}
			else if((alive && neighbours == 3) || (alive && neighbours == 2)){
				color = vec4(1.0, 0.0, 0.0, 1.0);
			}
			else{
				color = vec4(0.0, 0.0, 0.0, 1.0);
			}
		}

		imageStore(outputValue, ivec2(gid), color);
		
}
************************************************************************ */