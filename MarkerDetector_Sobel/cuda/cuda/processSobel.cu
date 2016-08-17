#include <cuda.h>
#include <cuda_runtime.h>
#include <stdio.h>

#include "global_var.h"

__global__ void Pass0_0(u_int8_t *u8_GrayImageIn,
                        int32_t *ptBufferDxOut,
                        int32_t *ptBufferDyOut,
                        u_int32_t *ptSobelOut,
                        int w,int h)
{

    int indiceKernelx[8] = {-1,0,1,1,1,0,-1,-1};
    int indiceKernely[8] = {-1,-1,-1,0,1,1,1,0};

    int indiceKernelWeightX[8] = {-1,0,1,2,1,0,-1,-2};
    int indiceKernelWeightY[8] = {-1,-2,-1,0,1,2,1,0};

    __shared__ u_int8_t  LocalMem[(BLOCK_SIZE_X+2)*(BLOCK_SIZE_Y+2)];

    int x = blockIdx.x*blockDim.x;
    int y = blockIdx.y*blockDim.y;
    int xglobal = x+threadIdx.x;
    int yglobal = y+threadIdx.y;
    int xlocal  = threadIdx.x;
    int ylocal  = threadIdx.y;

    int xout =0;
    int yout =0;
    int c = 0;
    int x0 = 0,y0 = 0;


    for(int i=threadIdx.x;i<(BLOCK_SIZE_X+2) && (x+i)<w;i=i+blockDim.x)
    {
        for(int j=threadIdx.y;j<(BLOCK_SIZE_Y+2) && (y+j)<h;j=j+blockDim.y)
        {
            if((x+i)<0 || (y+j)<0) continue;
            LocalMem[i+j*(BLOCK_SIZE_Y+2)] = u8_GrayImageIn[x+i + (y+ j)*w];
        }
    }


    if(xglobal < 1 || xglobal >= 640-1 || yglobal < 1 || yglobal >= 480-1)
    {
        ptBufferDxOut[xglobal+yglobal*w] = -1;
        ptBufferDyOut[xglobal+yglobal*w] = -1;
        ptSobelOut[xglobal+yglobal*w] = 0;
        return;
    }


    syncthreads();

    for(int i=0;i<8;i++)
    {
        x0 = indiceKernelx[i]+1;
        y0 = indiceKernely[i]+1;
        c =  LocalMem[threadIdx.x+x0 +(threadIdx.y+y0)*(BLOCK_SIZE_Y+2)];

        xout += c*indiceKernelWeightX[i];
        yout += c*indiceKernelWeightY[i];
    }

    ptBufferDxOut[xglobal+yglobal*w]    = xout;
    ptBufferDyOut[xglobal+yglobal*w]    = yout;
    ptSobelOut[xglobal+yglobal*w]       = xout*xout + yout*yout;

}


__global__ void Pass0_1(int32_t *ptBufferDxIn,
                        int32_t *ptBufferDyIn,
                        u_int32_t *ptSobelOut,
                        int w,int h)
{
    __shared__ u_int32_t  LocalMemI[(BLOCK_SIZE_X+2)*(BLOCK_SIZE_Y+2)];
    __shared__ int32_t  LocalMemIx[(BLOCK_SIZE_X+2)*(BLOCK_SIZE_Y+2)];
    __shared__ int32_t  LocalMemIy[(BLOCK_SIZE_X+2)*(BLOCK_SIZE_Y+2)];

    int x = blockIdx.x*blockDim.x;
    int y = blockIdx.y*blockDim.y;
    int xglobal = x+threadIdx.x;
    int yglobal = y+threadIdx.y;
    int xlocal  = threadIdx.x;
    int ylocal  = threadIdx.y;

    for(int i=threadIdx.x;i<BLOCK_SIZE_X+2 && (x+i)<w;i=i+blockDim.x)
    {
        for(int j=threadIdx.y;j<BLOCK_SIZE_Y+2 && (y+j)<h;j=j+blockDim.y)
        {
            if((x+i)<0 || (y+j)<0) continue;
            LocalMemI[i+j*(BLOCK_SIZE_X+2)]  = ptSobelOut[x+i-1 + (y+j-1)*w];
            LocalMemIx[i+j*(BLOCK_SIZE_X+2)] = ptBufferDxIn[x+i-1 + (y+j-1)*w];
            LocalMemIy[i+j*(BLOCK_SIZE_X+2)] = ptBufferDyIn[x+i-1 + (y+j-1)*w];
        }
    }

    if(xglobal < 1 || xglobal >= 640-1 || yglobal < 1 || yglobal >= 480-1)
    {
        ptBufferDxIn[xglobal+yglobal*w] = -1;
        ptBufferDyIn[xglobal+yglobal*w] = -1;
        ptSobelOut[xglobal+yglobal*w] = -1;
        return;
    }


    syncthreads();

    int p0_local = (ylocal+1) * (BLOCK_SIZE_X+2) + xlocal+1;

    int x2 = 1, y2 = 1;
    int sx = LocalMemIx[p0_local], sy = LocalMemIy[p0_local];

    if (sx < 0) { sx = -sx; x2 = -1; }
    if (sy < 0) { sy = -sy; y2 = -1; }
    sx = max(sx, 1);

    if ((sy << 8) < 106 * sx) y2 = 0;
    if ((sy << 8) > 617 * sx) x2 = 0;

    int p1_local = ((ylocal+1 + y2) *(BLOCK_SIZE_X+2) ) + xlocal + x2 +1;
    int p2_local = ((ylocal+1 - y2) *(BLOCK_SIZE_X+2) ) + xlocal - x2 +1;
    int p3_local = ((ylocal+1 + y2) *(BLOCK_SIZE_X+2) ) + xlocal - x2 +1;
    int p4_local = ((ylocal+1 - y2) *(BLOCK_SIZE_X+2) ) + xlocal + x2 +1;

    int p0_global = (yglobal *w ) + xglobal;
    int p1_global = ((yglobal + y2) *w ) + xglobal + x2;
    int p2_global = ((yglobal - y2) *w ) + xglobal - x2;
    //    int p3_global = ((yglobal + y2) *w ) + xglobal - x2;
    //    int p4_global = ((yglobal - y2) *w ) + xglobal + x2;



    bool sn  = (LocalMemIx[p0_local] * LocalMemIx[p1_local] + LocalMemIy[p0_local] * LocalMemIy[p1_local]) > 0;
    bool ss  = (LocalMemIx[p0_local] * LocalMemIx[p2_local] + LocalMemIy[p0_local] * LocalMemIy[p2_local]) > 0;
    bool sew = (LocalMemIx[p3_local] * LocalMemIx[p4_local] + LocalMemIy[p3_local] * LocalMemIy[p4_local]) > 0;


    int m = 512;
    if (x2 != 0 && y2 != 0) m = 1024;
    if (!sn &&  ss & sew) m = 1024;
    if (            !sew) m = 1024;

    int m0 = LocalMemI[p0_local];
    int m1 = LocalMemI[p1_local];

    int m2 = LocalMemI[p2_local];
    int a0 = m0 * m;
    int a1 = m1 << 8;
    int a2 = m2 << 8;


    //ptBufferDxIn[p0_global] = p1_global;// p2_local>1156 | p2_local<0;//p1_global>307200;

    if (a1 > a0 && m1 >= m2) {

        atomicAdd(&ptSobelOut[p1_global], m0);
        atomicSub(&ptSobelOut[p0_global], m0);

    } else if (a2 > a0 && m2 >= m1) {

        atomicAdd(&ptSobelOut[p2_global], m0);
        atomicSub(&ptSobelOut[p0_global], m0);
    }

}


