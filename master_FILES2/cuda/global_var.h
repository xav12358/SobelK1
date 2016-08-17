#ifndef GLOBAL_HH
#define GLOBAL_HH

#pragma once

#define DEBUGG  1
#define VERBOSE 1

#define LEVELS 3

#define BLOCK_SIZE_X 32
#define BLOCK_SIZE_Y 32

#define SHIFT 10
#define COEF  5

#define _MAX_NODE 128

#define _MARKER_MAX_SIZE    56
#define _MARKER_SMALL_SIZE  7

#define _MARKER_ID_INVALID 6666
#define _SHIFT_MARKER   10

#include <cuda.h>
#include <cuda_runtime.h>
#include <stdio.h>

// This will output the proper CUDA error strings in the event that a CUDA host call returns an error
#define checkCudaErrors(err)           __checkCudaErrors (err, __FILE__, __LINE__)

inline void __checkCudaErrors(cudaError err, const char *file, const int line)
{
    if (cudaSuccess != err)
    {
        printf( "%s(%i) : CUDA Runtime API error %d: %s.\n", file, line, (int)err, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}



#endif // GLOBAL_HH

