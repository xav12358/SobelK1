#ifndef MARKERDETECTOR_H
#define MARKERDETECTOR_H

#include <cuda.h>
#include <cuda_runtime.h>
#include <stdio.h>

#include "global_var.h"
#include "include/node.h"
#include "include/Eigen/Dense"


#include "camera/camera.h"
#include "include/marker.h"



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

    TransformationM * tranformationList_Device;     ///< List of homography caculate in the CPU
    u_int8_t    *u8_extractedMarkers56p_Device;     ///< Store the 56x56 markers
    u_int8_t    *u8_extractedMarkers7p_Device;      ///< Store the 7x7 markers
    uint8_t     *u8_MarkerListToSearch5p_Device;    ///< List of 5x5 marker to search in image
    u_int16_t   *u16_DetectedId_Device;             ///< List of detected Id
    float2      *f2_SquareList_Device;              ///< Store the list of Square detected

    float       *f_tmp_AMatrix_Device;              ///< Tmp variable to process homography in kernel


    ////////////////////////////////////////////////
    //////////////////// In the HOST   /////////////
    u_int32_t   *u32_BufferCornerList_Host;     ///< Store the list of extremum corners
    u_int32_t   u32_NbPotentialSquare_Host;     ///< Store the number of potential square in the image
    u_int32_t   u32_NbSquare_Host;              ///< Store the
    float2      *f2_SquareList_Host;            ///< Store the list of Square detected

    TransformationM * tranformationList_Host;   ///<List of homography caculate in the CPU
    u_int8_t    *u8_extractedMarkers56p_Host;   ///< Store the 56x56 markers
    u_int8_t    *u8_extractedMarkers7p_Host;    ///< Store the 7x7 markers
    uint8_t     *u8_MarkerListToSearch5p_Host;  ///< List of 5x5 marker to search in image
    u_int16_t   *u16_DetectedId_Host;           ///< List of detected Id


    u_int16_t   u16_MaxFeatureToProcess;
    int irows,icols;                            ///< size of image

    std::vector <Node> NodeListPotentialSquare; ///< Liste of potential marker
    std::vector <Marker> SquareList;      ///< Liste of effective marker
    TangentialModel *Camera;                    ///< Tangential model for the camera


    float dt_ms[8];
    FILE *pFile;

    cudaEvent_t Start;
    cudaEvent_t Stop;

public:
    MarkerDetector_gpu(int rows, int cols);
    ~MarkerDetector_gpu(); 

    void createMarkerList(void);

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

    char * run(u_int8_t *ptSrcHost, int rows, int cols, int ipass);


    void findMarker();


};

#endif // MARKERDETECTOR_H
