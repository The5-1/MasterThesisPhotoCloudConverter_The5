#version 330

layout(location = 0) in  vec4 vPosition; 
layout(location = 1) in  vec4 vColor; 

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;

uniform vec4 clearColor;

uniform vec3 viewPoint;

uniform int renderPass;

uniform vec3 cameraPos;
uniform float glPointSize;

out float kantenorientierung;
out vec4 viewPosition;
out vec3 coordinateGridPos;
out vec3 color;
out vec4 positionFBO;


//#define BACKFACE_CULLING 0

void main() {
	//Color
	color = vColor.rgb;
	kantenorientierung = vColor.a;
	//Position	
	viewPosition = viewMatrix * modelMatrix * vec4(vPosition.xyz, 1.0);
	positionFBO = modelMatrix * vec4(vPosition.xyz, 1.0);
	gl_Position = projMatrix * viewPosition;

	//Size (Constant size, selfmade)
	gl_PointSize = glPointSize * (1.0 - gl_Position.z / gl_Position.w);

	//High-Quality Point-Based Rendering on Modern GPUs (Seite 3)
	//float distanceCam = length( - viewPosition.xyz ); //Does not need to be divided by w! w = 1 (Viewtrafo, is only rotation/Translation)
	//gl_PointSize = glPointSize * (1.0 / distanceCam) * (768.0 / 2.0);
}

