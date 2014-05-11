#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif


#include <hx/CFFI.h>
#include "Camera.h"


using namespace camera;



static value camera_capture_photo(value maxPixelSize, value jpegQuality, value cameraOverlayFile) 
{
    return alloc_bool(CapturePhoto(val_int(maxPixelSize), (float)val_float(jpegQuality), val_string(cameraOverlayFile)));
}
DEFINE_PRIM(camera_capture_photo, 3);



extern "C" void camera_main () 
{
    val_int(0); // Fix Neko init
}
DEFINE_ENTRY_POINT(camera_main);



extern "C" int camera_register_prims () 
{ 
    Initialize();
    return 0; 
}