#include <cuda.h>
#include <cuda_runtime.h>
#include <stdio.h>


#include "global_var.h"
#include "markerdetector.h"

texture<unsigned char, 2,cudaReadModeNormalizedFloat> Image_Gray;


__global__ void ExtractMarker56p( u_int8_t *ptTemplateMarker)
{

    for(int i=threadIdx.x;i<_MARKER_MAX_SIZE;i+=blockDim.x)
    {
        for(int j=threadIdx.y;j<_MARKER_MAX_SIZE;j+=blockDim.y)
        {
            float x00 = (float)i;
            float y00 = (float)j;
                      u_int8_t u8_Val = 255* tex2D(Image_Gray,x00+0.5,y00+0.5);
            ptTemplateMarker[blockIdx.x*_MARKER_MAX_SIZE*_MARKER_MAX_SIZE + (i + j*_MARKER_MAX_SIZE) ] = u8_Val;
        }
    }

}



