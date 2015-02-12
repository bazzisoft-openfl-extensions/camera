#include <UIKit/UIKit.h>
#include <MobileCoreServices/MobileCoreServices.h>
#include <objc/runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include "CameraIPhone.h"
#include "ExtensionKitIPhone.h"


@interface TouchPassthroughImageView : UIImageView
{
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;
@end


@implementation TouchPassthroughImageView
{
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return NO;
}

@end



@interface CameraControllerAndDelegate : NSObject<UINavigationControllerDelegate, UIImagePickerControllerDelegate,
                                                  UIPopoverControllerDelegate>
{
}
- (id)initWithView:(UIViewController*)view;
- (BOOL)capturePhotoWithMaxSize:(int)maxSize jpegQuality:(float)jpegQuality cameraOverlayFile:(NSString*)cameraOverlayFile;
@end

@implementation CameraControllerAndDelegate
{
    BOOL m_deviceIsIPad;
    UIViewController* m_view;
    UIImagePickerController* m_imagePickerController;
    UIPopoverController* m_popoverController;
    BOOL m_hasCameraOverlay;
    int m_capturePhotoMaxSize;
    float m_capturePhotoJpegQuality;
}


- (id)initWithView:(UIViewController*)view
{
    self = [super init];

    m_deviceIsIPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    m_view = view;
    m_imagePickerController = nil;
    m_popoverController = nil;

    return self;
}


- (BOOL)capturePhotoWithMaxSize:(int)maxSize jpegQuality:(float)jpegQuality cameraOverlayFile:(NSString*)cameraOverlayFile
{
    // Allow creator to release if they want to
    [self retain];

    m_capturePhotoMaxSize = maxSize;
    m_capturePhotoJpegQuality = jpegQuality;
    m_hasCameraOverlay = NO;

    UIImagePickerControllerSourceType sourceType;

    m_imagePickerController = [[UIImagePickerController alloc] init];
    m_popoverController = nil;

    // Check if the camera is available and if not Set sourceType to the library.
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else
    {
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }

    // Setup image picker
    m_imagePickerController.delegate = self;
    m_imagePickerController.sourceType = sourceType;
    m_imagePickerController.mediaTypes = [[[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil] autorelease];
    m_imagePickerController.allowsEditing = NO;

    if (UIImagePickerControllerSourceTypeCamera == sourceType)
    {
        // Setup camera
        m_imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        m_imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        m_imagePickerController.showsCameraControls = YES;

        // Setup camera overlay view if requested
        if (cameraOverlayFile != nil)
        {
            m_hasCameraOverlay = YES;
            UIImage* overlayImage = [UIImage imageWithContentsOfFile:cameraOverlayFile];
            UIImageView* overlayView = [[[TouchPassthroughImageView alloc] initWithImage:overlayImage] autorelease];
            overlayView.opaque = NO;
            overlayView.contentMode = UIViewContentModeScaleAspectFit;
            m_imagePickerController.cameraOverlayView = overlayView;
        }
    }

    // If the sourceType isn't the camera, then use the popover to present
    // the imagePicker, with the frame that's been passed into this method
    if (sourceType != UIImagePickerControllerSourceTypeCamera && m_deviceIsIPad)
    {
        CGRect rect = CGRectMake(0, 0, 1, 1);
        m_popoverController = [[UIPopoverController alloc] initWithContentViewController:m_imagePickerController];
        m_popoverController.delegate = self;
        [m_popoverController presentPopoverFromRect:rect inView:m_view.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        // Present a imagePicker as a standard view
        [m_view presentViewController:m_imagePickerController animated:YES completion:nil];
    }

    // Register for orientation changes to adjust the overlay image
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
    [self orientationChanged:nil];

    return YES;
}


- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

    if (m_hasCameraOverlay)
    {
        CGRect transformedFrame = CGRectApplyAffineTransform(m_imagePickerController.view.frame, m_imagePickerController.view.transform);
        transformedFrame.origin.x = 0.0f;
        transformedFrame.origin.y = 0.0f;
        m_imagePickerController.cameraOverlayView.frame = transformedFrame;
    }
}


- (void)dismissCameraViews
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

    if (m_popoverController != nil)
    {
        [m_popoverController dismissPopoverAnimated:YES];
        [m_popoverController release];
        [m_imagePickerController release];
    }
    else if (m_imagePickerController != nil)
    {
        [m_imagePickerController dismissViewControllerAnimated:YES completion:nil];
        [m_imagePickerController release];
    }

    m_imagePickerController = nil;
    m_popoverController = nil;
    [self release];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController
{
    [self imagePickerControllerDidCancel:m_imagePickerController];
}


- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    UIImage* photo = [info objectForKey:UIImagePickerControllerOriginalImage];
    int photoWidth = (int)photo.size.width;
    int photoHeight = (int)photo.size.height;
    printf("Camera: Captured photo %d x %d (orientation %d)\n", photoWidth, photoHeight, photo.imageOrientation);

    // Rotate image to make it straight up
    photo = extensionkit::iphone::RotateUIImageToOrientationUp(photo);

    // Resize the image if it's too large
    if (extensionkit::iphone::ClampDimensionsToMaxSize(&photoWidth, &photoHeight, m_capturePhotoMaxSize))
    {
        photo = extensionkit::iphone::ResizeUIImage(photo, photoWidth, photoHeight);
        printf("Camera: Resized photo to %d x %d\n", photoWidth, photoHeight);
    }

    // Write to JPEG
    int dataLength;
    FILE* tempFile;
    const void* data = extensionkit::iphone::UIImageAsJPEGBytes(photo, &dataLength, m_capturePhotoJpegQuality);
    const char* tempFilePath = extensionkit::CreateTemporaryFile(&tempFile);

    if (tempFilePath != NULL)
    {
        printf("Camera: Writing JPEG (%d bytes) to %s\n", dataLength, tempFilePath);
        fwrite(data, 1, dataLength, tempFile);
        fclose(tempFile);
    }
    else
    {
        printf("Camera: ERROR! Unable to create temporary file.\n");
    }

    // raise an OpenFL event CameraEvent.PHOTO_CAPTURED
    extensionkit::DispatchEventToHaxe("camera.event.CameraEvent",
                                      extensionkit::CSTRING, "camera_photo_captured",
                                      extensionkit::CINT, photoWidth,
                                      extensionkit::CINT, photoHeight,
                                      extensionkit::CSTRING, tempFilePath,
                                      extensionkit::CEND);

    [self dismissCameraViews];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    printf("Camera: Dismissed with no photo captured.\n");

    // raise an OpenFL event CameraEvent.PHOTO_CANCELLED
    extensionkit::DispatchEventToHaxe("camera.event.CameraEvent",
                                      extensionkit::CSTRING, "camera_photo_cancelled",
                                      extensionkit::CEND);

    [self dismissCameraViews];
}

@end



//
// Function that dynamically implements the NMEAppDelegate.supportedInterfaceOrientationsForWindow
// callback to allow portrait orientation even if app only supports landscape.
// This is required as barcode scanning camera simulator needs portrait mode.
//
static NSUInteger ApplicationSupportedInterfaceOrientationsForWindow(id self, SEL _cmd, UIApplication* application, UIWindow* window)
{
    return UIInterfaceOrientationMaskAll;
}



namespace camera
{
    namespace iphone
    {
        void InitializeIPhone()
        {
            // Ensure we support portrait orientation else UIImagePickerController crashes
            class_addMethod(NSClassFromString(@"NMEAppDelegate"),
                @selector(application:supportedInterfaceOrientationsForWindow:),
                (IMP) ApplicationSupportedInterfaceOrientationsForWindow,
                "I@:@@");
        }

        bool CapturePhoto(int maxPixelSize, float jpegQuality, const char* cameraOverlayFile)
        {
            // Get our topmost view controller
            UIViewController* topViewController = [[UIApplication sharedApplication] keyWindow].rootViewController;

            // Convert camera overlay to NSString
            NSString* cameraOverlay = nil;

            if (cameraOverlayFile != NULL)
            {
                cameraOverlay = [NSString stringWithUTF8String:cameraOverlayFile];
            }

            // Create our camera+delegate object that will trigger the camera view
            CameraControllerAndDelegate* cameraController = [[[CameraControllerAndDelegate alloc] initWithView:topViewController] autorelease];
            BOOL ret = [cameraController capturePhotoWithMaxSize:maxPixelSize jpegQuality:jpegQuality cameraOverlayFile:cameraOverlay];

            return ret;
        }
    }
}