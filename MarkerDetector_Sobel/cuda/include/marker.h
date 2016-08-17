#ifndef MARKER_H
#define MARKER_H

#include "include/Eigen/Dense"

#include <camera/camera.h>

class Marker
{
    u_int16_t ID;               ///< ID of the marker
    u_int8_t OrientationType;   ///< type of orientation
    float markerSize;           ///< Size in meter

    Eigen::Matrix3f R;
    Eigen::Vector3f T;
    Eigen::Matrix4f mse3MarkerfromC;


public:
    Eigen::Vector2f P[4];       ///< Position of the 4 corners


    Marker();
    void            extract3DPosition(Camera &Cam, int iiter =10);

    u_int16_t       GetID(){return ID;}
    float           GetMarkerSize(){return markerSize;}
    u_int8_t        GetOrientation(){return OrientationType;}
    Eigen::Vector2f GetP(int indice){return P[indice];}

    void SetID(u_int16_t IDD){ID = IDD;}
    void SetMarkerSize(float S){markerSize = S;}
    void SetOrientation(u_int8_t Ori){OrientationType = Ori;}

};

#endif // MARKER_H
