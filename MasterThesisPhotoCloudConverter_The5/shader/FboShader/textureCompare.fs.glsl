#version 430

#define RED vec3(1.0, 0.0, 0.0)
#define GREEN vec3(0.0, 1.0, 0.0)
#define BLUE vec3(0.0, 0.0, 1.0)
#define PINK vec3(1.0, 0.0, 1.0)

layout(location = 0)  out vec4 out0; // color 

uniform sampler2D renderTexture;
uniform sampler2D photoTexture;

uniform float tc_x;
uniform float tc_y;

in vec2 tc;

void main() 
{ 
	vec3 col = vec3(1.0,1.0,1.0);

	/************
	Split screen
	************/
	/*
	if(tc.x < 0.5){
		col = texture2D(renderTexture, tc + vec2(0.5, 0.0)).rgb;
	}
	else{
		col = texture2D(photoTexture, tc).rgb;
	}
	*/

	/************
	Overwrite with real color
	************/
	vec3 diff = abs( texture2D(renderTexture, vec2(fract((1.0-tc.x) + tc_x),1.0-tc.y + tc_y)).rgb - texture2D(photoTexture, vec2(tc.x,1.0-tc.y)).rgb );

	/************
	Overwrite with red
	************/
	vec4 rgba = texture2D(renderTexture, vec2(fract((1.0-tc.x) + tc_x),1.0-tc.y +tc_y)).rgba;
	if(rgba.a == 0.0){
		col = texture2D(photoTexture, vec2(tc.x,1.0-tc.y)).rgb;
	}
	else{
		col = PINK;
	}

	out0 = vec4(col, 1.0);
}


/*
layout(location = 0)  out vec4 out0; // color

layout(binding = 5, rgba32f) uniform image2D photoTexture;

uniform sampler2D renderTexture;

in vec2 tc;

void main() 
{ 
	vec3 col;
	if(tc.x < 0.5){
		//col = RED;
		col = imageLoad(photoTexture, ivec2(100, 100)).rgb;
	}
	else{
		col = texture2D(renderTexture, tc).rgb;
	}
	out0 = vec4(col, 1);
}
*/