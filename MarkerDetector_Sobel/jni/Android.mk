LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := lib_sobelstream
LOCAL_SRC_FILES := ../cuda/lib_sobelstream.a
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
CUDA_TOOLKIT_ROOT :=/home/xavier/NVPACK/cuda-6.5
LOCAL_MODULE := libcudart_static
LOCAL_LIB_PATH   += $(CUDA_TOOLKIT_ROOT)/targets/armv7-linux-androideabi/lib/
LOCAL_SRC_FILES  := $(LOCAL_LIB_PATH)/libcudart_static.a 
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := MarkerDetector

RECURSIVE_GAUSSIAN_ROOT := $(LOCAL_PATH)/..

MY_PREFIX       := $(LOCAL_PATH)/
MY_SOURCES      := $(wildcard $(LOCAL_PATH)/*.cpp)
LOCAL_SRC_FILES := $(MY_SOURCES:$(MY_PREFIX)%=%)
 
LOCAL_STATIC_LIBRARIES := lib_sobelstream libcudart_static
LOCAL_STATIC_LIBRARIES += nv_and_util nv_egl_util nv_glesutil nv_shader nv_file
LOCAL_LDLIBS := -llog -landroid -ljnigraphics -lGLESv2 -lEGL 
LOCAL_C_INCLUDES += $(RECURSIVE_GAUSSIAN_ROOT)/cuda
LOCAL_C_INCLUDES += $(CUDA_TOOLKIT_ROOT)/targets/armv7-linux-androideabi/include
include $(BUILD_SHARED_LIBRARY)

$(call import-add-path, $(LOCAL_PATH)/../extra_libs/jni)

$(call import-module,nv_and_util)
$(call import-module,nv_egl_util)
$(call import-module,nv_shader)
$(call import-module,nv_file)
$(call import-module,nv_glesutil)
