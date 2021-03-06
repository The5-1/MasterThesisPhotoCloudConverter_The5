#ifndef TEXTURE_H
#define TEXTURE_H

//#define STB_IMAGE_IMPLEMENTATION
//#include "stb_image.h"

#include <GL/glew.h>
#include <GL/glut.h>
#include <iostream>



class Texture {
public:
	int w, h;
	GLuint index;

public:
	/***********
	Default
	***********/
	Texture() {
	}

	/***********
	Selfmade-Texture
	***********/
	Texture(int w, int h, int internal_format, int format, int type){

		this->w = w;
		this->h = h;

		glGenTextures(1, &index);
		//std::cout << "tex id " << index << std::endl;

		// "Bind" the newly created texture : all future texture functions will modify this texture
		glBindTexture(GL_TEXTURE_2D, index);


		glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

		// Give an empty image to OpenGL ( the last "0" )
		glTexImage2D(GL_TEXTURE_2D, 0, internal_format, w, h, 0, format, type, 0);
	}


	//Texture(int w, int h, glm::vec4 color) {
	//	this->w = w;
	//	this->h = h;
	//
	//	glGenTextures(1, &index);
	//	GLubyte  *emptyData = new GLubyte[w * h * 4];
	//
	//	for (int i = 0; i < w * h; i++) {
	//		emptyData[4 * i + 0] = 255;
	//		emptyData[4 * i + 1] = 255;
	//		emptyData[4 * i + 2] = 255;
	//		emptyData[4 * i + 3] = 255;
	//	}
	//
	//	glBindTexture(GL_TEXTURE_2D, index);
	//	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, emptyData);
	//
	//	delete[] emptyData;
	//}

	Texture(int w, int h, glm::vec4 color) {
		std::cout << "Texture.h: Created test Texture" << std::endl;
	
		this->w = w;
		this->h = h;
	
		glGenTextures(1, &index);
		gl_check_error("Texture with data start");
		//Data
		//std::vector<GLfloat> emptyData(w * h * 4);
		GLfloat *emptyData = new GLfloat[w * h * 4];
		for (int i = 0; i < w * h; i++) {
			emptyData[4 * i + 0] = color.x;
			emptyData[4 * i + 1] = color.y;
			emptyData[4 * i + 2] = color.z;
			emptyData[4 * i + 3] = color.w;
		}

		//Bind
		glBindTexture(GL_TEXTURE_2D, index);
		gl_check_error("Texture with data mid");
		//Some options
		//glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		//glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		//glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		//glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		//glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	
		//Use the clear color
		//glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, 0, w, h, GL_RGBA, GL_FLOAT, &emptyData[0]);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, 0, w, h, GL_RGBA, GL_FLOAT, emptyData);
		gl_check_error("Texture with data finish");
		//Delete stuff on CPU
		//delete[] emptyData;
	}


	/***********
	Texture from image
	***********/
	Texture(std::string filepath) {
		glGenTextures(1, &this->index);
		
		int width, height, nrComponents;
		unsigned char *data = stbi_load(filepath.c_str(), &width, &height, &nrComponents, 0);
		
		this->w = width;
		this->h = height;
		
		if (data)
		{
			GLenum format;
			if (nrComponents == 1) {
				format = GL_RED;
			}
			else if (nrComponents == 2) {
				format = GL_RG;
			}
			else if (nrComponents == 3){
				format = GL_RGB;
			}
			else if (nrComponents == 4) {
				format = GL_RGBA;
			}
			
			//std::cout << "Texture.h: " << filepath << " has " << nrComponents << " components" << std::endl;

			glBindTexture(GL_TEXTURE_2D, this->index);
			glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data);
			glGenerateMipmap(GL_TEXTURE_2D);
		
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		
			stbi_image_free(data);
		}
		else
		{
			std::cout << "Texture.h failed to load at path: " << filepath << std::endl;
			stbi_image_free(data);
		}
	}

	void Bind() {
		glBindTexture(GL_TEXTURE_2D, this->index);
	}

	int Unbind() {
		glBindTexture(GL_TEXTURE_2D, 0);
		return index;
	}

	GLuint Index() const { 
		return index; 
	}

};

class FilterKernel {
public:
	int w;
	GLuint index;

public:
	FilterKernel() {
		const float sigma2 = 0.316228f; // Sqrt(0.1).

		GLfloat yi[256];
		for (unsigned int i = 0; i < 256; ++i)
		{
			float x = static_cast<GLfloat>(i) / 255.0f;
			float const w = x * x / (2.0f * sigma2);
			yi[i] = std::exp(-w);

			//std::cout << yi[i] << " ";
		}

		glGenTextures(1, &index);
		glBindTexture(GL_TEXTURE_1D, index);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
		glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		//void glTexImage1D(GLenum target,GLint level,GLint internalFormat,GLsizei width,GLint border,GLenum format,GLenum type,const GLvoid * data);
		this->w = 256;
		glTexImage1D(GL_TEXTURE_1D, 0, GL_R32F, w, 0, GL_RED, GL_FLOAT, yi);
	}



	void Bind() {
		glBindTexture(GL_TEXTURE_2D, index);
	}

	int Unbind() {
		glBindTexture(GL_TEXTURE_2D, 0);
		return index;
	}

	GLuint Index() const {
		return index;
	}

};

#endif
