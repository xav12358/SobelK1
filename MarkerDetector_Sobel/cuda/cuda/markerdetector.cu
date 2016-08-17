#include "math/interpolation_func.h"
#include "markerdetector.h"


#include "cleanBuffers.cu"
#include "processSobel.cu"

#include <iostream>
#include <math.h>
#include <string>
#include <stdio.h>
#include <stdlib.h>



char *bufferToDisplay;

////////////////////////////
/// \brief MarkerDetector_gpu::MarkerDetector_gpu
/// \param rows
/// \param cols
///
MarkerDetector_gpu::MarkerDetector_gpu(int rows,int cols)

{

	bufferToDisplay = (char *)malloc(500*sizeof(char));

	LOGD("MarkerDetector_gpu0\n");
	if(VERBOSE)
		std::cout << "- MarkerDetector_gpu contructeur "<< std::endl;


	icols = cols;
	irows = rows;
	threads = dim3(BLOCK_SIZE_X,BLOCK_SIZE_Y);
	blocks  = dim3(ceil(cols/BLOCK_SIZE_X),ceil(rows/BLOCK_SIZE_Y));

	checkCudaErrors(cudaMalloc((void **)&u8_GrayImage_Device,rows*cols*sizeof(u_int8_t)));
	checkCudaErrors(cudaMalloc((void **)&u32_Buffer0_Device,rows*cols*sizeof(u_int32_t)));

	checkCudaErrors(cudaMalloc((void **)&i32_BufferDx_Device,rows*cols*sizeof(int32_t)));
	checkCudaErrors(cudaMalloc((void **)&i32_BufferDy_Device,rows*cols*sizeof(int32_t)));

	checkCudaErrors(cudaMalloc((void **)&u32_SobelImage_Device,rows*cols*sizeof(u_int32_t)));
	checkCudaErrors(cudaMalloc((void **)&u32_BufferArea_Device,rows*cols*sizeof(u_int32_t)));

	checkCudaErrors(cudaMalloc((void **)&u32_Buffer5_Device,rows*cols*sizeof(u_int32_t)));
	checkCudaErrors(cudaMalloc((void **)&u32_BufferCornerList_Device,rows*cols*sizeof(u_int32_t)));

	checkCudaErrors(cudaMalloc((void**)&u8_extractedMarkers56p_Device,_MARKER_MAX_SIZE*_MARKER_MAX_SIZE*_MAX_NODE*sizeof(u_int8_t)));
	checkCudaErrors(cudaMalloc((void**)&u8_extractedMarkers7p_Device,_MARKER_SMALL_SIZE*_MARKER_SMALL_SIZE*_MAX_NODE*sizeof(u_int8_t)));

	checkCudaErrors(cudaMalloc((void**)&tranformationList_Device,_MAX_NODE*sizeof(TransformationM)));
	checkCudaErrors(cudaMalloc((void**)&u8_MarkerListToSearch5p_Device,1024*5*5*sizeof(u_int8_t)));

	checkCudaErrors(cudaMalloc((void**)&u16_DetectedId_Device,_MAX_NODE*sizeof(u_int16_t)));
	checkCudaErrors(cudaMalloc((void**)&f2_SquareList_Device,4*_MAX_NODE*sizeof(float2)));

	checkCudaErrors(cudaMalloc((void**)&f_tmp_AMatrix_Device,_MAX_NODE*8*8*sizeof(float)));


	/////////////////////////////////
	//    To Do: use cudaHostAlloc
	u32_BufferCornerList_Host   = (u_int32_t*)malloc(rows*cols*sizeof(u_int32_t));
	u8_extractedMarkers56p_Host = (u_int8_t *)malloc(_MARKER_MAX_SIZE*_MARKER_MAX_SIZE*_MAX_NODE*sizeof(u_int8_t));

	u8_extractedMarkers7p_Host  = (u_int8_t *)malloc(_MARKER_SMALL_SIZE*_MARKER_SMALL_SIZE*_MAX_NODE*sizeof(u_int8_t));
	tranformationList_Host      = (TransformationM *)malloc(_MAX_NODE*sizeof(TransformationM));

	u8_MarkerListToSearch5p_Host= (u_int8_t *)malloc(1024*5*5*sizeof(u_int8_t));
	u16_DetectedId_Host         = (u_int16_t*)malloc(_MAX_NODE*sizeof(u_int16_t));
	f2_SquareList_Host          = (float2*)malloc(4*_MAX_NODE*sizeof(float2));


	// Create the list of 1024 markers
	createMarkerList();



//	Image_Gray.filterMode = cudaFilterModeLinear;
//	Image_Gray.normalized = false;
//	cudaChannelFormatDesc  desc = cudaCreateChannelDesc<unsigned char>();
//	checkCudaErrors(cudaBindTexture2D(0,&Image_Gray,u8_GrayImage_Device, &desc, icols , irows, icols));




	cudaEventCreate(&Start,0);
	cudaEventCreate(&Stop,0);

	//pFile = fopen ("myfile.csv","a");
	LOGD("SOBEL;CCL;Blobs;Corners;CornersGPU;Refine;ExtractMarker;DetectId\n");


}

