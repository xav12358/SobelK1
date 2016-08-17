

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "sobelStream.h"

//#include "helper_math.h"
#include <android/log.h>

#define APP_NAME "CUDA_CORE"

#define LOGD(...) ((void)__android_log_print(ANDROID_LOG_DEBUG,  \
                                             APP_NAME, \
                                             __VA_ARGS__))



#define checkCudaErrors(err)           __checkCudaErrors (err, __FILE__, __LINE__)

inline void __checkCudaErrors(cudaError err, const char *file, const int line)
{
    if (cudaSuccess != err)
    {
        LOGD("CUDA Runtime API error: %s", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

// This will output the proper error string when calling cudaGetLastError
#define getLastCudaError(msg)      __getLastCudaError (msg, __FILE__, __LINE__)

inline void __getLastCudaError(const char *errorMessage, const char *file, const int line)
{
    cudaError_t err = cudaGetLastError();

    if (cudaSuccess != err)
    {
        LOGD("CUDA error %s:%s", errorMessage, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}


#define WIDTH   640
#define HEIGHT  480
#define NB_STREAM 10

#define BLOC_X 32
#define BLOC_Y 32

cudaStream_t *Stream;

cudaArray * Array_PatchsMaxDevice;
texture<u_int8_t, 2,cudaReadModeElementType> Image;


__global__ void SobelKernelSTREAM(u_int8_t *ptDataIn ,u_int8_t *ptDataOut,int hoffset,int widthToProcess,int heightToProcess)
{

    __shared__ u_int8_t localImage[WIDTH*HEIGHT/10];
    int x = blockIdx.x*blockDim.x;
    int y = blockIdx.y*blockDim.y;


    for(int i=threadIdx.x;i<widthToProcess;i+=blockDim.x)
    {
        for(int j=threadIdx.y;j<heightToProcess;j+=blockDim.y)
        {
            localImage[i+j*WIDTH] = ptDataIn[i +(j+hoffset)*WIDTH];
        }

    }

    syncthreads();

    int indiceKernelx[8] = {-1,0,1,1,1,0,-1,-1};
    int indiceKernely[8] = {-1,-1,-1,0,1,1,1,0};

    int indiceKernelWeightX[8] = {-1,0,1,2,1,0,-1,-2};
    int indiceKernelWeightY[8] = {-1,-2,-1,0,1,2,1,0};

    int x0,y0,c;
    int xout,yout;
    for(int i=threadIdx.x;i<widthToProcess;i+=blockDim.x)
    {
        for(int j=threadIdx.y;j<heightToProcess;j+=blockDim.y)
        {
            bool isValid = true;
            for(int k=0;k<8;k++)
            {

                x0 = indiceKernelx[k]+1;
                y0 = indiceKernely[k]+1;
                if(x0<0 || y0<0 || x0<widthToProcess || y0>heightToProcess)
                    break;
                c =  localImage[i+x0 +(j+y0)*WIDTH];

                xout += c*indiceKernelWeightX[k];
                yout += c*indiceKernelWeightY[k];
            }
            if(!isValid)
                continue;
            ptDataOut[i+(j+hoffset)*WIDTH] = xout*xout;//sqrt(xout*xout+yout*yout) ;
        }
    }
}

#define BLOCK_SIZE_X 32
#define BLOCK_SIZE_Y 32

__global__ void SobelKernel(u_int8_t *ptDataIn ,u_int8_t *ptDataOut,int w,int h)
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


    int xout =0;
    int yout =0;
    int c = 0;
    int x0 = 0,y0 = 0;


    for(int i=threadIdx.x;i<(BLOCK_SIZE_X+2) && (x+i)<w;i=i+blockDim.x)
    {
        for(int j=threadIdx.y;j<(BLOCK_SIZE_Y+2) && (y+j)<h;j=j+blockDim.y)
        {
            if((x+i)<0 || (y+j)<0) continue;
            LocalMem[i+j*(BLOCK_SIZE_Y+2)] = ptDataIn[x+i + (y+ j)*w];
        }
    }


    if(xglobal < 1 || xglobal >= 640-1 || yglobal < 1 || yglobal >= 480-1)
    {
        ptDataOut[xglobal+yglobal*w] = 0;
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

    ptDataOut[xglobal+yglobal*w]       = xout*xout + yout*yout;


}

__global__ void ClearKernel(u_int8_t *ptDataOut,int w,int h)
{


    int x = blockIdx.x*blockDim.x;
    int y = blockIdx.y*blockDim.y;

    int xglobal = x + threadIdx.x;
    int yglobal = y + threadIdx.y;


    if(xglobal>=w || yglobal >= h  )
        return;


    ptDataOut[xglobal +yglobal*WIDTH] = 0;

}



void processFilter(void)
{

    u_int8_t *u8_PtImageHost;
    u_int8_t *u8_PtImageDevice;

    u_int8_t *u8_ptDataOutHost;
    u_int8_t *u8_ptDataOutDevice;

    u_int8_t u8_Used[NB_STREAM];

    //    u8_ptDataOutHost = (u_int8_t *)malloc(WIDTH*HEIGHT*sizeof(u_int8_t));
    //    u8_PtImageHost = (u_int8_t *)malloc(WIDTH*HEIGHT*sizeof(u_int8_t));

    checkCudaErrors(cudaHostAlloc((void**)&u8_ptDataOutHost,WIDTH*HEIGHT*sizeof(u_int8_t),cudaHostAllocDefault));
    checkCudaErrors(cudaHostAlloc((void**)&u8_PtImageHost,WIDTH*HEIGHT*sizeof(u_int8_t),cudaHostAllocDefault));


    checkCudaErrors(cudaMalloc((void**)&u8_ptDataOutDevice,WIDTH*HEIGHT*sizeof(u_int8_t)));
    checkCudaErrors(cudaMalloc((void**)&u8_PtImageDevice,WIDTH*HEIGHT*sizeof(u_int8_t)));

    cudaChannelFormatDesc channelDesc = cudaCreateChannelDesc<unsigned char>();
    checkCudaErrors(cudaMallocArray(&Array_PatchsMaxDevice, &channelDesc,WIDTH,HEIGHT ));
    checkCudaErrors(cudaBindTextureToArray(Image,Array_PatchsMaxDevice));


    dim3 threads(BLOC_X,BLOC_Y);
    dim3 blocks(1,1);
    //    ClearKernel<<<blocks,threads>>>(u8_ptDataOutDevice,WIDTH,HEIGHT);


    int blockh = HEIGHT/NB_STREAM;


    Stream = (cudaStream_t *) malloc(NB_STREAM * sizeof(cudaStream_t));

    for (int i = 0; i < NB_STREAM; i++)
    {
        checkCudaErrors(cudaStreamCreate(&(Stream[i])));
    }

    int eventflags = cudaEventDefault;

    cudaEvent_t Start;
    cudaEvent_t Stop;
    checkCudaErrors(cudaEventCreateWithFlags(&Start, eventflags));
    checkCudaErrors(cudaEventCreateWithFlags(&Stop, eventflags));

    cudaEventRecord(Start, 0);

    /////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////
    for(int i=0;i<NB_STREAM;i++)
    {
        if(i == 0)
        {
            int localHeight  = blockh;
            checkCudaErrors(cudaMemcpyAsync(u8_PtImageHost,u8_PtImageDevice,WIDTH*(localHeight-1),cudaMemcpyHostToDevice,Stream[i]));
            SobelKernelSTREAM<<<blocks,threads,0,Stream[i]>>>(u8_PtImageDevice,u8_ptDataOutDevice,0,WIDTH,localHeight-1);
            checkCudaErrors(cudaMemcpyAsync(u8_ptDataOutHost,u8_ptDataOutDevice,WIDTH*(localHeight-1)*sizeof(u_int8_t),cudaMemcpyDeviceToHost,Stream[i]));

            u8_Used[i] = 1;

        }else{

            int ioffsetImage =  WIDTH*(HEIGHT/NB_STREAM  );
            int hoffset = HEIGHT/NB_STREAM *i;
            int hoffsetkernel = HEIGHT/NB_STREAM -1 + HEIGHT/NB_STREAM* (i-1);
            int localHeight  = min(HEIGHT - (blockh*i),blockh);

            printf("hoffset %d localHeight %d\n",hoffset,localHeight);
            checkCudaErrors(cudaMemcpyAsync(&u8_PtImageHost[hoffset*WIDTH],&u8_PtImageDevice[hoffset*WIDTH],WIDTH*(localHeight-1),cudaMemcpyHostToDevice,Stream[i]));
            SobelKernelSTREAM<<<blocks,threads,0,Stream[i]>>>(u8_PtImageDevice,u8_ptDataOutDevice,hoffset,WIDTH,localHeight);
            checkCudaErrors(cudaGetLastError());
            checkCudaErrors(cudaMemcpyAsync(&u8_ptDataOutHost[hoffsetkernel*WIDTH],&u8_ptDataOutDevice[hoffsetkernel*WIDTH],WIDTH*localHeight*sizeof(u_int8_t),cudaMemcpyDeviceToHost,Stream[i]));

            u8_Used[i] = 1;
            if(HEIGHT - (blockh +1 +blockh*(i-1))<=0)
            {
                break;
            }
        }
    }

    float dt_msK;
    cudaEventRecord(Stop, 0);
    cudaEventSynchronize(Start);
    cudaEventSynchronize(Stop);
    cudaEventElapsedTime(&dt_msK, Start, Stop);

//    LOGD("WITH STREAM dt_ms %f \n",dt_ms);

    /////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////

    float dt_ms[3];

    dim3 threadsK(BLOCK_SIZE_X,BLOCK_SIZE_Y);
    dim3 blocksK(ceil((float)WIDTH/BLOC_X),ceil((float)HEIGHT/BLOC_Y));

    cudaEventRecord(Start, 0);
    checkCudaErrors(cudaMemcpy(u8_PtImageHost,u8_PtImageDevice,WIDTH*HEIGHT,cudaMemcpyHostToDevice));
    cudaEventRecord(Stop, 0);
    cudaEventSynchronize(Start);
    cudaEventSynchronize(Stop);
    cudaEventElapsedTime(&dt_ms[0], Start, Stop);


    cudaEventRecord(Start, 0);
    SobelKernel<<<blocksK,threadsK>>>(u8_PtImageDevice,u8_ptDataOutDevice,WIDTH,HEIGHT);
    cudaEventRecord(Stop, 0);
    cudaEventSynchronize(Start);
    cudaEventSynchronize(Stop);
    cudaEventElapsedTime(&dt_ms[1], Start, Stop);

    cudaEventRecord(Start, 0);
    checkCudaErrors(cudaMemcpy(u8_ptDataOutHost,u8_ptDataOutDevice,WIDTH*(HEIGHT)*sizeof(u_int8_t),cudaMemcpyDeviceToHost));
    cudaEventRecord(Stop, 0);
    cudaEventSynchronize(Start);
    cudaEventSynchronize(Stop);
    cudaEventElapsedTime(&dt_ms[2], Start, Stop);

    LOGD("dt;%f;%f;%f\n",dt_ms[0],dt_ms[1],dt_ms[2]);

}

