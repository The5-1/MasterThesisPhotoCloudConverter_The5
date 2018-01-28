#define GLEW_STATIC //Using the static lib, so we need to enable it
#define _CRT_SECURE_NO_DEPRECATE
#include <iostream>
#include <GL/glew.h>
#include <GL/glut.h>
#include <Ant/AntTweakBar.h>
#include <memory>
#include <algorithm>
#include "helper.h"
#include "Shader.h"
#include "Skybox.h"
#include "times.h"
#include "InstancedMesh.h"
#include "FBO.h"
#include "Texture.h"
#include "glm/gtx/string_cast.hpp"
#include "marchingCubesVolume.h"

#include "HalfEdgeMesh.h"
#include "MeshResampler.h"
#include "nanoflannHelper.h"

#include <stdlib.h>     /* srand, rand */
#include <time.h>       /* time */

#include "PC_Octree.h"
#include "ObjToPcd.h"
#include "BinaryFileReader.h"
#include "PC_Viewer.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

//Octree
PC_Octree* octree = nullptr;

//Time
Timer timer;
int frame;
long timeCounter, timebase;
char timeString[50];

//Resolution (has to be changed in helper.h too)
glm::vec2 resolution = glm::vec2(1024.0f, 768.0f);

//Externals
//cameraSystem cam(1.0f, 1.0f, glm::vec3(20.95f, 20.95f, -0.6f));
//cameraSystem cam(1.0f, 1.0f, glm::vec3(2.44f, 1.41f, 0.008f));
cameraSystem cam(1.0f, 1.0f, glm::vec3(6.36f, 2.94f, 0.05f));

glm::mat4 projMatrix;
glm::mat4 viewMatrix;

bool leftMouseClick;
int leftMouseClickX;
int leftMouseClickY;

//Skybox
Skybox skybox;
char* negz = "C:/Dev/Assets/SkyboxTextures/Yokohama2/negz.jpg";
char* posz = "C:/Dev/Assets/SkyboxTextures/Yokohama2/posz.jpg";
char* posy = "C:/Dev/Assets/SkyboxTextures/Yokohama2/posy.jpg";
char* negy = "C:/Dev/Assets/SkyboxTextures/Yokohama2/negy.jpg";
char* negx = "C:/Dev/Assets/SkyboxTextures/Yokohama2/negx.jpg";
char* posx = "C:/Dev/Assets/SkyboxTextures/Yokohama2/posx.jpg";

//Textures
FilterKernel* filter = 0;

//Shaders
Shader basicShader;
Shader modelLoaderShader;
Shader simpleSplatShader;
Shader basicColorShader;
Shader pointShader;
//FBO Shader
Shader quadScreenSizedShader;
Shader standardMiniColorFboShader;
Shader standardMiniDepthFboShader;
//FBO Shader
Shader pointGbufferShader;
Shader pointDeferredShader;
Shader pointFuzzyShader;
Shader pointFuzzyFinalShader;
Shader pointGbufferUpdatedShader;
Shader pointDeferredUpdatedShader;
Shader pointGbufferUpdated2ndPassShader;
//Pixel
Shader pixelShader;

//Masterthesis - ComputeShader
Shader pcToPhotoComputeShader;
Shader photoToPcComputeShader;
Shader gravityShader;

//Textures
Texture *photoTexture = nullptr;
Texture *pointCloudTexture = nullptr;

//Filter
Shader gaussFilterShader;
Shader oneDimKernelShader;

//Skybox
Shader skyboxShader;

//Models
simpleModel *teaPot = 0;
solidSphere *sphere = 0;
simpleQuad * quad = 0;
coordinateSystem *coordSysstem = 0;
viewFrustrum * viewfrustrum = 0;
BinaryReadDraw *binaryDraw = 0;
PC_Viewer *viewer = nullptr;

//Frame buffer object
FBO *fbo = 0;
FBO *fbo2 = 0;

