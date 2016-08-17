#ifndef EIGEN_FUNC_H
#define EIGEN_FUNC_H


#include <include/Eigen/Dense>

Eigen::Matrix4f exp(const Eigen::VectorXf& mu);
void            rodrigues_so3_exp(const Eigen::Vector3f w, const float A, const float B, Eigen::Matrix3f &R);

#endif // EIGEN_FUNC_H
