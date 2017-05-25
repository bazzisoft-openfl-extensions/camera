package camera;
import camera.event.CameraEvent;
import camera.utils.ImageUtils;
import extensionkit.ExtensionKit;
import flash.display.BitmapData;
import haxe.io.Bytes;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#end

#if android
import lime.system.JNI;
#end

#if !flash
import sys.io.File;
import sys.FileSystem;
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
    private static var s_cameraOverlayFilename:String = null;

    public static function Initialize() : Void
    {
        if (s_initialized)
        {
            return;
        }

        s_initialized = true;

        ExtensionKit.Initialize();

        #if cpp
        camera_capture_photo = Lib.load("camera", "camera_capture_photo", 3);
        #end

        #if android
        camera_capture_photo_jni = JNI.createStaticMethod("org.haxe.extension.camera.Camera", "CapturePhoto", "(IF)Z");
        #end

        PrepareCameraOverlayFile();
    }

    /**
     * Checks if a camera overlay is currently in place.
     */
    public static inline function HasCameraOverlayImage() : Bool
    {
        #if !flash
        return FileSystem.exists(s_cameraOverlayFilename);
        #else
        return false;
        #end
    }    
    
    /**
     * Sets a bitmap that is overlaid onto the native camera view. Can use transparency.
     */
    public static function SetCameraOverlayImage(bitmapData:BitmapData) : Void
    {
        #if !flash        
        var imageBytes:Bytes = ImageUtils.ConvertBitmapDataToImageData(bitmapData, ImageUtils.FORMAT_PNG);
        File.saveBytes(s_cameraOverlayFilename, imageBytes);        
        #end
    }
    
    /**
     * Removes a previously set overlay image.
     */
    public static function ClearCameraOverlayImage() : Void
    {
        #if !flash
        if (HasCameraOverlayImage())
        {
            FileSystem.deleteFile(s_cameraOverlayFilename);
        }
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

        // TODO: Send overlay image & show it
        return camera_capture_photo_jni(maxPixelSize, jpegQuality);

        #elseif (cpp && mobile)

        return camera_capture_photo(maxPixelSize, jpegQuality, GetCameraOverlayFileIfExists());

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
    
    //---------------------------------
    // Private Methods
    //---------------------------------
    
    private static function PrepareCameraOverlayFile() : Void
    {
        #if !flash
        
        s_cameraOverlayFilename = ExtensionKit.GetTempDirectory() + "/org.haxe.extension.camera";
        
        if (!FileSystem.exists(s_cameraOverlayFilename))
        {
            FileSystem.createDirectory(s_cameraOverlayFilename);
        }
        
        s_cameraOverlayFilename += "/camera-overlay.png";
                
        // Don't carry over overlay from previous execution!
        ClearCameraOverlayImage();
        
        #end
    }
    
    private static function GetCameraOverlayFileIfExists() : String
    {
        #if !flash
        
        if (HasCameraOverlayImage())
        {
            return s_cameraOverlayFilename;            
        }
        else
        {
            return null;
        }
        
        #else
        
        return null;
        
        #end
    }
}