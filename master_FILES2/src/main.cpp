#include <iostream>
using namespace std;

#include "cuda/markerdetector.h"

#include <opencv/cv.h>
#include <opencv/highgui.h>



int main()
{



    cv::VideoCapture cap("/home/ubuntu/Desktop/master_FILES/Sequence11"); // open the default camera
    if(!cap.isOpened())  // check if we succeeded
        return -1;

    cv::Mat imageColor;
    cv::Mat imageGray;
    cv::Mat imageGraySized;
    imageGraySized.create(480,640,CV_8U);

    MarkerDetector_gpu *MarkerDetecter = new MarkerDetector_gpu(480,640);
    int indice = 0;
    while(indice<500)
    {
        cap >> imageColor;
        cv::cvtColor(imageColor,imageGray,CV_RGB2GRAY);
        cv::resize(imageGray,imageGraySized,imageGraySized.size());

//        Cam->FillMat(imageGray);
        //std::cout << "imageGray.rows " << imageGraySized.rows << " imageGray.cols " << imageGraySized.cols << std::endl;
        indice++;
        if(indice <25)
            continue;
        //cv::imshow("Original gray",imageGray);
        //cv::waitKey(10);
        MarkerDetecter->run(imageGraySized.data,480,640,10);
    }


    return 0;
}

