#version 330
  
layout(location = 0) in  vec4 vPosition; 
layout(location = 1) in  vec4 vColor; 

uniform float glPointSize;

uniform mat4 projMatrix;
uniform mat4 viewMatrix;

out vec4 color;

void main() {
	color = vColor;

	gl_Position = projMatrix * viewMatrix * vPosition;

	//gl_PointSize = glPointSize;
	gl_PointSize = glPointSize * (1.0 - gl_Position.z/gl_Position.w);
}

