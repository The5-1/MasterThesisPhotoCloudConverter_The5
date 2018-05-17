#version 430

#define PI 3.141592653589793
//Vec3
#define RED vec3(1.0, 0.0, 0.0)
#define GREEN vec3(0.0, 1.0, 0.0)
#define BLUE vec3(0.0, 0.0, 1.0)
#define PINK vec3(1.0, 0.0784, 0.5764)
//Vec4
#define RED4 vec4(1.0, 0.0, 0.0, 1.0)
#define GREEN4 vec4(0.0, 1.0, 0.0, 1.0)
#define BLUE4 vec4(0.0, 0.0, 1.0, 1.0)
#define PINK4 vec4(1.0, 0.0784, 0.5764, 1.0)

struct posColor {
	vec4 position;
	vec4 color;
};

layout(local_size_x = 128, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 4) buffer Pos
{
    posColor PosCol[];
};

uniform sampler2D inputValue;
uniform sampler2D depthValue;


float rgb2luma(vec3 rgb){
    return sqrt(dot(rgb, vec3(0.299, 0.587, 0.114)));
}

bool isBlack(vec3 rgb){
	return rgb == vec3(0.0, 0.0, 0.0);
}


void main() {  
	///////////////////////
	// Color change
	///////////////////////
	float colorFactor = 0.85;

	float width = 4096.0;
	float height = 2048.0;
	uint gid = gl_GlobalInvocationID.x;

	///////////////////////
	// sphere Coordinates
	///////////////////////
	vec3 pos = PosCol[ gl_GlobalInvocationID.x ].position.xyz;
	vec3 col = PosCol[ gl_GlobalInvocationID.x ].color.xyz;
	
	float r = length(pos);
	float lon = atan(pos.z, pos.x);
	float lat = acos(pos.y / r);
	const vec2 radsToUnit = vec2(1.0 / (PI * 2.0), 1.0 / PI);
	vec2 sphereCoords = vec2(lon, lat) * radsToUnit;

	///////////////////////
	// Texture Coordinates /Colors
	///////////////////////
	//Texture-Coordinates
	//|----||----||----|
	//|-00-||-01-||-02-|
	//------------------
	//|----||----||----|
	//|-10-||-11-||-12-|
	//------------------
	//|----||----||----|
	//|-20-||-21-||-22-|
	//------------------
	vec2 center = vec2(fract(sphereCoords.x), 1.0 - sphereCoords.y);

	vec2 tc00 = vec2(fract(sphereCoords.x) - 1.0/width, 1.0 - sphereCoords.y + 1.0/height);
	vec2 tc01 = vec2(fract(sphereCoords.x), 1.0 - sphereCoords.y + 1.0/height);
	vec2 tc02 = vec2(fract(sphereCoords.x) + 1.0/width, 1.0 - sphereCoords.y + 1.0/height);

	vec2 tc10 = vec2(fract(sphereCoords.x) - 1.0/width, 1.0 - sphereCoords.y);
	vec2 tc12 = vec2(fract(sphereCoords.x) + 1.0/width, 1.0 - sphereCoords.y);

	vec2 tc20 = vec2(fract(sphereCoords.x) - 1.0/width, 1.0 - sphereCoords.y - 1.0/height);
	vec2 tc21 = vec2(fract(sphereCoords.x), 1.0 - sphereCoords.y - 1.0/height);
	vec2 tc22 = vec2(fract(sphereCoords.x) + 1.0/width, 1.0 - sphereCoords.y - 1.0/height);

	//Color
	vec4 tc00_Col = texture2D(inputValue, tc00).rgba;
	vec4 tc01_Col = texture2D(inputValue, tc01).rgba;
	vec4 tc02_Col = texture2D(inputValue, tc02).rgba;

	vec4 tc10_Col = texture2D(inputValue, tc10).rgba;
	vec4 center_Col =  texture2D(inputValue, center).rgba;
	vec4 tc12_Col = texture2D(inputValue, tc12).rgba;

	vec4 tc20_Col = texture2D(inputValue, tc20).rgba;
	vec4 tc21_Col = texture2D(inputValue, tc21).rgba;
	vec4 tc22_Col = texture2D(inputValue, tc22).rgba;

	

	///////////////////////
	// Edge Detection-Thresholds
	///////////////////////
	float EDGE_THRESHOLD_MIN = 0.0312;
	float EDGE_THRESHOLD_MAX = 0.125;

	///////////////////////
	// Depth detection
	///////////////////////
	bool depthTestFailed = false;
	float epsilon = 0.05;

	if(abs( texture2D(depthValue, tc00).a - texture2D(depthValue, center).a) > epsilon){
		depthTestFailed = true;
	}
	if(abs( texture2D(depthValue, tc01).a - texture2D(depthValue, center).a) > epsilon){
		depthTestFailed = true;
	}
	if(abs( texture2D(depthValue, tc02).a - texture2D(depthValue, center).a) > epsilon){
		depthTestFailed = true;
	}

	if(abs( texture2D(depthValue, tc10).a - texture2D(depthValue, center).a) > epsilon){
		depthTestFailed = true;
	}
	if(abs( texture2D(depthValue, tc12).a - texture2D(depthValue, center).a) > epsilon){
		depthTestFailed = true;
	}

	if(abs( texture2D(depthValue, tc20).a - texture2D(depthValue, center).a) > epsilon){
		depthTestFailed = true;
	}
	if(abs( texture2D(depthValue, tc21).a - texture2D(depthValue, center).a) > epsilon){
		depthTestFailed = true;
	}
	if(abs( texture2D(depthValue, tc22).a - texture2D(depthValue, center).a) > epsilon){
		depthTestFailed = true;
	}
	///////////////////////
	// Luma
	///////////////////////
	float lumaCenter = rgb2luma(center_Col.rgb);
	float lumaDown = rgb2luma(tc21_Col.rgb);
	float lumaUp = rgb2luma(tc01_Col.rgb);
	float lumaLeft = rgb2luma(tc10_Col.rgb);
	float lumaRight = rgb2luma(tc12_Col.rgb);

	float lumaMin = min(lumaCenter,min(min(lumaDown,lumaUp),min(lumaLeft,lumaRight)));
	float lumaMax = max(lumaCenter,max(max(lumaDown,lumaUp),max(lumaLeft,lumaRight)));
	float lumaRange = lumaMax - lumaMin;


	///////////////////////
	// Detect Horizontal/Vertical/Diagonal
	///////////////////////
	if(!depthTestFailed){
		PosCol[ gl_GlobalInvocationID.x ].color = vec4(center_Col.rgb, -1.0);
		return;
	}


	if(lumaRange < max(EDGE_THRESHOLD_MIN, lumaMax*EDGE_THRESHOLD_MAX) && !depthTestFailed){
		PosCol[ gl_GlobalInvocationID.x ].color = center_Col;
	}
	else{
		// Query the 4 remaining corners lumas.
		float lumaDownLeft = rgb2luma(tc20_Col.rgb);
		float lumaUpRight = rgb2luma(tc02_Col.rgb);
		float lumaUpLeft = rgb2luma(tc00_Col.rgb);
		float lumaDownRight = rgb2luma(tc22_Col.rgb);

		// Combine the four edges lumas (using intermediary variables for future computations with the same values).
		float lumaDownUp = lumaDown + lumaUp;
		float lumaLeftRight = lumaLeft + lumaRight;

		// Same for corners
		float lumaLeftCorners = lumaDownLeft + lumaUpLeft;
		float lumaDownCorners = lumaDownLeft + lumaDownRight;
		float lumaRightCorners = lumaDownRight + lumaUpRight;
		float lumaUpCorners = lumaUpRight + lumaUpLeft;

		// Compute an estimation of the gradient along the horizontal and vertical axis.
		float edgeHorizontal =  abs(-2.0 * lumaLeft + lumaLeftCorners)  + abs(-2.0 * lumaCenter + lumaDownUp ) * 2.0    + abs(-2.0 * lumaRight + lumaRightCorners);
		float edgeVertical =    abs(-2.0 * lumaUp + lumaUpCorners)      + abs(-2.0 * lumaCenter + lumaLeftRight) * 2.0  + abs(-2.0 * lumaDown + lumaDownCorners);
		float diagonal1 = 3.0 * abs(-2.0 * lumaCenter + lumaUpRight + lumaDownLeft);
		float diagonal2 = 3.0 * abs(-2.0 * lumaCenter + lumaDownRight + lumaUpLeft);

		int type = 0;

		if( (edgeHorizontal >= edgeVertical) && (edgeHorizontal >= diagonal1) && (edgeHorizontal >= diagonal2)){
			type = 0;
		}
		else if( (edgeVertical >= edgeHorizontal) && (edgeVertical >= diagonal1) && (edgeVertical >= diagonal2)){
			type = 1;
		}
		else if( (diagonal1 >= edgeVertical) && (diagonal1 >= edgeHorizontal) && (diagonal1 >= diagonal2)){
			type = 2;
		}
		else{
			type = 3;
		}
			
		//|----||----||----|
		//|-00-||-01-||-02-|
		//------------------
		//|----||----||----|
		//|-10-||-11-||-12-|
		//------------------
		//|----||----||----|
		//|-20-||-21-||-22-|
		//------------------
		float translation = 0.0;
		// |\
		// |_\  with 0.875

		// |-/
		// |/  with 0.125

		//	a b c d e
		//	o 1 2 3 e
		//	n 4 5 6 f
		//  m 7 8 9 g
		//	l k j i h
		vec2 a = vec2(fract(sphereCoords.x) - 2.0/width, 1.0 - sphereCoords.y + 2.0/height);
		vec2 b = vec2(fract(sphereCoords.x) - 1.0/width, 1.0 - sphereCoords.y + 2.0/height);
		vec2 c = vec2(fract(sphereCoords.x) , 1.0 - sphereCoords.y + 2.0/height);
		vec2 d = vec2(fract(sphereCoords.x) + 1.0/width, 1.0 - sphereCoords.y + 2.0/height);
		vec2 e = vec2(fract(sphereCoords.x) + 2.0/width, 1.0 - sphereCoords.y + 2.0/height);

		vec2 n = vec2(fract(sphereCoords.x) - 2.0/width, 1.0 - sphereCoords.y);
		vec2 f =vec2(fract(sphereCoords.x) + 2.0/width, 1.0 - sphereCoords.y);

		vec2 n_left = vec2(fract(sphereCoords.x) - 3.0/width, 1.0 - sphereCoords.y);
		vec2 f_right =vec2(fract(sphereCoords.x) + 3.0/width, 1.0 - sphereCoords.y);

		vec2 m = vec2(fract(sphereCoords.x) - 2.0/width, 1.0 - sphereCoords.y - 1.0/height);
		vec2 g =vec2(fract(sphereCoords.x) + 2.0/width, 1.0 - sphereCoords.y - 1.0/height);


		vec2 l = vec2(fract(sphereCoords.x) - 2.0/width, 1.0 - sphereCoords.y - 2.0/height);
		vec2 k = vec2(fract(sphereCoords.x) - 1.0/width, 1.0 - sphereCoords.y - 2.0/height);
		vec2 j = vec2(fract(sphereCoords.x) , 1.0 - sphereCoords.y - 2.0/height);
		vec2 i = vec2(fract(sphereCoords.x) + 1.0/width, 1.0 - sphereCoords.y - 2.0/height);
		vec2 h = vec2(fract(sphereCoords.x) + 2.0/width, 1.0 - sphereCoords.y - 2.0/height);

	///////////////////////
	// Colorcode the Translations 
	///////////////////////
		#if 0
			if(type == 0){
				if(isBlack(texture2D(inputValue, tc10).rgb) || isBlack(texture2D(inputValue, tc12).rgb ) 
						|| isBlack(texture2D(inputValue, n).rgb) || isBlack(texture2D(inputValue, f).rgb)
						|| isBlack(texture2D(inputValue, tc20).rgb) || isBlack(texture2D(inputValue, tc21).rgb) || isBlack(texture2D(inputValue, tc22).rgb)
						//|| isBlack(texture2D(inputValue, m).rgb) || isBlack(texture2D(inputValue, g).rgb)
						//|| isBlack(texture2D(inputValue, l).rgb) || isBlack(texture2D(inputValue, k).rgb) || isBlack(texture2D(inputValue, j).rgb) || isBlack(texture2D(inputValue, i).rgb) || isBlack(texture2D(inputValue, h).rgb)  
						){
					translation = 0.1;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(PINK, (0.25 * PI)/10.0 + translation * 10.0);
				}
				else if(isBlack(texture2D(inputValue, n_left).rgb) || isBlack(texture2D(inputValue, f_right).rgb)
						){
					translation = 0.1;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(GREEN, (0.25 * PI)/10.0 + translation * 10.0);
				}
				else{
				PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.25 * PI)/10.0 + translation * 10.0);
				}
			}
			else if(type == 1){
				if(isBlack(texture2D(inputValue, tc10).rgb) || isBlack(texture2D(inputValue, tc12).rgb ) 
				|| isBlack(texture2D(inputValue, c).rgb) || isBlack(texture2D(inputValue, j).rgb)
				){
					translation = 0.1;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(PINK, (0.5 * PI)/10.0 + translation * 10.0);
				}
				else{
				PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.5 * PI)/10.0 + translation  * 10.0);
				}
			}
			else if(type == 2){
				//Should be diagonal, but gets mostly recognized wrongly -> Use horizontal
				
				if(isBlack(texture2D(inputValue, n).rgb ) ||isBlack(texture2D(inputValue, f).rgb) 
				){
					translation = 0.1;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(BLUE, (0.25 * PI)/10.0 + translation * 10.0);
				}
				else{
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.25 * PI)/10.0 + translation  * 10.0);
				}
				
				//PosCol[ gl_GlobalInvocationID.x ].color = vec4(center_Col.rgb, (0.25 * PI)/10.0 + translation  * 10.0);
			}
			else{
				//Diagonal, Mainly seen on the orange roof (White house)
				if(isBlack(texture2D(inputValue, tc10).rgb) || isBlack(texture2D(inputValue, tc12).rgb ) 
				|| isBlack(texture2D(inputValue, n).rgb) || isBlack(texture2D(inputValue, f).rgb)
				|| isBlack(texture2D(inputValue, e).rgb) //Kills the Spikes at the white wall (left)
				|| isBlack(texture2D(inputValue, l).rgb) //Kills the Spikes at the white wall (left)
				){
					translation = 0.1;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(RED, (0.02 * PI)/10.0 + translation * 10.0);
				}
				else{
				PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.02 * PI)/10.0 + translation  * 10.0);
				}
			}
		}
	#endif

	///////////////////////
	// Translate the Translation
	///////////////////////
	#if 0
			if(type == 0){
				if(isBlack(texture2D(inputValue, tc10).rgb) || isBlack(texture2D(inputValue, tc12).rgb ) 
						|| isBlack(texture2D(inputValue, n).rgb) || isBlack(texture2D(inputValue, f).rgb)
						|| isBlack(texture2D(inputValue, tc20).rgb) || isBlack(texture2D(inputValue, tc21).rgb) || isBlack(texture2D(inputValue, tc22).rgb)
						//|| isBlack(texture2D(inputValue, m).rgb) || isBlack(texture2D(inputValue, g).rgb)
						//|| isBlack(texture2D(inputValue, l).rgb) || isBlack(texture2D(inputValue, k).rgb) || isBlack(texture2D(inputValue, j).rgb) || isBlack(texture2D(inputValue, i).rgb) || isBlack(texture2D(inputValue, h).rgb)  
						){
					translation = 0.8;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(PINK, (0.25 * PI)/10.0 + translation * 10.0);
				}
				else if(isBlack(texture2D(inputValue, n_left).rgb) || isBlack(texture2D(inputValue, f_right).rgb)
						){
					translation = 0.6;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(GREEN, (0.25 * PI)/10.0 + translation * 10.0);
				}
				else{
				PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.25 * PI)/10.0 + translation * 10.0);
				}
			}
			else if(type == 1){
				if(isBlack(texture2D(inputValue, tc10).rgb) || isBlack(texture2D(inputValue, tc12).rgb ) 
				|| isBlack(texture2D(inputValue, c).rgb) || isBlack(texture2D(inputValue, j).rgb)
				){
					translation = 0.4;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(PINK, (0.5 * PI)/10.0 + translation * 10.0);
				}
				else{
				PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.5 * PI)/10.0 + translation  * 10.0);
				}
			}
			else if(type == 2){
				//Should be diagonal, but gets mostly recognized wrongly -> Use horizontal
				
				if(isBlack(texture2D(inputValue, n).rgb ) ||isBlack(texture2D(inputValue, f).rgb) 
				){
					translation = 0.0;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(BLUE, (0.25 * PI)/10.0 + translation * 10.0);
					PosCol[ gl_GlobalInvocationID.x ].position.x = 500.0;
				}
				else{
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.25 * PI)/10.0 + translation  * 10.0);
				}
				
				//PosCol[ gl_GlobalInvocationID.x ].color = vec4(center_Col.rgb, (0.25 * PI)/10.0 + translation  * 10.0);
			}
			else{
				//Diagonal, Mainly seen on the orange roof (White house)
				if(isBlack(texture2D(inputValue, tc10).rgb) || isBlack(texture2D(inputValue, tc12).rgb ) 
				|| isBlack(texture2D(inputValue, n).rgb) || isBlack(texture2D(inputValue, f).rgb)
				|| isBlack(texture2D(inputValue, e).rgb) //Kills the Spikes at the white wall (left)
				|| isBlack(texture2D(inputValue, l).rgb) //Kills the Spikes at the white wall (left)
				){
					translation = 0.0;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(RED, (0.02 * PI)/10.0 + translation * 10.0);
					PosCol[ gl_GlobalInvocationID.x ].position.x = 500.0;
				}
				else{
				PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.02 * PI)/10.0 + translation  * 10.0);
				}
			}
		}
	#endif


	///////////////////////
	// Translate the Translation with original Color
	///////////////////////
	#if 1
			if(type == 0){
				if(isBlack(texture2D(inputValue, tc10).rgb) || isBlack(texture2D(inputValue, tc12).rgb ) 
						|| isBlack(texture2D(inputValue, n).rgb) || isBlack(texture2D(inputValue, f).rgb)
						|| isBlack(texture2D(inputValue, tc20).rgb) || isBlack(texture2D(inputValue, tc21).rgb) || isBlack(texture2D(inputValue, tc22).rgb)
						//|| isBlack(texture2D(inputValue, m).rgb) || isBlack(texture2D(inputValue, g).rgb)
						//|| isBlack(texture2D(inputValue, l).rgb) || isBlack(texture2D(inputValue, k).rgb) || isBlack(texture2D(inputValue, j).rgb) || isBlack(texture2D(inputValue, i).rgb) || isBlack(texture2D(inputValue, h).rgb)  
						){
					translation = 0.8;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.25 * PI)/10.0 + translation * 10.0);
				}
				else if(isBlack(texture2D(inputValue, n_left).rgb) || isBlack(texture2D(inputValue, f_right).rgb)
						){
					translation = 0.6;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.25 * PI)/10.0 + translation * 10.0);
				}
				else{
				PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.25 * PI)/10.0 + translation * 10.0);
				}

				
			}
			else if(type == 1){
				if(isBlack(texture2D(inputValue, tc10).rgb) || isBlack(texture2D(inputValue, tc12).rgb ) 
				|| isBlack(texture2D(inputValue, c).rgb) || isBlack(texture2D(inputValue, j).rgb)
				){
					translation = 0.4;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.5 * PI)/10.0 + translation * 10.0);
				}
				else{
				PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.5 * PI)/10.0 + translation  * 10.0);
				}
			}
			else if(type == 2){
				//Should be diagonal, but gets mostly recognized wrongly -> Use horizontal
				
				if(isBlack(texture2D(inputValue, n).rgb ) ||isBlack(texture2D(inputValue, f).rgb) 
				){
					translation = 0.0;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.25 * PI)/10.0 + translation * 10.0);
					PosCol[ gl_GlobalInvocationID.x ].position.x = 500.0;
				}
				else{
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.25 * PI)/10.0 + translation  * 10.0);
				}
				
				//PosCol[ gl_GlobalInvocationID.x ].color = vec4(center_Col.rgb, (0.25 * PI)/10.0 + translation  * 10.0);
			}
			else{
				//Diagonal, Mainly seen on the orange roof (White house)
				if(isBlack(texture2D(inputValue, tc10).rgb) || isBlack(texture2D(inputValue, tc12).rgb ) 
				|| isBlack(texture2D(inputValue, n).rgb) || isBlack(texture2D(inputValue, f).rgb)
				|| isBlack(texture2D(inputValue, e).rgb) //Kills the Spikes at the white wall (left)
				|| isBlack(texture2D(inputValue, l).rgb) //Kills the Spikes at the white wall (left)
				){
					translation = 0.0;
					PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.02 * PI)/10.0 + translation * 10.0);
					PosCol[ gl_GlobalInvocationID.x ].position.x = 500.0;
				}
				else{
				PosCol[ gl_GlobalInvocationID.x ].color = vec4(colorFactor * center_Col.rgb, (0.02 * PI)/10.0 + translation  * 10.0);
				}
			}
		}
	#endif
	///////////////////////
	// Output Color
	///////////////////////
	//PosCol[ gl_GlobalInvocationID.x ].color = center_Col; 

	//PosCol[ gl_GlobalInvocationID.x ].color = vec4(texture2D(depthValue, center).r);

	/*
	if(depthTestFailed){
		PosCol[ gl_GlobalInvocationID.x ].color = PINK4;
	}else{
		PosCol[ gl_GlobalInvocationID.x ].color = center_Col;
	}
	*/
}
