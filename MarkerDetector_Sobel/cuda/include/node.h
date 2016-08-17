#ifndef NODE_H
#define NODE_H

#include <stdint.h>
#include <vector>


#include "/home/xavier/Bureau/Developpement/CCL_gpu/CCL_gpu2/include/Eigen/Dense"
#include "/home/xavier/workspace/MarkerDetector/cuda/cuda/global_var.h"

//class Point2d{
//    uint32_t x,y;

//public:
//    Point2d(uint32_t x,uint32_t y)
//    {
//        this->x = x;
//        this->y = y;
//    }

//    Point2d()
//    {
//        this->x = 0;
//        this->y = 0;
//    }

//    void setX(uint32_t x)
//    {
//        this->x = x;
//    }

//    void setY(uint32_t y)
//    {
//        this->y = y;
//    }

//    uint32_t getX()
//    {
//        return x;
//    }

//    uint32_t getY()
//    {
//        return y;
//    }

//};


class Node
{


public:
    Eigen::Vector2f ul, lr;
    std::vector<Eigen::Vector2f> PointList;
    float f_area;

    Node(std::vector<Eigen::Vector2f> vt, Eigen::Vector2f ul, Eigen::Vector2f lr);

    Node()
    {}
};

#endif // NODE_H
