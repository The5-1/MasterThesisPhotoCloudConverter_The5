/* GUIDES:
How to use glPoints: https://stackoverflow.com/questions/27098315/render-large-circular-points-in-modern-opengl
*/
#version 330
#define RED vec3(1.0, 0.0, 0.0)
#define GREEN vec3(0.0, 1.0, 0.0)
#define BLUE vec3(0.0, 0.0, 1.0)
#define PI 3.14159265359

layout(location = 0) out vec4 outColor;

in vec4 color;

void main(){ 
	
	vec2 circCoord0 = gl_PointCoord;

	vec2 circCoordNew = circCoord0*2.0-1.0;


	float alpha = min(1.0,(1.0-length(circCoord0*2.0-1.0))*4.0);
	///////////////
	//Draw Circle
	///////////////
	/*
	if(alpha <= 0.0)
	{
		discard;
	}
	outColor = vec4(color,1.0);
	*/
	
	///////////////
	//Draw rotatable diagonal
	///////////////
	/*
	float theta = 0.25 * PI; // + 0.5 * PI
	mat2 rotationCirc = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
	circCoordNew = rotationCirc * circCoordNew;
	if(circCoordNew.x - circCoordNew.y > 0){
		outColor = vec4(BLUE,1.0);
	}
	else{
		outColor = color;
	}
	*/
	
	///////////////
	//Does alpha channel work?
	///////////////
	/*
	if(color.a < 0){
		outColor = vec4(BLUE,1.0);
	}
	else{
		outColor = color;
	}
	*/

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////
	//Horizontal / Vertical diagonal
	///////////////
	/*
	if(color.a >= 0.0){
		float theta = 0.25 * PI + color.a;
		mat2 rotationCirc = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
		circCoordNew = rotationCirc * circCoordNew;

		if(circCoordNew.x - circCoordNew.y > 0){
			outColor = vec4(BLUE,1.0);
		}
		else{
			outColor = color;
		}
	}
	else{
		outColor = color;
	}
	*/

	///////////////
	//Color Output
	///////////////
	outColor = color;
}
