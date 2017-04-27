package org.haxe.extension.camera;

import java.io.File;
import java.io.IOException;

import org.haxe.extension.extensionkit.FileUtils;
import org.haxe.extension.extensionkit.HaxeCallback;
import org.haxe.extension.extensionkit.ImageUtils;
import org.haxe.extension.extensionkit.Trace;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.provider.MediaStore;


public class Camera extends org.haxe.extension.Extension 
{
    private static final int ACTIVITY_REQUEST_CODE = 51734;
    
    private static File s_imageTempFile = null;
    private static int s_maxImagePixelSize = 2048;
    private static float s_jpegQuality = 0.9f;
    
    public static boolean CapturePhoto(int maxPixelSize, float jpegQuality)
    {
        Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                
        try
        {
            s_maxImagePixelSize = maxPixelSize;
            s_jpegQuality = jpegQuality;
            s_imageTempFile = FileUtils.CreateTemporaryFile(true);
        }
        catch (IOException ex)
        {
            Trace.Error("Camera: Unable to create temporary file in image storage.");
            return false;
        }
        
        intent.putExtra(MediaStore.EXTRA_OUTPUT, Uri.fromFile(s_imageTempFile));
        mainActivity.startActivityForResult(intent, ACTIVITY_REQUEST_CODE);
        return true;
    }  
    
    /**
     * Called when an activity you launched exits, giving you the requestCode 
     * you started it with, the resultCode it returned, and any additional data 
     * from it.
     */
    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) 
    {
        if (requestCode == ACTIVITY_REQUEST_CODE)
        {
            if (resultCode == Activity.RESULT_OK)
            {
            	ImageUtils.Dimensions dimensions = new ImageUtils.Dimensions(0, 0);
            	
                try
                {
                    Bitmap tmpBitmap = ImageUtils.LoadBitmapFromFile(s_imageTempFile);
                	dimensions = new ImageUtils.Dimensions(tmpBitmap);
                    Trace.Info(String.format("Camera: Captured photo %d x %d (%d bytes)", tmpBitmap.getWidth(), tmpBitmap.getHeight(), s_imageTempFile.length()));
                    
                    tmpBitmap = ImageUtils.RotateBitmapToOrientationUp(tmpBitmap, s_imageTempFile);
                    Trace.Info(String.format("Camera: After rotation: %d x %d", tmpBitmap.getWidth(), tmpBitmap.getHeight()));
                    
                    if (ImageUtils.ClampDimensionsToMaxSize(dimensions, s_maxImagePixelSize))
                    {
                    	tmpBitmap = ImageUtils.ResizeBitmap(tmpBitmap, dimensions.width, dimensions.height);
                    	Trace.Info(String.format("Camera: Resized photo to %d x %d", dimensions.width, dimensions.height));
                    }
                    
                    ImageUtils.SaveBitmapAsJPEG(tmpBitmap, s_imageTempFile, s_jpegQuality);
                    Trace.Info(String.format("Camera: Final image size is %d bytes", s_imageTempFile.length()));
                }
                catch (IOException e)
                {
                    Trace.Error("Camera: Unable to resize photo: " + e.toString());
                }

                HaxeCallback.DispatchEventToHaxe("camera.event.CameraEvent",
                        new Object[] {
                            "camera_photo_captured",
                            dimensions.width,
                            dimensions.height,
                            s_imageTempFile.getAbsolutePath()
                        });
            }
            else
            {
                Trace.Info("Camera: Picture capture cancelled or failed.");
                
                s_imageTempFile.delete();
                
                HaxeCallback.DispatchEventToHaxe("camera.event.CameraEvent",
                        new Object[] {
                            "camera_photo_cancelled"
                        });
            }
            
            s_imageTempFile = null;
            return false;
        }        
 
        return super.onActivityResult(requestCode, resultCode, data);
    }    
}