// tweak bar
TwBar *tweakBar;
bool wireFrameTeapot = false;
bool backfaceCull = false;
bool drawOctreeBox = false;
bool setViewFrustrum = false;
bool showFrustrumCull = false;
bool fillViewFrustrum = false;
bool debugView = true;
bool useGaussFilter = false;
int filterPasses = 5;
glm::vec3 lightPos = glm::vec3(10.0, 10.0, 0.0);
float glPointSizeFloat = 80.0f;
float depthEpsilonOffset = 0.0f;
typedef enum { QUAD_SPLATS, POINTS_GL } SPLAT_TYPE; SPLAT_TYPE m_currenSplatDraw = POINTS_GL;
typedef enum { SIMPLE, DEBUG, DEFERRED, TRIANGLE, KERNEL, DEFERRED_UPDATE, CULL_DEFERRED } RENDER_TYPE; RENDER_TYPE m_currenRender = CULL_DEFERRED;

/* *********************************************************************************************************
Helper Function
********************************************************************************************************* */
void drawFBO(FBO *_fbo) {
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glEnable(GL_DEPTH_TEST);
	glDisable(GL_CULL_FACE);
	glClearColor(0.2f, 0.2f, 0.2f, 1);
	//Color
	standardMiniColorFboShader.enable();
	_fbo->bindTexture(0);
	standardMiniColorFboShader.uniform("tex", 0);
	standardMiniColorFboShader.uniform("downLeft", glm::vec2(0.0f, 0.5f));
	standardMiniColorFboShader.uniform("upRight", glm::vec2(0.5f, 1.0f));
	quad->draw();
	_fbo->unbindTexture(0);
	standardMiniColorFboShader.disable();

	//Depth
	standardMiniDepthFboShader.enable();
	_fbo->bindDepth();
	standardMiniDepthFboShader.uniform("tex", 0);
	standardMiniDepthFboShader.uniform("downLeft", glm::vec2(0.5f, 0.5f));
	standardMiniDepthFboShader.uniform("upRight", glm::vec2(1.0f, 1.0f));
	quad->draw();
	_fbo->unbindDepth();
	standardMiniDepthFboShader.disable();

	//Normal
	standardMiniColorFboShader.enable();
	_fbo->bindTexture(1);
	standardMiniColorFboShader.uniform("tex", 0);
	standardMiniColorFboShader.uniform("downLeft", glm::vec2(0.0f, 0.0f));
	standardMiniColorFboShader.uniform("upRight", glm::vec2(0.5f, 0.5f));
	quad->draw();
	_fbo->unbindTexture(1);
	standardMiniColorFboShader.disable();

	//Position
	standardMiniColorFboShader.enable();
	_fbo->bindTexture(2);
	standardMiniColorFboShader.uniform("tex", 0);
	standardMiniColorFboShader.uniform("downLeft", glm::vec2(0.5f, 0.0f));
	standardMiniColorFboShader.uniform("upRight", glm::vec2(1.0f, 0.5f));
	quad->draw();
	_fbo->unbindTexture(2);
	standardMiniColorFboShader.disable();
}

typedef enum { INDEX, ALL, DYNAMIC } DRAW_TYPE; DRAW_TYPE m_splatDraw = INDEX;
int index0 = 0, index1 = 0, index2 = 0;
bool refresh = false;
bool print = false;
bool printDynamic = false;
float lodLevel = 0.0f;