__global__ void Pass0_2(u_int32_t *ptSobelIn,
                        u_int32_t *ptLabelOut,
                        int w,int h)
{
    //__shared__ u_int32_t  LocalMemI[(BLOCK_SIZE_X+4)*(BLOCK_SIZE_Y+4)];

    int x = blockIdx.x*blockDim.x;
    int y = blockIdx.y*blockDim.y;
    int xglobal = x+threadIdx.x;
    int yglobal = y+threadIdx.y;
    int xlocal  = threadIdx.x;
    int ylocal  = threadIdx.y;


    /*for(int i=threadIdx.x  ;i<BLOCK_SIZE_X+4 && (x+i)<w;i=i+blockDim.x)
    {
        for(int j=threadIdx.y ;j<BLOCK_SIZE_Y+4 && (y+j)<h;j=j+blockDim.y)
        {
            if((x+i)<0 || (y+j)<0) continue;
            LocalMemI[i+j*(BLOCK_SIZE_X+4)]  = ptSobelIn[x+i-4 + (y+j-4)*w];
        }
    }

    syncthreads();
    */

    if(xglobal <= 4 || xglobal >= 640-4  || yglobal <= 4 || yglobal >= 480-4)
    {
        ptLabelOut[xglobal+yglobal*w] = 0;
        return;
    }

    int xglobal0 = xglobal;
    int yglobal0 = yglobal;
    int p_global  = xglobal+yglobal*w;
    int p_local  = xlocal+4+(ylocal+4)*(BLOCK_SIZE_X+4);
    int p0 = p_local, p1;


    //if (LocalMemI[p0] > 300000) {
    if (ptSobelIn [p_global] > 30000) {
        ptLabelOut[p_global] = p_global;
    }else
    {
        ptLabelOut[p_global] = 0;
    }

    return;


    /*
    if (LocalMemI[p0] < 3000) {
        ptLabelOut[p_global] = 0;
        return;
    }
    p1 = p0 - BLOCK_SIZE_Y+4;
    if (LocalMemI[p1] >= 3000) {
        p0 = p1;
        yglobal0--;
    }

    p1 = p0 - 1;
    if (LocalMemI[p1] >= 3000) {
        p0 = p1;
        xglobal0--;
    }

    p1 = p0 - BLOCK_SIZE_Y+4;
    if (LocalMemI[p1] >= 3000) {
        p0 = p1;
        yglobal0--;
    }

    p1 = p0 - 1;
    if (LocalMemI[p1] >= 3000) {
        p0 = p1;
        xglobal0--;
    }

    p1 = p0 - BLOCK_SIZE_Y+4;
    if (LocalMemI[p1] >= 3000) {
        p0 = p1;
        yglobal0--;
    }

    p1 = p0 - 1;
    if (LocalMemI[p1] >= 3000) {
        p0 = p1;
        xglobal0--;
    }

    p1 = p0 - BLOCK_SIZE_Y+4;
    if (LocalMemI[p1] >= 3000) {
        p0 = p1;
        yglobal0--;
    }

    p1 = p0 - 1;
    if (LocalMemI[p1] >= 3000) {
        p0 = p1;
        xglobal0--;
    }

    ptLabelOut[p_global] = xglobal0+yglobal0*w;
    */
}
