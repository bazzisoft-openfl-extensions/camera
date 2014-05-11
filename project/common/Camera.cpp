#include <stdio.h>
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

    bool CapturePhoto(int maxPixelSize, float jpegQuality, const char* cameraOverlayFile)
    {
        if (cameraOverlayFile != NULL && cameraOverlayFile[0] == '\0')
        {
            cameraOverlayFile = NULL;
        }
        
        #ifdef IPHONE
        return iphone::CapturePhoto(maxPixelSize, jpegQuality, cameraOverlayFile);
        #else
        return false;
        #endif
    }
}