float sphereRadius = 1.0f;
float sphereX = 0.0f;
float sphereY = 0.0f;
float sphereZ = 0.0f;
float tc_x = 0.0f;
float tc_y = 0.0f;
bool wireframe = true;
bool screenshot = false;
bool gravityComputeShader = false;
bool panoramaComputeShader = false;
bool colorComputeShader = false;
/* *********************************************************************************************************
TweakBar
********************************************************************************************************* */
void setupTweakBar() {
	TwInit(TW_OPENGL_CORE, NULL);
	tweakBar = TwNewBar("Settings");

	TwEnumVal Draw[] = { { INDEX, "INDEX" },{ ALL, "ALL" },{ DYNAMIC , "DYNAMIC" } };
	TwType SplatsTwType = TwDefineEnum("DrawType", Draw, 3);
	TwAddVarRW(tweakBar, "Splats", SplatsTwType, &m_splatDraw, NULL);

	TwAddSeparator(tweakBar, "Splat Draw", nullptr);
	TwAddVarRW(tweakBar, "glPointSize", TW_TYPE_FLOAT, &glPointSizeFloat, " label='glPointSize' min=0.0 step=10.0 max=1000.0");
	TwAddVarRW(tweakBar, "Sphere r", TW_TYPE_FLOAT, &sphereRadius, " label='Sphere r' min=0.0 step=0.1 max=100.0");
	TwAddVarRW(tweakBar, "Sphere x", TW_TYPE_FLOAT, &sphereX, " label='Sphere x' min=-100.0 step=1.0 max=100.0");
	TwAddVarRW(tweakBar, "Sphere y", TW_TYPE_FLOAT, &sphereY, " label='Sphere y' min=-100.0 step=1.0 max=100.0");
	TwAddVarRW(tweakBar, "Sphere z", TW_TYPE_FLOAT, &sphereZ, " label='Sphere z' min=-100.0 step=1.0 max=100.0");

	TwAddVarRW(tweakBar, "Wireframe", TW_TYPE_BOOLCPP, &wireframe, " label='Wireframe' ");
	TwAddVarRW(tweakBar, "Screenshot", TW_TYPE_BOOLCPP, &screenshot, " label='Screenshot' ");
	TwAddSeparator(tweakBar, "", NULL);
	TwAddVarRW(tweakBar, "Gravity", TW_TYPE_BOOLCPP, &gravityComputeShader, " label='Gravity' ");
	TwAddSeparator(tweakBar, "", NULL);
	TwAddVarRW(tweakBar, "Get Panorama", TW_TYPE_BOOLCPP, &panoramaComputeShader, " label='Get Panorama' ");
	TwAddSeparator(tweakBar, "", NULL);
	TwAddVarRW(tweakBar, "Color from photo", TW_TYPE_BOOLCPP, &colorComputeShader, " label='Color from photo' ");
	TwAddVarRW(tweakBar, "TC x", TW_TYPE_FLOAT, &tc_x, " label='TC x' min=-1.0 step=0.01 max=1.0");
	TwAddVarRW(tweakBar, "TC y", TW_TYPE_FLOAT, &tc_y, " label='TC y' min=-1.0 step=0.01 max=1.0");
}

/* *********************************************************************************************************
Initiation
********************************************************************************************************* */
GLuint mainVBO[2];
int mainVBOsize = 0;
int work_group_size = 128;

int pointCloudTextureHeight = 1024;
int pointCloudTextureWidth = 2048;

struct posAndCol {
	glm::vec4 position;
	glm::vec4 color;
};

