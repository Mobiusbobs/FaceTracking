//
//  ViewController.m
//  openCViOSFaceTrackingTutorial
//
//  Created by Evangelos Georgiou on 16/03/2013.
//  Copyright (c) 2013 Evangelos Georgiou. All rights reserved.
//

#import "ViewController.h"
#include <iostream>
#include <stdio.h>

NSString* const faceCascadeFilename = @"cascade_0821";
const int HaarOptions = CV_HAAR_DO_ROUGH_SEARCH ;
//#define CV_HAAR_DO_CANNY_PRUNING    1
//#define CV_HAAR_SCALE_IMAGE         2
//#define CV_HAAR_FIND_BIGGEST_OBJECT 4
//#define CV_HAAR_DO_ROUGH_SEARCH     8

@interface ViewController ()

@end


@implementation ViewController

@synthesize videoCamera;
@synthesize mask=_mask;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.delegate = self;
    
    NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:faceCascadeFilename ofType:@"xml"];
    
    
    faceCascade.load([faceCascadePath UTF8String]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus

// Modify from here
static void overlayImage(Mat* src, Mat* overlay, const cv::Point& location)
{
    for (int y = max(location.y, 0); y < src->rows; ++y)
    {
        int fY = y - location.y;
        
        if (fY >= overlay->rows)
            break;
        
        for (int x = max(location.x, 0); x < src->cols; ++x)
        {
            int fX = x - location.x;
            
            if (fX >= overlay->cols)
                break;
            
            double opacity = ((double)overlay->data[fY * overlay->step + fX * overlay->channels() + 3]) / 255;
            
            for (int c = 0; opacity > 0 && c < src->channels(); ++c)
            {
                unsigned char overlayPx = overlay->data[fY * overlay->step + fX * overlay->channels() + c];
                unsigned char srcPx = src->data[y * src->step + x * src->channels() + c];
                src->data[y * src->step + src->channels() * x + c] = srcPx * (1. - opacity) + overlayPx * opacity;
            }
        }
    }
}


- (void)processImage:(Mat&)image;
{
    cv::Mat mask = [self cvMatFromUIImage:[UIImage imageNamed:@"glasses.png"]];
    Mat image_copy;
    
    
    Mat grayscaleFrame;
    cvtColor(image, grayscaleFrame, CV_BGR2GRAY);
    equalizeHist(grayscaleFrame, grayscaleFrame);
    
    std::vector<cv::Rect> faces;
    faceCascade.detectMultiScale(grayscaleFrame, faces, 1.05, 6, HaarOptions, cv::Size(30, 30),cv::Size(200, 200));
    

    for (int i = 0; i < faces.size(); i++)
    {
        cv::Point pt1(faces[0].x + faces[0].width, faces[0].y + faces[0].height);
        cv::Point pt2(faces[0].x, faces[0].y);
        cv::Size eyesize = cv::Size(faces[i].width, faces[i].height);

        
        cv::Mat resizeMask;
        cv::resize(mask, resizeMask, eyesize);

//        NSLog(@"hello %f,%f",center.x, center.y);
//        cv::rectangle(image, pt1, pt2, cvScalar(0, 255, 255, 0), 1, 8 ,0);
        cv::Rect roi(pt2, resizeMask.size() );
//        overlayImage(image, resizeMask, image_copy, pt2);
        overlayImage(&image, &resizeMask, pt2);
    }
    
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    CGContextSetAlpha(contextRef, 0.99);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}
// End modify

#endif

#pragma mark - UI Actions

- (IBAction)startCamera:(id)sender
{
    [self.videoCamera start];
}

- (IBAction)stopCamera:(id)sender
{
    [self.videoCamera stop];
}

@end
