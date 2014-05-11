package camera;
import camera.event.CameraEvent;
import extensionkit.ExtensionKit;
import flash.display.BitmapData;
import haxe.io.Bytes;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#end

#if (android && openfl)
import openfl.utils.JNI;
#end


class Camera 
{
    #if cpp
    private static var camera_capture_photo = null;
    #end

    #if android
    private static var camera_capture_photo_jni = null;
    #end

    private static var s_initialized:Bool = false;
    private static var s_fakePhoto:BitmapData = null;

    public static function Initialize() : Void
    {
        if (s_initialized)
        {
            return;
        }

        s_initialized = true;

        ExtensionKit.Initialize();

        #if cpp
        camera_capture_photo = Lib.load("camera", "camera_capture_photo", 2);
        #end

        #if android
        camera_capture_photo_jni = JNI.createStaticMethod("org.haxe.extension.camera.Camera", "CapturePhoto", "(IF)Z");
        #end
    }

    /**
     * Triggers the native/java camera functionality. On non-supported platforms,
     * returns a fake image if SetFakePhotoResult() was set.
     *
     * @param maxPixelSize The maximum size in pixels of any image dimension.
     * 
     * @param jpegQuality The quality setting for JPEG encoding (0.0 - 1.0)
     * 
     * @return true if the camera was successfully launched.
     *         false if device doesn't support a camera & no fake result set.
     */
    public static function CapturePhoto(maxPixelSize:Int = 2048, jpegQuality:Float = 0.9) : Bool
    {
        #if android

        return camera_capture_photo_jni(maxPixelSize, jpegQuality);

        #elseif (cpp && mobile)

        return camera_capture_photo(maxPixelSize, jpegQuality);

        #else

        if (s_fakePhoto != null)
        {
            SimulatePhotoCaptured(s_fakePhoto);
            return true;
        }
        else
        {
            trace("Camera.CapturePhoto() is not supported on this platform.");
            return false;
        }

        #end
    }

    /**
     * Sets a fake photo to return as a CameraEvent when running
     * on a platform that doesn't have a camera.
     */
    public static function SetFakePhotoResult(photo:BitmapData) : Void
    {
        s_fakePhoto = photo;
    }

    /**
     * Dispatches the CameraEvent for the given photo.
     */
    public static function SimulatePhotoCaptured(photo:BitmapData) : Void
    {
        ExtensionKit.stage.dispatchEvent(new CameraEvent(CameraEvent.PHOTO_CAPTURED, photo.width, photo.height, photo));
    }

    /**
     * Dispatches the BarcodeScannedEvent indicating cancellation of a scan.
     */
    public static function SimulatePhotoCancelled() : Void
    {
        ExtensionKit.stage.dispatchEvent(new CameraEvent(CameraEvent.PHOTO_CANCELLED));
    }    
}