GLuint mainSsboPosCol;
void init() {
	/*****************************************************************
	Screen-Quad
	*****************************************************************/
	quad = new simpleQuad();
	quad->upload();


	/*****************************************************************
	Sphere
	*****************************************************************/
	sphere = new solidSphere(1.0f, 10, 10);
	sphere->upload();

	/*****************************************************************
	Filter
	*****************************************************************/
	filter = new FilterKernel();

	/*****************************************************************
	obj-Models
	*****************************************************************/
	std::vector<glm::vec3> bigVertices, bigNormals, bigColors;
	std::vector<float> bigRadii;

	//FILE * file = fopen("//home.rrze.uni-erlangen.de/ar81ohoq/Desktop/Dev/Assets/Pointclouds/Station018.txt", "r");

	//FILE * file = fopen("D:/Dev/Assets/Pointcloud/Station/Segmented300k/Station018.txt", "r");
	FILE * file = fopen("D:/Dev/Assets/Pointcloud/Station/Station018.txt", "r");
	

	if (file == NULL) {
		cerr << "Model file not found" << endl;
		exit(0);
	}

	char lineHeader[128];
	fgets(lineHeader, 128, file); //Reads the first line, which contains the build of the file (We just assume they are always build the same way)

	int numVertices;
	fscanf(file, "%i\n", &numVertices);
	std::cout << "Load Point-Cloud from Text file: " << numVertices << " numVertices" << std::endl;

	/*****************************************************************
	Start Compute Shader - Setup
	*****************************************************************/
	glGenBuffers(1, &mainSsboPosCol);
	/*
	UniformBufferObjects (UBO): Read only
	Shader Storage Buffer Objects (SSBO): Read and write
	*/
	glBindBuffer(GL_SHADER_STORAGE_BUFFER, mainSsboPosCol);
	/*	!!!!!!!!!!!
	Shader_Storage_Buffers need to be a multiple of 4 floats!!!
	https://www.cg.tuwien.ac.at/courses/Realtime/repetitorium/VU.WS.2014/rtr_rep_2014_ComputeShader.pdf (Page 26 as PDF, Slide 29)
	https://www.opengl.org/discussion_boards/showthread.php/199410-SSBO-alignment-question
	!!!!!!!!!!!!!!! */
	glBufferData(GL_SHADER_STORAGE_BUFFER, numVertices * sizeof(posAndCol), NULL, GL_STATIC_DRAW);

	GLint bufMask = GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_BUFFER_BIT;
	posAndCol *posCS = (posAndCol*)glMapBufferRange(GL_SHADER_STORAGE_BUFFER, 0, numVertices * sizeof(posAndCol), bufMask);

	/*****************************************************************
	End Compute Shader - Setup
	*****************************************************************/

	for (int i = 0; i < numVertices; i++) {
		mainVBOsize++;

		double X, Y, Z;
		float Xf, Yf, Zf;
		glm::vec3 color;
		float Point_Source_ID, Scan_Angle_Rank, Time, Intensity, Classification;

		fscanf(file, "%lf %lf %lf %f %f %f %f\n", &X, &Y, &Z, &color.x, &color.y, &color.z, &Intensity);

		//Move the position of the Scanner to (0.0, 0.0, 0.0)
		float scanXpos = 813.16972799999996f;
		float scanYpos = 599.10159699999997f;
		float scanZpos = 29.616304f;

		Xf = float(X) - scanXpos;
		Yf = float(Y) - scanYpos;
		Zf = float(Z) - scanZpos;

		posCS[i].position.x = Xf;
		posCS[i].position.y = Zf;
		posCS[i].position.z = Yf;
		posCS[i].position.w = 1.0f;

		posCS[i].color.r = color.r;
		posCS[i].color.g = color.g;
		posCS[i].color.b = color.b;
		posCS[i].color.a = 1.0f;
	}

	std::fclose(file);

	glUnmapBuffer(GL_SHADER_STORAGE_BUFFER);

	/*****************************************************************
	Textures (Pointcloud)
	*****************************************************************/
	pointCloudTexture = new Texture(pointCloudTextureWidth, pointCloudTextureHeight, GL_RGBA32F, GL_RGBA, GL_FLOAT);
	photoTexture = new Texture("D:/Dev/Assets/Pointcloud/Station/Station018.jpg");
	//photoTexture = new Texture("C:/Dev/Assets/Sponza_Atrium_Png/Textures/background.png");

	/*****************************************************************
	Coordinate System
	*****************************************************************/
	coordSysstem = new coordinateSystem();
	coordSysstem->upload();

	/*****************************************************************
	View Frusturm
	*****************************************************************/
	viewfrustrum = new viewFrustrum(glm::mat4(1.0f), viewMatrix, projMatrix, 5, glm::vec3(cam.viewDir));
	viewfrustrum->upload();

	/*****************************************************************
	Skybox (Only for aesthetic reasons, can be deleted)
	*****************************************************************/
	skybox.createSkybox(negz, posz, posy, negy, negx, posx);

	/*****************************************************************
	FBO
	*****************************************************************/
	fbo = new FBO("Gbuffer", WIDTH, HEIGHT, FBO_GBUFFER_32BIT);
	gl_check_error("fbo");

	fbo2 = new FBO("Gbuffer", WIDTH, HEIGHT, FBO_GBUFFER_32BIT);
	gl_check_error("fbo2");
}


