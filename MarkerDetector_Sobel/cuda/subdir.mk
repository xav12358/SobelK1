
OBJS += \
./cuda/markerdetector.o
#sobelStream.o\
#./src/node.o \
#./src/marker.o\
#./camera/camera.o\
#./math/interpolation_func.o\
#./cuda/cleanBuffers.o\
#./cuda/extractCorners.o\
#./cuda/extractMarkers.o\
#./cuda/matchmarkers.o\
#./cuda/processBlobs.o\
#./cuda/processCCL.o\
#./cuda/processCorner.o\
#./cuda/processHomography.o\
#./cuda/processRefine.o\
#./cuda/processSobel.o



%.o: %.cu
	$(NVCC) $(CFLAGS) $(EXTRA_CFLAGS) -c -o "$@" "$<"
	
%.o: %.cpp
	$(NVCC) $(CFLAGS) $(EXTRA_CFLAGS) -c -o "$@" "$<"
