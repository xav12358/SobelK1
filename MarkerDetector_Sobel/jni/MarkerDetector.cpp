#include "MarkerDetector.h"
#include "Utils.h"


#include "cuda/markerdetector.h"

#define APP_NAME "native_basic"

#define LOGD(...) ((void)__android_log_print(ANDROID_LOG_DEBUG,  \
		APP_NAME, \
		__VA_ARGS__))
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO,  \
		APP_NAME, \
		__VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN,  \
		APP_NAME, \
		__VA_ARGS__))


MarkerDetector_gpu *MarkerDetecter;
u_int8_t Data[640*480];

JNIEXPORT jstring JNICALL processMarker(JNIEnv * pEnv, jclass pClass, jobject pTarget,jbyteArray pSource) {


	// Retrieves bitmap information and locks it for drawing.
	AndroidBitmapInfo bitmapInfo;
	uint32_t* bitmapContent;
	if (AndroidBitmap_getInfo(pEnv,pTarget, &bitmapInfo) < 0) abort();
	//	if (bitmapInfo.format != ANDROID_BITMAP_FORMAT_RGBA_8888) abort();
	if (AndroidBitmap_lockPixels(pEnv, pTarget,
			(void**)&bitmapContent) < 0) abort();

	jbyte* source = (jbyte*)(pEnv)->GetPrimitiveArrayCritical(pSource, 0);
	if (source == NULL) abort();

	LOGW("processMarker\n");
	yuv2rgb(bitmapContent,(u_int8_t*)source,480,640);

	char * returnVal = MarkerDetecter->run((u_int8_t*)source,480,640,10);
	returnVal[200] = '\0';
//	char msg[60] = "Hello ";


	// Unlocks the bitmap and releases the Java array when finished.
	pEnv-> ReleasePrimitiveArrayCritical(pSource,source, 0);
	if (AndroidBitmap_unlockPixels(pEnv, pTarget) < 0) abort();

	jstring result;
	result = pEnv->NewStringUTF(returnVal);

	return result;
}


void yuv2rgb(uint32_t *bitmapContent,u_int8_t *pSource,int height,int width)
{

	int32_t frameSize = 640*480;

	int32_t colorY, colorU, colorV;
	int32_t colorR, colorG, colorB;
	int32_t y1;

	int im_offset = width*height;
	u_int8_t *pOut = (u_int8_t *)bitmapContent;
	for (int y = 0;y < height; y++) {
		for (int x = 0; x < width;x++) {

			int inIdx= y*width+x;
			int uvIdx= im_offset + (y/2)*width + (x & ~1);
			int shlx = x/2;
			int shly = y/2;

			int yvalue   = (int)pSource[inIdx];
			int vvalue   = (int)pSource[uvIdx+0];
			int uvalue   = (int)pSource[uvIdx+1];

			int tmp = (0.403936*(uvalue-128)+0.838316*(vvalue-128)+(yvalue-16));
			pOut[inIdx] = fmax(fmin(255,tmp),0);
		}
	}


}






static JNINativeMethod gMethodRegistry[] = {
		{ "processMarker", "(Landroid/graphics/Bitmap;[B)Ljava/lang/String;", (void *) processMarker }
};
static int gMethodRegistrySize = sizeof(gMethodRegistry)
                            										   / sizeof(gMethodRegistry[0]);

JNIEXPORT jint JNI_OnLoad(JavaVM* pVM, void* reserved) {
	JNIEnv *env;
	if (pVM->GetEnv( (void**) &env, JNI_VERSION_1_6) != JNI_OK)
	{
	}

	jclass MainActivity = env->FindClass("com/markerdetector/MainActivity");

	env->RegisterNatives( MainActivity, gMethodRegistry, 1);
	env->DeleteLocalRef(MainActivity);

	LOGI("JNI_Constructor");
	int width =640;
	int height = 480;

	MarkerDetecter = new MarkerDetector_gpu(480,640);


	LOGI("JNI_OnLoad");

	return JNI_VERSION_1_6;
}