void loadShader(bool init) {
	basicShader = Shader("./shader/basic.vs.glsl", "./shader/basic.fs.glsl");
	basicColorShader = Shader("./shader/basicColor.vs.glsl", "./shader/basicColor.fs.glsl");
	modelLoaderShader = Shader("./shader/modelLoader.vs.glsl", "./shader/modelLoader.fs.glsl");
	skyboxShader = Shader("./shader/skybox.vs.glsl", "./shader/skybox.fs.glsl");
	simpleSplatShader = Shader("./shader/simpleSplat.vs.glsl", "./shader/simpleSplat.fs.glsl", "./shader/simpleSplat.gs.glsl");
	pointShader = Shader("./shader/point.vs.glsl", "./shader/point.fs.glsl");

	//Deferred
	pointGbufferShader = Shader("./shader/PointGbuffer/pointGbuffer.vs.glsl", "./shader/PointGbuffer/pointGbuffer.fs.glsl");
	pointDeferredShader = Shader("./shader/PointGbuffer/pointDeferred.vs.glsl", "./shader/PointGbuffer/pointDeferred.fs.glsl");
	pointFuzzyShader = Shader("./shader/PointGbuffer/pointFuzzy.vs.glsl", "./shader/PointGbuffer/pointFuzzy.fs.glsl");
	pointFuzzyFinalShader = Shader("./shader/PointGbuffer/pointFuzzyFinal.vs.glsl", "./shader/PointGbuffer/pointFuzzyFinal.fs.glsl");

	//Updated
	pointGbufferUpdatedShader = Shader("./shader/PointGbuffer/pointGbufferUpdated.vs.glsl", "./shader/PointGbuffer/pointGbufferUpdated.fs.glsl");
	pointDeferredUpdatedShader = Shader("./shader/PointGbuffer/pointDeferredUpdated.vs.glsl", "./shader/PointGbuffer/pointDeferredUpdated.fs.glsl");
	pointGbufferUpdated2ndPassShader = Shader("./shader/PointGbuffer/pointGbufferUpdated2ndPass.vs.glsl", "./shader/PointGbuffer/pointGbufferUpdated2ndPass.fs.glsl");


	//FBO
	quadScreenSizedShader = Shader("./shader/FboShader/quadScreenSized.vs.glsl", "./shader/FboShader/quadScreenSized.fs.glsl");
	standardMiniColorFboShader = Shader("./shader/FboShader/standardMiniColorFBO.vs.glsl", "./shader/FboShader/standardMiniColorFBO.fs.glsl");
	standardMiniDepthFboShader = Shader("./shader/FboShader/standardMiniDepthFBO.vs.glsl", "./shader/FboShader/standardMiniDepthFBO.fs.glsl");
	gaussFilterShader = Shader("./shader/Filter/gaussFilter.vs.glsl", "./shader/Filter/gaussFilter.fs.glsl");

	//Pixel
	pixelShader = Shader("./shader/Pixel/pixel.vs.glsl", "./shader/Pixel/pixel.fs.glsl");

	//Debug-Shaders
	oneDimKernelShader = Shader("./shader/Filter/oneDimKernel.vs.glsl", "./shader/Filter/oneDimKernel.fs.glsl");

	//ComputeShader
	pcToPhotoComputeShader = Shader("./shader/ComputeShader/pcToPhoto.cs.glsl"); 
	photoToPcComputeShader = Shader("./shader/ComputeShader/photoToPc.cs.glsl");
	gravityShader = Shader("./shader/ComputeShader/gravity.cs.glsl");
}

