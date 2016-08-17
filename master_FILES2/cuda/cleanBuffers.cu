#include <cuda.h>
#include <cuda_runtime.h>
#include <stdio.h>

__global__ void Pass0_clean(int32_t *ptBufferDxOut,
                            int32_t *ptBufferDyOut,
                            u_int32_t *ptSobelOut,
                            u_int32_t *ptLabelOut,
                            u_int32_t *ptArea,
                            u_int32_t *ptOut,
                            u_int32_t *u32_BufferCornerList_Device,
                            int w,int h)
{


    int x = blockIdx.x*blockDim.x;
    int y = blockIdx.y*blockDim.y;
    int xglobal = x+threadIdx.x;
    int yglobal = y+threadIdx.y;

    if(xglobal>w || yglobal >h)
    {
        return;
    }

    ptBufferDxOut[xglobal+yglobal*w]    = 0;
    ptBufferDyOut[xglobal+yglobal*w]    = 0;
    ptSobelOut[xglobal+yglobal*w]       = 0;
    ptLabelOut[xglobal+yglobal*w]       = 0;
    ptArea[xglobal+yglobal*w]           = 0;
    ptOut[xglobal+yglobal*w]            = 0;
    u32_BufferCornerList_Device[xglobal+yglobal*w] = 0;
}
