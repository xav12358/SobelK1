#ifndef _MARKER_DETECT
#define _MARKER_DETECT

#include <android/log.h>
#include <android/bitmap.h>
#include <jni.h>

#include <math.h>
#include <stdio.h>

void yuv2rgb(uint32_t *bitmapContent,u_int8_t *pSource,int height,int width);

#endif
