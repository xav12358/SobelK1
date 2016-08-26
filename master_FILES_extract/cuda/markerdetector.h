#ifndef MARKERDETECTOR_H
#define MARKERDETECTOR_H

#include <cuda.h>
#include <cuda_runtime.h>
#include <stdio.h>

#include "global_var.h"

#include <math_constants.h>


//typedef struct{
//    Eigen::Vector2f P[4];       ///< Position of the 4 corners
//    u_int16_t ID;               ///< ID of the marker
//    u_int8_t OrientationType;   ///< type of orientation
//    float markerSize;           ///< Size in meter

//    Eigen::Matrix3f R;
//    Eigen::Vector3f T;
//    Eigen::Matrix4f mse3MarkerfromC;
//}SquarePoints;


typedef struct{
    float Homography[9];
}TransformationM;

/////////////////////
/// \brief The MarkerDetector_gpu class
///
class MarkerDetector_gpu
{
    dim3 threads;
    dim3 blocks;

    ////////////////////////////////////////////////
    //////////////////// In the device   ///////////
    u_int8_t    *u8_GrayImage_Device;   ///< Store the gray image
    u_int32_t   *u32_Buffer0_Device;    ///< Store the labellised image
    int32_t     *i32_BufferDx_Device;   ///< Store the derivative x image
    int32_t     *i32_BufferDy_Device;   ///< Store the derivative y image
    u_int32_t   *u32_SobelImage_Device; ///< Store sobel image
    u_int32_t   *u32_BufferArea_Device;         ///< Store the area
    u_int32_t   *u32_Buffer5_Device;            ///< Store the value of location of min point label
    u_int32_t   *u32_BufferCornerList_Device;   ///< Store the list of corners
    u_int8_t    *u8_ptDynamicThreshold_Device; ///< Store the dynamic calculated threshold

    TransformationM * tranformationList_Device;     ///< List of homography caculate in the CPU
    u_int8_t    *u8_extractedMarkers56p_Device;     ///< Store the 56x56 markers
    u_int8_t    *u8_extractedMarkers7p_Device;      ///< Store the 7x7 markers
    u_int8_t     *u8_MarkerListToSearch5p_Device;    ///< List of 5x5 marker to search in image
    u_int16_t   *u16_DetectedId_Device;             ///< List of detected Id
    float2      *f2_SquareList_Device;              ///< Store the list of Square detected


    ////////////////////////////////////////////////
    //////////////////// In the HOST   /////////////
    u_int32_t   *u32_BufferCornerList_Host;     ///< Store the list of extremum corners
    u_int32_t   u32_NbPotentialSquare_Host;     ///< Store the number of potential square in the image
    u_int32_t   u32_NbSquare_Host;              ///< Store the
    float2      *f2_SquareList_Host;            ///< Store the list of Square detected

    TransformationM * tranformationList_Host;   ///<List of homography caculate in the CPU
    u_int8_t    *u8_extractedMarkers56p_Host;   ///< Store the 56x56 markers
    u_int8_t    *u8_extractedMarkers7p_Host;    ///< Store the 7x7 markers
    u_int8_t     *u8_MarkerListToSearch5p_Host;  ///< List of 5x5 marker to search in image
    u_int16_t   *u16_DetectedId_Host;           ///< List of detected Id
    u_int8_t    *u8_ptDynamicThreshold_Host;   ///< Store the dynamic calculated threshold



    u_int16_t   u16_MaxFeatureToProcess;
    int irows,icols;                            ///< size of image


    float dt_ms[8];
    cudaEvent_t Start;
    cudaEvent_t Stop;
    FILE *pFile;

    /////////////////////////////////////////////////
    /////////////////////////////////////////////////
    ///  CUBLAS library variables
    //////////////////// In the Device   /////////////
    float **d_AA, **d_AAInv, **d_BB, **d_CC,**d_CCInv;
    float **h_AA, **h_AAInv, **h_BB, **h_CC,**h_CCInv;
    float *d_Alpha,*d_Beta;
    float *h_Alpha,*h_Beta;
    int* dAUPivots;
    int* dAUInfo;

    //////////////////// In the HOST   /////////////

public:
    MarkerDetector_gpu(int rows, int cols);
    ~MarkerDetector_gpu(); 

    void copyImageToDevice(u_int8_t *ptSrcHost, int rows, int cols);
    void createMarkerList(void);
    void createCublasValue(void);
    void drawMarker(u_int8_t *ptSrc);
    void extractCorners(u_int8_t *ptSrcHost);
    void findMarkerCPU(void);
    void processBlobs(void);
    void processCCL(int ipass);
    void processCopyImage(void);
    void processCorners(u_int8_t *ptSrcHost);
    void processCornersGPU(u_int8_t *ptSrcHost);
    void processDetectId(void);
    void processExtractMarkers(u_int8_t *ptSrcHost);
    void processExtractMarkersGPU(u_int8_t *ptSrcHost);
    void processMarkerPosition(u_int8_t *ptSrcHost);
    void processRefineLine(u_int8_t *ptSrc, int iindiceSquare, int indiceP0, int indiceP1, int ithreshold);
    void processRefineSquare(u_int8_t *ptSrc,int iindice);
    void processRefineSubpixel(u_int8_t *ptSrc);
    void processRefineSubpixelGPU(u_int8_t *ptSrc);
    void processSobel(void);

    void run(u_int8_t *ptSrcHost, int rows, int cols, int ipass);

    void findMarker();

};

#endif // MARKERDETECTOR_H