/* *********************************************************************************************************
Scenes: Unit cube + Pointcloud
********************************************************************************************************* */
void PixelScene() {
	fbo->Bind();
	{
		/* ********************************************
		Print
		**********************************************/
		//Clear
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glClearColor(0.3f, 0.3f, 0.3f, 1.0f);

		glDisable(GL_CULL_FACE);

		/* ********************************************
		Coordinate System
		**********************************************/
		basicColorShader.enable();
		glm::mat4 modelMatrix = glm::scale(glm::vec3(1.0f));
		basicColorShader.uniform("modelMatrix", modelMatrix);
		basicColorShader.uniform("viewMatrix", viewMatrix);
		basicColorShader.uniform("projMatrix", projMatrix);
		coordSysstem->draw();
		basicColorShader.disable();

		/* ********************************************
		Sphere
		**********************************************/

		if (wireframe) {
			glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		}
		basicShader.enable();
		modelMatrix = glm::mat4(1.0f);
		modelMatrix = glm::translate(modelMatrix, glm::vec3(sphereX, sphereY, sphereZ));
		modelMatrix = glm::scale(modelMatrix, glm::vec3(sphereRadius));

		basicShader.uniform("modelMatrix", modelMatrix);
		basicShader.uniform("viewMatrix", viewMatrix);
		basicShader.uniform("projMatrix", projMatrix);
		basicShader.uniform("col", glm::vec3(1.0f, 0.0f, 0.0f));
		sphere->draw();
		basicShader.disable();
		if (wireframe) {
			glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
		}

		/* ********************************************
		Pointcloud + Compute Shader (Source https://www.khronos.org/assets/uploads/developers/library/2014-siggraph-bof/KITE-BOF_Aug14.pdf)
		**********************************************/
		if (gravityComputeShader) {
			//Compute
			gravityShader.enable();
			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, mainSsboPosCol);
			glDispatchCompute(int(mainVBOsize / work_group_size), 1, 1);
			glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
			gravityShader.disable();
		}

		if (panoramaComputeShader) {
			panoramaComputeShader = false;
			/*****************************************************************
			Fill Texture
			*****************************************************************/
			pcToPhotoComputeShader.enable();
			glActiveTexture(GL_TEXTURE0);
			pointCloudTexture->Bind();
			glBindImageTexture(0, pointCloudTexture->Index(), 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA32F);
			glUniform1i(glGetUniformLocation(pcToPhotoComputeShader.ID, "width"), pointCloudTextureWidth);
			glUniform1i(glGetUniformLocation(pcToPhotoComputeShader.ID, "height"), pointCloudTextureHeight);

			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, mainSsboPosCol);

			glDispatchCompute(int(mainVBOsize / work_group_size) + 1, 1, 1);
			glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);

			pcToPhotoComputeShader.disable();
			pointCloudTexture->Unbind();

			/*****************************************************************
			Texture to PNG
			*****************************************************************/

			const size_t bytesPerChannel = 3;
			const size_t imageSizeInBytes = bytesPerChannel * size_t(pointCloudTextureWidth) * size_t(pointCloudTextureHeight);
			BYTE* pixels = static_cast<BYTE*>(malloc(imageSizeInBytes));

			GLint m_viewport[4];
			glGetIntegerv(GL_VIEWPORT, m_viewport);
			glPixelStorei(GL_PACK_ALIGNMENT, 1);

			pointCloudTexture->Bind();
			glGetTexImage(GL_TEXTURE_2D, 0, GL_RGB, GL_UNSIGNED_BYTE, pixels);
			pointCloudTexture->Unbind();

			for (int y = 0; y < pointCloudTextureHeight / 2; y++)
			{
				const int swapY = pointCloudTextureHeight - y - 1;
				for (int x = 0; x < pointCloudTextureWidth; x++)
				{
					const int offset = int(bytesPerChannel) * (x + y * pointCloudTextureWidth);
					const int swapOffset = int(bytesPerChannel) * (x + swapY * pointCloudTextureWidth);
					std::swap(pixels[offset + 0], pixels[swapOffset + 0]);
					std::swap(pixels[offset + 1], pixels[swapOffset + 1]);
					std::swap(pixels[offset + 2], pixels[swapOffset + 2]);
				}
			}
			std::string name = "panoramaStation_" + std::to_string(pointCloudTextureWidth) + "x" + std::to_string(pointCloudTextureHeight) + ".png";
			stbi_write_png(name.c_str(), pointCloudTextureWidth, pointCloudTextureHeight, 3, pixels, 0);
		}

		if (colorComputeShader) {
			//colorComputeShader = false;

			photoToPcComputeShader.enable();
			glActiveTexture(GL_TEXTURE0);
			photoTexture->Bind();
			photoToPcComputeShader.uniform("tc_x", tc_x);
			photoToPcComputeShader.uniform("tc_y", tc_y);
			standardMiniColorFboShader.uniform("tex", 0);

			glUniform1i(glGetUniformLocation(photoToPcComputeShader.ID, "width"), photoTexture->w);
			glUniform1i(glGetUniformLocation(photoToPcComputeShader.ID, "height"), photoTexture->h);

			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, mainSsboPosCol);

			glDispatchCompute(int(mainVBOsize / work_group_size) + 1, 1, 1);
			glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);

			photoToPcComputeShader.disable();
			photoTexture->Unbind();
		}

		//Render
		glEnable(GL_POINT_SPRITE);
		glEnable(GL_PROGRAM_POINT_SIZE);
		pixelShader.enable();

		pixelShader.uniform("viewMatrix", viewMatrix);
		pixelShader.uniform("projMatrix", projMatrix);
		pixelShader.uniform("glPointSize", glPointSizeFloat);

		glEnableVertexAttribArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, mainSsboPosCol);
		glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, sizeof(posAndCol), 0);

		glEnableVertexAttribArray(1);
		glBindBuffer(GL_ARRAY_BUFFER, mainSsboPosCol);
		glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, sizeof(posAndCol), ((void*)(16))); //Last parameter is offset -> Before color we have a vec4 position -> 4 floats -> 16 byte offset
																						   //glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, sizeof(posAndCol), (GLvoid*)offsetof(VertexFormat, color));  //http://en.cppreference.com/w/cpp/types/offsetof , https://gamedev.stackexchange.com/questions/106141/how-to-correctly-specify-the-offset-in-a-call-to-glvertexattribpointer

		glEnableClientState(GL_VERTEX_ARRAY);
		glDrawArrays(GL_POINTS, 0, mainVBOsize);
		glDisableClientState(GL_VERTEX_ARRAY);

		pixelShader.disable();
		glDisable(GL_POINT_SPRITE);
		glDisable(GL_PROGRAM_POINT_SIZE);


	}
	fbo->Unbind();

	if (screenshot) {
		screenshot = false;
		/*
		https://www.gamedev.net/forums/topic/436385-how-to-save-a-screenshot-in-opengl/
		*/
		const int width = WIDTH;
		const int height = HEIGHT;

		const size_t bytesPerPixel = 3;	// RGB
		const size_t imageSizeInBytes = bytesPerPixel * size_t(width) * size_t(height);

		// Allocate with malloc, because the data will be managed by wxImage
		BYTE* pixels = static_cast<BYTE*>(malloc(imageSizeInBytes));

		// glReadPixels takes the lower-left corner, while GetViewportOffset gets the top left corner
		GLint m_viewport[4];
		glGetIntegerv(GL_VIEWPORT, m_viewport);

		// glReadPixels can align the first pixel in each row at 1-, 2-, 4- and 8-byte boundaries. We
		// have allocated the exact size needed for the image so we have to use 1-byte alignment
		// (otherwise glReadPixels would write out of bounds)
		glPixelStorei(GL_PACK_ALIGNMENT, 1);
		glReadPixels(m_viewport[0], m_viewport[1], width, height, GL_RGB, GL_UNSIGNED_BYTE, pixels); //Only works on FBO's

		// glReadPixels reads the given rectangle from bottom-left to top-right, so we must
		// reverse it
		for (int y = 0; y < height / 2; y++)
		{
			const int swapY = height - y - 1;
			for (int x = 0; x < width; x++)
			{
				const int offset = int(bytesPerPixel) * (x + y * width);
				const int swapOffset = int(bytesPerPixel) * (x + swapY * width);

				// Swap R, G and B of the 2 pixels
				std::swap(pixels[offset + 0], pixels[swapOffset + 0]);
				std::swap(pixels[offset + 1], pixels[swapOffset + 1]);
				std::swap(pixels[offset + 2], pixels[swapOffset + 2]);
			}
		}

		////int stbi_write_png(char const *filename, int w, int h, int comp, const void *data, int stride_in_bytes);
		///*The functions create an image file defined by the parameters. The image
		//  is a rectangle of pixels stored from left-to-right, top-to-bottom.
		//  Each pixel contains 'comp' channels of data stored interleaved with 8-bits
		//  per channel, in the following order: 1=Y, 2=YA, 3=RGB, 4=RGBA. (Y is
		//  monochrome color.) The rectangle is 'w' pixels wide and 'h' pixels tall.
		//  The *data pointer points to the first byte of the top-left-most pixel.
		//  For PNG, "stride_in_bytes" is the distance in bytes from the first byte of
		//  a row of pixels to the first byte of the next row of pixels.*/
		stbi_write_png("screenshot.png", WIDTH, HEIGHT, 3, pixels, 0);

		/*
		Example stb_image_write (http://antongerdelan.net/blog/formatted/2015_02_10_bresenham.html)
		*/
		//unsigned char img[256 * 256 * 3];
		//for (int x = 0; x < 256; x++) {
		//	for (int y = 0; y < 256; y++) {
		//		int index = y * 256 + x;
		//		int red = index * 3;
		//
		//		img[red] = 100;
		//		img[red + 1] = 0;
		//		img[red + 2] = 0;
		//	}
		//}
		//stbi_write_png("output.png", 256, 256, 3, img, 0);
	}

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_CULL_FACE);
	glClearColor(0.2f, 0.2f, 0.2f, 1);


	standardMiniColorFboShader.enable();
	fbo->bindTexture(0);
	standardMiniColorFboShader.uniform("tex", 0);
	standardMiniColorFboShader.uniform("downLeft", glm::vec2(0.0f, 0.0f));
	standardMiniColorFboShader.uniform("upRight", glm::vec2(1.0f, 1.0f));
	quad->draw();
	fbo->unbindTexture(0);
	standardMiniColorFboShader.disable();

	
	standardMiniColorFboShader.enable();
	glActiveTexture(GL_TEXTURE0);
	pointCloudTexture->Bind();
	standardMiniColorFboShader.uniform("tex", 0);
	standardMiniColorFboShader.uniform("downLeft", glm::vec2(0.6f, 0.6f));
	standardMiniColorFboShader.uniform("upRight", glm::vec2(1.0f, 1.0f));
	quad->draw();
	pointCloudTexture->Unbind();
	standardMiniColorFboShader.disable();



	standardMiniColorFboShader.enable();
	glActiveTexture(GL_TEXTURE0);
	photoTexture->Bind();
	standardMiniColorFboShader.uniform("tex", 0);
	standardMiniColorFboShader.uniform("downLeft", glm::vec2(0.6f, 0.2f));
	standardMiniColorFboShader.uniform("upRight", glm::vec2(1.0f, 0.6f));
	quad->draw();
	photoTexture->Unbind();
	standardMiniColorFboShader.disable();
}

