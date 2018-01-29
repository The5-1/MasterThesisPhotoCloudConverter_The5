#version 430

#define RED vec3(1.0, 0.0, 0.0)
#define GREEN vec3(0.0, 1.0, 0.0)
#define BLUE vec3(0.0, 0.0, 1.0)


layout(location = 0)  out vec4 out0; // color 

uniform sampler2D renderTexture;
uniform sampler2D photoTexture;

in vec2 tc;

void main() 
{ 
	vec3 col;
	
	if(tc.x < 0.5){
		//col = RED;
		col = texture2D(renderTexture, tc + vec2(0.5, 0.0)).rgb;
	}
	else{
		col = texture2D(photoTexture, tc).rgb;
	}
	

	col = texture2D(renderTexture, tc).rgb + texture2D(photoTexture, tc).rgb;

	//col = texture2D(renderTexture, tc).rgb;
	//col = texture2D(photoTexture, tc).rgb;

	out0 = vec4(col, 1);
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