Camera
=======

### Take photos from a mobile device's camera and receive the byte data 

- Triggers the built-in camera in iOS and Android, or the Photo Library picker
  in the iOS Simulator. 

- Returns the captured photo to Haxe as JPEG byte data via a `CameraEvent` on the stage.

- Simulates a camera event from provided `BitmapData` for non-mobile platforms.

- *TODO*: Allows placing a `BitmapData` overlay over the built-in camera display.


Acknowledgements
----------------

- Inspired & assisted by:
    - [https://github.com/josuigoa/CameraMic](https://github.com/josuigoa/CameraMic)
    - [http://adoptioncurve.net/archives/2012/04/using-the-camer-of-ios-simulators/](http://adoptioncurve.net/archives/2012/04/using-the-camer-of-ios-simulators/)
    - [http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/](http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/)


Dependencies
------------

- This extension implicitly includes `extensionkit` which must be available in a folder
  beside this one.


Installation
------------

    git clone https://github.com/bazzisoft-openfl-extensions/extensionkit
    git clone https://github.com/bazzisoft-openfl-extensions/camera
    lime rebuild extensionkit [linux|windows|mac|android|ios]
    lime rebuild camera [linux|windows|mac|android|ios]


Usage
-----

### project.xml

    <include path="/path/to/camera" />


### Haxe
    
    class Main extends Sprite
    {
    	public function new()
        {
    		super();

            Camera.Initialize();

            stage.addEventListener(CameraEvent.PHOTO_CAPTURED, HandlePhotoCaptured);
            stage.addEventListener(CameraEvent.PHOTO_CANCELLED, function(e) { trace(e); });
    
            #if !mobile
            // When testing on flash/desktop, CapturePhoto() should send this image...
            Camera.SetFakePhotoResult(Assets.getBitmapData("assets/mySimulatedPhoto.jpg"));
            #end

            // Take photo, limit max possible size to 1024x1024, JPEG quality 0.9
            Camera.CapturePhoto(1024, 0.9);

            ...
        }

        public function HandlePhotoCaptured(e:CameraEvent) : Void
        {
            var bitmapData:BitmapData = e.GetBitmapData();
            var jpegBytes:Bytes = e.GetImageData();

            addChild(new Bitmap(bitmapData));
        }
    }