/* *********************************************************************************************************
Display + Main
********************************************************************************************************* */
void display() {
	//Timer
	timer.update();

	//FPS-Counter
	frame++;
	timeCounter = glutGet(GLUT_ELAPSED_TIME);
	if (timeCounter - timebase > 1000) {
		sprintf_s(timeString, "FPS:%4.2f", frame*1000.0 / (timeCounter - timebase));
		timebase = timeCounter;
		frame = 0;
		glutSetWindowTitle(timeString);
	}

	PixelScene();

	TwDraw(); //Draw Tweak-Bar

	glutSwapBuffers();
	glutPostRedisplay();

}

int main(int argc, char** argv) {
	glutInit(&argc, argv);
	glutInitWindowSize(WIDTH, HEIGHT);
	glutInitDisplayMode(GLUT_RGB | GLUT_DEPTH | GLUT_DOUBLE | GLUT_STENCIL);

	glutCreateWindow("Basic Framework");

	setupTweakBar();

	GLenum err = glewInit();
	if (GLEW_OK != err) {
		std::cerr << "Error : " << glewGetErrorString(err) << std::endl;
	}

	glutDisplayFunc(display);
	glutKeyboardFunc(keyboard);
	glutMotionFunc(onMouseMove);
	glutMouseFunc(onMouseDown);
	glutReshapeFunc(reshape);
	glutIdleFunc(onIdle);

	glutSpecialFunc((GLUTspecialfun)TwEventSpecialGLUT);
	glutPassiveMotionFunc((GLUTmousemotionfun)TwEventMouseMotionGLUT);
	TwGLUTModifiersFunc(glutGetModifiers);

	initGL();

	init();

	glutMainLoop();

	TwTerminate();

	delete coordSysstem;
	delete octree;
	delete viewfrustrum;
	//delete_VTKfile();


	return 0;
}
