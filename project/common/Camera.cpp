#include "Camera.h"
#include "../iphone/CameraIPhone.h"


namespace camera 
{
    void Initialize()
    {
        #ifdef IPHONE
        iphone::InitializeIPhone();
        #endif
    }

    bool CapturePhoto(int maxPixelSize, float jpegQuality)
    {
        #ifdef IPHONE
        return iphone::CapturePhoto(maxPixelSize, jpegQuality);
        #else
        return false;
        #endif
    }
}