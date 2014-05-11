package camera.event;
import camera.utils.ImageUtils;
import flash.display.BitmapData;
import flash.events.Event;
import haxe.io.Bytes;

#if !flash
import sys.FileSystem;
import sys.io.File;
#end


class CameraEvent extends Event
{
    public static inline var PHOTO_CAPTURED = "camera_photo_captured";
    public static inline var PHOTO_CANCELLED = "camera_photo_cancelled";

    public var imageWidth(default, null) : Int;
    public var imageHeight(default, null) : Int;
    
    private var m_imageData:Bytes = null;
    private var m_bitmapData:BitmapData = null;

    public function new(type:String, imageWidth:Int = 0, imageHeight:Int = 0, ?imageFilePath:String, ?imageData:Bytes, ?bitmapData:BitmapData)
    {
        super(type, true, true);
        this.imageWidth = imageWidth;
        this.imageHeight = imageHeight;
        
        if (imageFilePath != null)
        {
            #if flash
            throw "Camera: Can't read images from a file in Flash.";
            #else
            m_imageData = File.getBytes(imageFilePath);
            FileSystem.deleteFile(imageFilePath);
            #end
        }
        else if (imageData != null)
        {
            m_imageData = imageData;
        }
        
        if (bitmapData != null)
        {
            m_bitmapData = bitmapData;
        }
    }

	public override function clone() : Event
    {
		return new CameraEvent(type, imageWidth, imageHeight, null, m_imageData, m_bitmapData);
	}

	public override function toString() : String
    {
        var s = "[CameraEvent type=" + type;
        if (type != PHOTO_CANCELLED)
        {
            s += " imageWidth=" + imageWidth + " imageHeight=" + imageHeight;
        }
        s += "]";
        return s;
	}

    public function GetImageData() : Bytes
    {
        if (m_imageData != null)
        {
            return m_imageData;
        }
        else if (m_bitmapData != null)
        {
            m_imageData = ImageUtils.ConvertBitmapDataToImageData(m_bitmapData, ImageUtils.FORMAT_JPEG, 0.9);
            return m_imageData;
        }
        else
        {
            return null;
        }
    }
    
    public function GetBitmapData() : BitmapData
    {
        if (m_bitmapData != null)
        {
            return m_bitmapData;
        }
        else if (m_imageData != null)
        {
            m_bitmapData = ImageUtils.ConvertImageDataToBitmapData(m_imageData);
            return m_bitmapData;
        }
        else
        {
            return null;
        }
    }
}