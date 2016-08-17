#include "/home/ubuntu/Desktop/master_FILES/include/marker.h"
#include "math/eigen_func.h"

#include "/home/ubuntu/Desktop/master_FILES/cuda/global_var.h"



#include <iostream>
#include <math.h>
#include <string>
#include <stdio.h>
#include <stdlib.h>



Marker::Marker()
{

}


//////////////////////////////////////
/// \brief Marker::extract3DPosition
/// \param Cam
/// \param iiter
///
void Marker::extract3DPosition(Camera & Cam,int iiter)
{

    TangentialModel *CamT = dynamic_cast<TangentialModel*>(&Cam);
    if(CamT !=0)
    {

    }

    Eigen::MatrixXf A(8,8);
    Eigen::MatrixXf B(8,1);
    Eigen::MatrixXf Ac(8,6);
    Eigen::MatrixXf Bc(8,1);

    int rotation = 7-OrientationType;
    int indiceP[4];

    indiceP[0] = (0+rotation)%4;
    indiceP[1] = (1+rotation)%4;
    indiceP[2] = (2+rotation)%4;
    indiceP[3] = (3+rotation)%4;

    for(int iter=0;iter<iiter;iter++)
    {
        if(iter == 0)
        {
            for(int c=0;c<4;c++)
            {
                double ssize = markerSize;
                Eigen::Vector4f p3DPos;
                switch(c)
                {
                case 3:
                    p3DPos[0] = -(ssize)/2;
                    p3DPos[1] = -(ssize)/2;
                    p3DPos[2] = 0;
                    break;

                case 0:
                    p3DPos[0] = (ssize)/2;
                    p3DPos[1] = -(ssize)/2;
                    p3DPos[2] = 0;
                    break;

                case 1:
                    p3DPos[0] = (ssize)/2;
                    p3DPos[1] = (ssize)/2;
                    p3DPos[2] = 0;
                    break;

                case 2:
                    p3DPos[0] = -(ssize)/2;
                    p3DPos[1] = (ssize)/2;
                    p3DPos[2] = 0;
                    break;
                }

                Eigen::Vector2f Corner = P[indiceP[c]];

                A(c,0) = p3DPos[0];
                A(c,1) = p3DPos[1];
                A(c,2) = 1;
                A(c,3) = 0;
                A(c,4) = 0;
                A(c,5) = 0;
                A(c,6) = -p3DPos[0]*Corner[0];
                A(c,7) = -p3DPos[1]*Corner[0];
                B(c,0)  = Corner[0];

                A(c+4,0) = 0;
                A(c+4,1) = 0;
                A(c+4,2) = 0;
                A(c+4,3) = p3DPos[0];
                A(c+4,4) = p3DPos[1];
                A(c+4,5) = 1;
                A(c+4,6) = -p3DPos[0]*Corner[1];
                A(c+4,7) = -p3DPos[1]*Corner[1];
                B(c+4,0)  = Corner[1];
            }

            Eigen::VectorXf X = A.colPivHouseholderQr().solve(B);
            Eigen::MatrixXf Xm(3,3);

            Xm(0,0) = X(0);
            Xm(0,1) = X(1);
            Xm(0,2) = X(2);
            Xm(1,0) = X(3);
            Xm(1,1) = X(4);
            Xm(1,2) = X(5);
            Xm(2,0) = X(6);
            Xm(2,1) = X(7);
            Xm(2,2) = 1;


            Eigen::Vector3f h1= Xm.col(0);
            Eigen::Vector3f h2= Xm.col(1);
            Eigen::Vector3f h3= Xm.col(2);
            double dl1,dl2,dlmean;


            Eigen::Vector3f tmp = CamT->GetIntrinsInv()*h1;
            dl1 = 1/sqrt(tmp[0]*tmp[0]+tmp[1]*tmp[1]+tmp[2]*tmp[2]);

            tmp = CamT->GetIntrinsInv()*h2;
            dl2 = 1/sqrt(tmp[0]*tmp[0]+tmp[1]*tmp[1]+tmp[2]*tmp[2]);

            dlmean = (dl1+dl2)/2;

            Eigen::Vector3f r1= dlmean*CamT->GetIntrinsInv()*h1;
            Eigen::Vector3f r2= dlmean*CamT->GetIntrinsInv()*h2;
            Eigen::Vector3f r3= r1.cross(r2);

            R.col(0) = r1;
            R.col(1) = r2;
            R.col(2) = r3;

            T = dlmean*CamT->GetIntrinsInv()*h3;

            mse3MarkerfromC.block(0,0,3,3) = R;
            mse3MarkerfromC.block(0,3,3,1) = T;
            mse3MarkerfromC.block(3,0,1,4)<< 0,0,0,1;

        }else{

            for(int c=0;c<4;c++)
            {
                double ssize = markerSize;
                Eigen::Vector4f p3DPos;
                switch(c)
                {
                case 3:
                    p3DPos[0] = -(ssize)/2;
                    p3DPos[1] = -(ssize)/2;
                    p3DPos[2] = 0;
                    p3DPos[3] = 1;
                    break;

                case 0:
                    p3DPos[0] = (ssize)/2;
                    p3DPos[1] = -(ssize)/2;
                    p3DPos[2] = 0;
                    p3DPos[3] = 1;
                    break;

                case 1:
                    p3DPos[0] = (ssize)/2;
                    p3DPos[1] = (ssize)/2;
                    p3DPos[2] = 0;
                    p3DPos[3] = 1;
                    break;

                case 2:
                    p3DPos[0] = -(ssize)/2;
                    p3DPos[1] = (ssize)/2;
                    p3DPos[2] = 0;
                    p3DPos[3] = 1;
                    break;
                }

                double u = P[indiceP[c]][0];
                double v = P[indiceP[c]][1];

                Eigen::Vector4f v3Cam     = mse3MarkerfromC*p3DPos;
                Eigen::Vector2f v2Implane(v3Cam[0]/v3Cam[2],v3Cam[1]/v3Cam[2]);
                Eigen::Vector2f v2Pixels  = CamT->Project(v2Implane);
                Eigen::Vector2f v2Error   = -(v2Pixels - Eigen::Vector2f(u,v));

                Eigen::Matrix2f m2CamDerivs = CamT->GetProjectionDerivs();
                //                Eigen::MatrixXf m26CamFrameMotion(2,6);
                Eigen::MatrixXf m26Jacobian(2,6);
                double dOneOverCameraZ = 1.0 / v3Cam[2];

                //                m26CamFrameMotion << dOneOverCameraZ,0,v3Cam[0]*dOneOverCameraZ,v3Cam[0]*v3Cam[1],-(1+v3Cam[0]*v3Cam[0]),v3Cam[1],
                //                        0,-dOneOverCameraZ,v3Cam[1]*dOneOverCameraZ,(1+v3Cam[1]*v3Cam[1]),-v3Cam[0]*v3Cam[1],-v3Cam[0];

                //                m26Jacobian = m2CamDerivs *m26CamFrameMotion;

                double x = v3Cam[0]/v3Cam[2];
                double y = v3Cam[1]/v3Cam[2];

                for(int m=0; m<6; m++)
                {
                    Eigen::Vector4f v4Motion = generator_field(m, v3Cam);
                    Eigen::Vector2f v2CamFrameMotion;
                    v2CamFrameMotion[0] = (v4Motion[0] - v3Cam[0] * v4Motion[2] * dOneOverCameraZ) * dOneOverCameraZ;
                    v2CamFrameMotion[1] = (v4Motion[1] - v3Cam[1] * v4Motion[2] * dOneOverCameraZ) * dOneOverCameraZ;
                    m26Jacobian.block(0,m,2,1) = m2CamDerivs * v2CamFrameMotion;  // du/dX = du/dx * dx/dX
                }

                Ac.block(c*2,0,2,6) = m26Jacobian;
                Bc.block(c*2,0,2,1) = v2Error;
            }


        }

        Eigen::VectorXf mu = Ac.colPivHouseholderQr().solve(Bc);
        if(mu.norm()>10)
        {
            if(mu.block(0,0,3,1).norm()>10)
            {
                mu.block(0,0,3,1) << 0,0,0;
            }

            if(mu.block(3,0,3,1).norm()>10)
            {
                mu.block(3,0,3,1) << 0,0,0;
            }
        }

        Eigen::Matrix4f Update = exp(mu);
        mse3MarkerfromC = Update*mse3MarkerfromC;


    }

    /*if(VERBOSE)
        std::cout << "mse3MarkerfromC " << std::endl << mse3MarkerfromC << std::endl;
*/
}



