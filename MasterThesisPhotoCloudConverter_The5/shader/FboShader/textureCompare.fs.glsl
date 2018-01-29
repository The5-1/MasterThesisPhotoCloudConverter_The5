#version 330

#define RED vec3(1.0, 0.0, 0.0)
#define GREEN vec3(0.0, 1.0, 0.0)
#define BLUE vec3(0.0, 0.0, 1.0)

layout(location = 0)  out vec4 out0; // color 

uniform sampler2D texture1;
uniform sampler2D texture2;

in vec2 tc;

void main() 
{ 
	vec3 col;
	if(tc.x < 0.5){
		col = RED;
	}
	else{
		col = texture2D(texture2, tc).rgb;
	}
	out0 = vec4(col, 1);
}