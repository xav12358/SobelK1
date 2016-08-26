TEMPLATE = app
CONFIG += console
CONFIG -= app_bundle
CONFIG -= qt

SOURCES += \
    src/main.cpp

include(deployment.pri)
qtcAddDeployment()


# This makes the .cu files appear in your project
OTHER_FILES += 

HEADERS += \
    cuda/markerdetector.h \
    cuda/global_var.h \



#######################################################################################

CONFIG += link_pkgconfig
PKGCONFIG += opencv

#LIBS +=-lcv -lhighgui -lstdc++ -lcxcore -lcvaux


INCLUDEPATH += /usr/include/opencv
LIBS += -L/usr/local/lib
LIBS += -L/usr/lib/x86_64-linux-gnu
LIBS += -lm
LIBS += -lopencv_core
LIBS += -lopencv_imgproc
LIBS += -lopencv_highgui
LIBS += -lopencv_objdetect
LIBS += -lopencv_calib3d

#######################################################################################
LIBS += -L /usr/lib/x86_64-linux-gnu -lcuda -lcudart -lcublas -lcublas_device -lcudadevrt


# CUDA settings <-- may change depending on your system
CUDA_SOURCES += ./cuda/markerdetector.cu
CUDA_SDK = /usr/lib/nvidia-cuda-toolkit             #/usr/include/   # Path to cuda SDK install
CUDA_DIR = /usr/lib/nvidia-cuda-toolkit             # Path to cuda toolkit install

# DO NOT EDIT BEYOND THIS UNLESS YOU KNOW WHAT YOU ARE DOING....

SYSTEM_NAME = unix         # Depending on your system either 'Win32', 'x64', or 'Win64'
SYSTEM_TYPE = 64            # '32' or '64', depending on your system
CUDA_ARCH = sm_35           # Type of CUDA architecture, for example 'compute_10', 'compute_11', 'sm_10'
NVCC_OPTIONS = #--use_fast_math


# include paths
INCLUDEPATH += $$CUDA_DIR/include
INCLUDEPATH += ../CCL_gpu2
INCLUDEPATH += ../CCL_gpu2/cuda
INCLUDEPATH += ../CCL_gpu2/include


DISTFILES += \ 
    cuda/extractMarkers.cu \
    cuda/markerdetector.cu \


# library directories
QMAKE_LIBDIR += /usr/lib/x86_64-linux-gnu  #/usr/lib/nvidia-cuda-toolkit/lib #/usr/lib/i386-linux-gnu #$CUDA_DIR/lib/

CUDA_OBJECTS_DIR = ./

# Add the necessary libraries
NVCC_LIBS = -L/usr/lib/x86_64-linux-gnu  -lcuda -lcudart -lcublas -lcublas_device -lcudadevrt

# The following makes sure all path names (which often include spaces) are put between quotation marks
CUDA_INC = $$join(INCLUDEPATH,'" -I"','-I"','"')

## Configuration of the Cuda compiler
##CONFIG(debug, debug|release) {
##    # Debug mode
##    cuda_d.input = CUDA_SOURCES
##    cuda_d.output = $$CUDA_OBJECTS_DIR/${QMAKE_FILE_BASE}_cuda.o
##    cuda_d.commands = $$CUDA_DIR/bin/nvcc -D_DEBUG $$NVCC_OPTIONS $$CUDA_INC $$NVCC_LIBS --machine $$SYSTEM_TYPE -arch=$$CUDA_ARCH -c -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
##    cuda_d.dependency_type = TYPE_C
##    QMAKE_EXTRA_COMPILERS += cuda_d
##}
##else {
#    # Release mode
#    cuda.input = CUDA_SOURCES
#    cuda.output = $$CUDA_OBJECTS_DIR/${QMAKE_FILE_BASE}_cuda.o
#    cuda.commands = $$CUDA_DIR/bin/nvcc --compiler-options $$NVCC_OPTIONS $$CUDA_INC $$NVCC_LIBS --machine $$SYSTEM_TYPE -arch=$$CUDA_ARCH -c -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
#    cuda.dependency_type = TYPE_C
#    QMAKE_EXTRA_COMPILERS += cuda
##}

    # Release mode
    cuda.input = CUDA_SOURCES
    cuda.output = $$CUDA_OBJECTS_DIR/${QMAKE_FILE_BASE}_cuda.o
    cuda.commands = $$CUDA_DIR/bin/nvcc -ccbin g++  -dc  $$NVCC_OPTIONS $$CUDA_INC $$NVCC_LIBS --machine $$SYSTEM_TYPE -arch=$$CUDA_ARCH -c -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
    cuda.dependency_type = TYPE_C
    QMAKE_EXTRA_COMPILERS += cuda


    cudaLINK.input = CUDA_SOURCES
    cudaLINK.output = $$CUDA_OBJECTS_DIR/${TARGET}_cuda.o
    cudaLINK.commands = $$CUDA_DIR/bin/nvcc -ccbin g++ -dlink  $$NVCC_OPTIONS $$CUDA_INC $$NVCC_LIBS --machine $$SYSTEM_TYPE -arch=$$CUDA_ARCH markerdetector_cuda.o -o ${TARGET}_cuda.o
    QMAKE_EXTRA_COMPILERS += cudaLINK



LIBS += -L -lunicap -lucil
INCLUDEPATH += /usr/local/include/unicap
DEPENDPATH += /usr/local/include/unicap

INCLUDEPATH += /usr/include/glib-2.0/
DEPENDPATH += /usr/include/glib-2.0/


INCLUDEPATH += /usr/lib/x86_64-linux-gnu/glib-2.0/include
DEPENDPATH += /usr/lib/x86_64-linux-gnu/glib-2.0/include
