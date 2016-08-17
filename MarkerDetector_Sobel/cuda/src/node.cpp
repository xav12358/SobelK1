#include "/home/xavier/workspace/MarkerDetector/cuda/include/node.h"

Node::Node(std::vector<Eigen::Vector2f> vt, Eigen::Vector2f ul, Eigen::Vector2f lr)
{
    this->ul = ul;
    this->lr = lr;
    this->PointList = vt;
}