/////////////////////////////////////
/// \brief MarkerDetector_gpu::~MarkerDetector_gpu
///
MarkerDetector_gpu::~MarkerDetector_gpu()
{
	// free device memory
	checkCudaErrors(cudaFree(u8_GrayImage_Device));
	checkCudaErrors(cudaFree(u32_Buffer0_Device));
	checkCudaErrors(cudaFree(i32_BufferDx_Device));
	checkCudaErrors(cudaFree(i32_BufferDy_Device));
	checkCudaErrors(cudaFree(u32_SobelImage_Device));
	checkCudaErrors(cudaFree(u32_BufferArea_Device));
	checkCudaErrors(cudaFree(u32_Buffer5_Device));
	checkCudaErrors(cudaFree(u32_BufferCornerList_Device));
	checkCudaErrors(cudaFree(u8_extractedMarkers56p_Device));
	checkCudaErrors(cudaFree(u8_extractedMarkers7p_Device));
	checkCudaErrors(cudaFree(u8_MarkerListToSearch5p_Host));
	checkCudaErrors(cudaFree(tranformationList_Device));

}






/////////////////////////////////
/// \brief MarkerDetector_gpu::processSobel
///
void MarkerDetector_gpu::processSobel(void)
{

	if(VERBOSE)
		std::cout << "- Process sobel filter " << std::endl;


	cudaEventRecord(Start,0);
	Pass0_0<<<blocks,threads>>>(u8_GrayImage_Device,
			i32_BufferDx_Device,
			i32_BufferDy_Device,
			u32_SobelImage_Device,
			icols,irows);


	Pass0_1<<<blocks,threads>>>(i32_BufferDx_Device,
			i32_BufferDy_Device,
			u32_SobelImage_Device,
			icols,irows);


	Pass0_2<<<blocks,threads>>>(u32_SobelImage_Device,
			u32_Buffer0_Device,
			icols,irows);


	cudaEventRecord(Stop, 0);
	cudaEventSynchronize(Start);
	cudaEventSynchronize(Stop);
	cudaEventElapsedTime(&dt_ms[0], Start, Stop);

#if DEBUGG == 12
		cv::Mat gray_Label,adjMap_Label;
gray_Label.create(480,640,CV_32S);
double min,max;

checkCudaErrors(cudaMemcpy(gray_Label.data ,u32_Buffer0_Device,icols*irows*sizeof(u_int32_t) ,cudaMemcpyDeviceToHost));

cv::minMaxIdx(gray_Label, &min, &max);
cv::convertScaleAbs(gray_Label, adjMap_Label, 255 / max);
cv::imshow("gray_Label", adjMap_Label);
cv::waitKey(-1);
#endif

}


///////////////////////
/// \brief MarkerDetector_gpu::run
/// \param ptSrcHost
/// \param rows
/// \param cols
/// \param ipass
///
char * MarkerDetector_gpu::run(u_int8_t *ptSrcHost,int rows,int cols,int ipass)
{
	////////////////////////////
	// Clean all buffers
	std::cout << "- Clean buffers " << std::endl;
	Pass0_clean<<<blocks,threads>>>( i32_BufferDx_Device,
			i32_BufferDy_Device,
			u32_SobelImage_Device,
			u32_Buffer0_Device,
			u32_BufferArea_Device,
			u32_Buffer5_Device,
			u32_BufferCornerList_Device,
			icols,irows);

	///////////////////////////////////
	// Copy to the device memory
	std::cout << "- Copy to the device memory " << std::endl;
	checkCudaErrors(cudaMemcpy(u8_GrayImage_Device,ptSrcHost,rows*cols*sizeof(u_int8_t),cudaMemcpyHostToDevice));


	///////////////////////////////////////
	// Process sobel filter
	processSobel();



	 LOGD( "%.5f;%.5f;%.5f;%.5f;%.5f;%.5f;%.5f;%.5f;%d\n", dt_ms[0], dt_ms[1], dt_ms[2], dt_ms[3], dt_ms[4], dt_ms[5], dt_ms[6], dt_ms[7],SquareList.size());



	int cx = snprintf(bufferToDisplay, 500, "SOBEL CCL %.5f\nBlobs %.5f\nCorners %.5f\nCornersGPU %.5f\nRefine %.5f\nExtractMarker %.5f\nDetectId %.5f\n ID detected:", dt_ms[0], dt_ms[1], dt_ms[2], dt_ms[3], dt_ms[4], dt_ms[5], dt_ms[6], dt_ms[7] );

	for(int ind=0;ind<u16_MaxFeatureToProcess;ind++)
	{
		if(u16_DetectedId_Host[ind] != _MARKER_ID_INVALID )
		{
			cx = snprintf(bufferToDisplay +cx, 500, " %d ", SquareList[ind].GetID());
		}

	}

	return bufferToDisplay;
}
