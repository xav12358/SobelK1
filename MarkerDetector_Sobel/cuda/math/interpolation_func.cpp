#include "interpolation_func.h"

#include <math.h>

float bilinearInterp(u_int8_t *ptSrc,float vx,float vy)
{
    float fQ11,fQ12,fQ21,fQ22;

    int ivx = floor(vx);
    int ivy = floor(vy);



    fQ11 = ptSrc[ivy*640+ivx];
    fQ12 = ptSrc[ivy*640+ivx+1];
    fQ21 = ptSrc[(ivy+1)*640+ivx];
    fQ22 = ptSrc[(ivx+1)*640+ivx+1];


    float deltay2 = vy - float(ivy);
    float deltay1 = 1- deltay2;


    float deltax2 = vx - float(ivx);
    float deltax1 = 1;

    //printf("dx %f dy %f ",deltax2,deltay2);
    float R1 = (deltax2)*fQ11+deltax1*fQ21;
    float R2 = (deltax2)*fQ12+deltax1*fQ22;

    //printf("val %f",(deltay2)*R1 + deltay1*R2);
    return fQ11;//  (deltay2)*R1 + deltay1*R2;
}