/////////////////////////////////
/// \brief Marker::extract3DPosition
/// \param Cam
/// \param iiter
///
void Marker::extract3DPosition(TangentialModel *Cam, int iiter)
{
    Eigen::MatrixXf A(8,8);
    Eigen::MatrixXf B(8,1);
    Eigen::MatrixXf Ac(8,6);
    Eigen::MatrixXf Bc(8,1);


    int rotation = 7-OrientationType;
    int indiceP[4];

    indiceP[0] = (0+rotation)%4;
    indiceP[1] = (1+rotation)%4;
    indiceP[2] = (2+rotation)%4;
    indiceP[3] = (3+rotation)%4;

    for(int iter=0;iter<iiter;iter++)
    {
        if(iter == 0)
        {
            for(int c=0;c<4;c++)
            {
                double ssize = markerSize;
                Eigen::Vector4f p3DPos;
                switch(c)
                {
                case 3:
                    p3DPos[0] = -(ssize)/2;
                    p3DPos[1] = -(ssize)/2;
                    p3DPos[2] = 0;
                    break;

                case 0:
                    p3DPos[0] = (ssize)/2;
                    p3DPos[1] = -(ssize)/2;
                    p3DPos[2] = 0;
                    break;

                case 1:
                    p3DPos[0] = (ssize)/2;
                    p3DPos[1] = (ssize)/2;
                    p3DPos[2] = 0;
                    break;

                case 2:
                    p3DPos[0] = -(ssize)/2;
                    p3DPos[1] = (ssize)/2;
                    p3DPos[2] = 0;
                    break;
                }

                Eigen::Vector2f Corner = P[indiceP[c]];

                A(c,0) = p3DPos[0];
                A(c,1) = p3DPos[1];
                A(c,2) = 1;
                A(c,3) = 0;
                A(c,4) = 0;
                A(c,5) = 0;
                A(c,6) = -p3DPos[0]*Corner[0];
                A(c,7) = -p3DPos[1]*Corner[0];
                B(c,0)  = Corner[0];

                A(c+4,0) = 0;
                A(c+4,1) = 0;
                A(c+4,2) = 0;
                A(c+4,3) = p3DPos[0];
                A(c+4,4) = p3DPos[1];
                A(c+4,5) = 1;
                A(c+4,6) = -p3DPos[0]*Corner[1];
                A(c+4,7) = -p3DPos[1]*Corner[1];
                B(c+4,0)  = Corner[1];
            }

            Eigen::VectorXf X = A.colPivHouseholderQr().solve(B);
            Eigen::MatrixXf Xm(3,3);

            Xm(0,0) = X(0);
            Xm(0,1) = X(1);
            Xm(0,2) = X(2);
            Xm(1,0) = X(3);
            Xm(1,1) = X(4);
            Xm(1,2) = X(5);
            Xm(2,0) = X(6);
            Xm(2,1) = X(7);
            Xm(2,2) = 1;


            Eigen::Vector3f h1= Xm.col(0);
            Eigen::Vector3f h2= Xm.col(1);
            Eigen::Vector3f h3= Xm.col(2);
            double dl1,dl2,dlmean;


            Eigen::Vector3f tmp = Cam->GetIntrinsInv()*h1;
            dl1 = 1/sqrt(tmp[0]*tmp[0]+tmp[1]*tmp[1]+tmp[2]*tmp[2]);

            tmp = Cam->GetIntrinsInv()*h2;
            dl2 = 1/sqrt(tmp[0]*tmp[0]+tmp[1]*tmp[1]+tmp[2]*tmp[2]);

            dlmean = (dl1+dl2)/2;

            Eigen::Vector3f r1= dlmean*Cam->GetIntrinsInv()*h1;
            Eigen::Vector3f r2= dlmean*Cam->GetIntrinsInv()*h2;
            Eigen::Vector3f r3= r1.cross(r2);

            R.col(0) = r1;
            R.col(1) = r2;
            R.col(2) = r3;

            T = dlmean*Cam->GetIntrinsInv()*h3;

            mse3MarkerfromC.block(0,0,3,3) = R;
            mse3MarkerfromC.block(0,3,3,1) = T;
            mse3MarkerfromC.block(3,0,1,4)<< 0,0,0,1;


        }else{

            for(int c=0;c<4;c++)
            {
                double ssize = markerSize;
                Eigen::Vector4f p3DPos;
                switch(c)
                {
                case 3:
                    p3DPos[0] = -(ssize)/2;
                    p3DPos[1] = -(ssize)/2;
                    p3DPos[2] = 0;
                    p3DPos[3] = 1;
                    break;

                case 0:
                    p3DPos[0] = (ssize)/2;
                    p3DPos[1] = -(ssize)/2;
                    p3DPos[2] = 0;
                    p3DPos[3] = 1;
                    break;

                case 1:
                    p3DPos[0] = (ssize)/2;
                    p3DPos[1] = (ssize)/2;
                    p3DPos[2] = 0;
                    p3DPos[3] = 1;
                    break;

                case 2:
                    p3DPos[0] = -(ssize)/2;
                    p3DPos[1] = (ssize)/2;
                    p3DPos[2] = 0;
                    p3DPos[3] = 1;
                    break;
                }

                double u = P[indiceP[c]][0];
                double v = P[indiceP[c]][1];

                Eigen::Vector4f v3Cam     = mse3MarkerfromC*p3DPos;
                Eigen::Vector2f v2Implane(v3Cam[0]/v3Cam[2],v3Cam[1]/v3Cam[2]);
                Eigen::Vector2f v2Pixels  = Cam->Project(v2Implane);
                Eigen::Vector2f v2Error   = -(v2Pixels - Eigen::Vector2f(u,v));

                Eigen::Matrix2f m2CamDerivs = Cam->GetProjectionDerivs();
                Eigen::MatrixXf m26Jacobian(2,6);
                double dOneOverCameraZ = 1.0 / v3Cam[2];


                double x = v3Cam[0]/v3Cam[2];
                double y = v3Cam[1]/v3Cam[2];

                for(int m=0; m<6; m++)
                {
                    Eigen::Vector4f v4Motion = generator_field(m, v3Cam);
                    Eigen::Vector2f v2CamFrameMotion;
                    v2CamFrameMotion[0] = (v4Motion[0] - v3Cam[0] * v4Motion[2] * dOneOverCameraZ) * dOneOverCameraZ;
                    v2CamFrameMotion[1] = (v4Motion[1] - v3Cam[1] * v4Motion[2] * dOneOverCameraZ) * dOneOverCameraZ;
                    m26Jacobian.block(0,m,2,1) = m2CamDerivs * v2CamFrameMotion;  // du/dX = du/dx * dx/dX
                }

                Ac.block(c*2,0,2,6) = m26Jacobian;
                Bc.block(c*2,0,2,1) = v2Error;
            }


            Eigen::VectorXf mu = Ac.colPivHouseholderQr().solve(Bc);
            if(mu.norm()>10)
            {
                if(mu.block(0,0,3,1).norm()>10)
                {
                    mu.block(0,0,3,1) << 0,0,0;
                }

                if(mu.block(3,0,3,1).norm()>10)
                {
                    mu.block(3,0,3,1) << 0,0,0;
                }
            }

            Eigen::Matrix4f Update = exp(mu);
            mse3MarkerfromC = Update*mse3MarkerfromC;

        }

    }

    if(VERBOSE)
        std::cout << "mse3MarkerfromC " << std::endl << mse3MarkerfromC << std::endl;


}

