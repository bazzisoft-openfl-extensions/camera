#ifndef CAMERA_H
#define CAMERA_H


namespace camera 
{
    void Initialize();
    bool CapturePhoto(int maxPixelSize, float jpegQuality, const char* cameraOverlayFile);
}


#endif