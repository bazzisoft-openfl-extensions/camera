#ifndef CAMERAIPHONE_H
#define CAMERAIPHONE_H


namespace camera
{
    namespace iphone
    {
        void InitializeIPhone();
        bool CapturePhoto(int maxPixelSize, float jpegQuality, const char* cameraOverlayFile);
    }
}


#endif