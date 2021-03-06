
#version 330
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outPos;
layout(location = 3) out vec4 outDepth;

uniform float depthEpsilonOffset;
uniform sampler1D filter_kernel;
uniform sampler2D texDepth;

uniform float width;
uniform float height;

in vec4 viewNormal;
in vec4 viewPosition;
in vec3 color;
in vec4 positionFBO;
in float kantenorientierung;
in vec3 coordinateGridPos;

#define PI 3.14159265359
#define AFFINE_PROJECTED 0
//#define GAUSS_ALPHA 0


void main(){ 
	//outNormal = vec4(0.5 * viewNormal.xyz + vec3(0.5), 1.0);
	//outPos = vec4(positionFBO.xyz/positionFBO.w, 1.0);
	//outNormal = vec4( vec3(texture(texDepth, 0.5 * gl_FragCoord.xy +0.5).r) , 1.0);
	//outPos = vec4( vec3(texture(texDepth, gl_FragCoord.xy).r), 1.0);
	ivec2 fDepthOld_res = textureSize(texDepth,0);
	vec2 texelSize = 1.0/vec2(fDepthOld_res);

	vec2 fScreenUV = vec2(gl_FragCoord.x, gl_FragCoord.y)*texelSize;

	float fDepthOld = texture(texDepth,fScreenUV).x;


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
		else{

		}

		//Update depth
		//float newDepth = gl_FragCoord.z + (pow(currentRadius, 2)) * gl_FragCoord.w + depthEpsilonOffset;
		float newDepth = gl_FragCoord.z + (pow(currentRadius, 2)) * gl_FragCoord.w;
		float depthBuffer =texture(texDepth, vec2(gl_FragCoord.x/width, gl_FragCoord.y/height)).r;
		float filter = texture(filter_kernel, currentRadius).r;
		
		if(newDepth > depthBuffer){
			discard;
		}

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
	
		
		outColor.r =  10.0 * (depthBuffer - newDepth) ;
		outColor.g =  10.0 * (depthBuffer - newDepth);
		outColor.b =  10.0 * (depthBuffer - newDepth);
		//outColor.w = (depthBuffer - newDepth) * 10.0;

		//float depth_new = gl_FragCoord.z+ (pow(currentRadius, 2)) * gl_FragCoord.w;



		float depth_new = gl_FragCoord.z+ (pow(currentRadius, 2)) * gl_FragCoord.w;

		float depth_old = texture(texDepth, vec2(gl_FragCoord.x/width, gl_FragCoord.y/height)).r; //Look up previous -epsillon depth by using the pixel cooridnates directly for lookup

		if(depth_new > depth_old){
			discard;
		}


		//weight is the distance between old and new depth in proportion to epsillon so [0,1]
		float weight = (depth_old - depth_new)/(depthEpsilonOffset); //when the distance is epsillon, this should be 1.0, when it is smaller, this should be <1.0
		
		//The colors are blended ADDITIVELY, Buffer is 32bit --> numbers > 1 allowed!!!
		outColor = vec4(color*weight, weight); 

		outDepth = vec4(vec3(depthBuffer), 1.0);;
		outNormal = vec4(vec3(depthBuffer), 1.0);
		outPos= vec4(vec3(newDepth), 1.0);

		//gl_FragDepth = newDepth; //we manually depth test and discard! //Depth Test is disabled for this renderpass

/*
		outColor = vec4(0.0);
		outColor.rg = fScreenUV;
		outColor = vec4(fDepthOld);
		outColor.a = 1.0;
		*/
	#endif
}
