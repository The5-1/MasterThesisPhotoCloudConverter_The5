
#version 330
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outPos;
layout(location = 3) out vec4 outDepth;

uniform float depthEpsilonOffset;
uniform sampler1D filter_kernel;
uniform sampler2D texDepth;

in vec4 viewNormal;
in vec4 viewPosition;
in vec3 color;
in vec4 positionFBO;
in float kantenorientierung;
in vec3 coordinateGridPos;

#define AFFINE_PROJECTED 0
#define GAUSS_ALPHA 0
#define PI 3.14159265

void main(){ 

	/* Idea: we write a parabolic depth
	**
	*/

	//outNormal = vec4(0.5 * viewNormal.xyz + vec3(0.5), 1.0);
	//outPos = vec4(positionFBO.xyz/positionFBO.w, 1.0);
	//outNormal = vec4( vec3(texture(texDepth, 0.5 * gl_FragCoord.xy +0.5).r) , 1.0);
	//outPos = vec4( vec3(texture(texDepth, gl_FragCoord.xy).r), 1.0);

	#ifdef AFFINE_PROJECTED
		vec2 circCoord = 2.0 * gl_PointCoord - vec2(1.0, 1.0); //Maps to [-1, 1]

		float maxRadius = 1.0;
		float currentRadius = length( vec2(circCoord.x, circCoord.y) );

		//float previous_buffered_epsillon_depth = 1.0; //TODO here we need a sampler to get the previous depth with epsillon offset!
		//float new_fragment_depth = gl_FragCoord.z;
		//float delta_depth_for_blending = max(0.0,new_fragment_depth-previous_buffered_epsillon_depth);

		if(currentRadius > maxRadius)
		{
			discard;
		}
		#if 1
		if(kantenorientierung >= 0.0){
			//Angle
			float alpha = 100.0 * fract(kantenorientierung); 
			float theta = 0.25 * PI + alpha;
			mat2 rotationCirc = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
			vec2 circCoordNew = rotationCirc * (gl_PointCoord*2.0-1.0);

			//Translation
			float translation = (kantenorientierung - fract(kantenorientierung))/10.0;

			if(circCoordNew.x - circCoordNew.y  - translation> 0 && alpha > 0){
			}
			else{
				//outColor = color;
				discard;
			}
			
		}
		#endif

		//Update depth
		float newDepth = gl_FragCoord.z + (pow(currentRadius, 2)) * gl_FragCoord.w + depthEpsilonOffset;


		/* BRUTE FORCE: 
		** WARNING: BROKEN!
		** we completely ditch the depth test here, so what we write to the colors is complete nonsense!
		** Original Idea: write new depth to
		*/
		outDepth = vec4(vec3(newDepth), 1.0);
		outColor = vec4(vec3(newDepth), 1.0);
		outNormal = vec4(vec3(newDepth), 1.0);
		outPos= vec4(vec3(newDepth), 1.0);


		gl_FragDepth = newDepth; 
	#endif
}
