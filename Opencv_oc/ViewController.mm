//
//  ViewController.m
//  Opencv_oc
//
//  Created by zhaojian on 9/13/17.
//  Copyright © 2017 zhaojian. All rights reserved.
//

#import "ViewController.h"
#import "BlocksKit.h"
#import "UIImage+fixOrientation.h"
#import "UIImagePickerController+BlocksKit.h"
#import <opencv2/opencv.hpp>
@interface ViewController () <UIImagePickerControllerDelegate>
@property(strong,nonatomic) UIImagePickerController* picker;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    
 
}

-(void)click{
    _picker = [[UIImagePickerController alloc] init];
    _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    _picker.allowsEditing = YES;
    
   __weak typeof(self) weakSelf = self;
    
    _picker.bk_didFinishPickingMediaBlock = ^(UIImagePickerController *picker , NSDictionary *info){
 
        NSDictionary* dict = [info objectForKey:UIImagePickerControllerMediaMetadata];
        
        weakSelf.label.text = [NSString stringWithFormat:@"%@",dict[@"Orientation"]];
        UIImage *selectImage = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation];
    
        weakSelf.imageView.image = [weakSelf UIImageFromCVMat:[weakSelf preProcess:selectImage]];
 
        NSLog(@"%ld",(long)weakSelf.imageView.image.imageOrientation);  // 0
        weakSelf.label2.text = [NSString stringWithFormat:@"%ld",(long)weakSelf.imageView.image.imageOrientation];
        [weakSelf.picker dismissViewControllerAnimated:YES completion:nil];
        
    };
    _picker.bk_didCancelBlock  = ^(UIImagePickerController *picker){
         
    };
    [self presentViewController:_picker animated:YES completion:nil];
}


-(void)findMxPolygon:(UIImage*)image{
    std::vector<std::vector<cv::Point> > contours  = [self findContours:image external:YES];
    if (contours.size() == 0) {
        return ;
    }
    else{
        
    }
}


-(std::vector<std::vector<cv::Point> >)findContours:(UIImage*)image external:(BOOL)external{
    
    int mode = external == YES? cv::RETR_EXTERNAL : cv::RETR_CCOMP ;
    cv::Mat matImage = [self  cvMatFromUIImage:image];
    std::vector<std::vector<cv::Point> > contours;
    cv::findContours(matImage, contours, mode, cv::CHAIN_APPROX_SIMPLE);
    return contours;
}

-(cv::Mat)preProcess:(UIImage*) selectImage{
    
    cv::Mat matImage = [self  cvMatFromUIImage:selectImage];
    cv::Mat matGrey;
    // 灰度
    cv::cvtColor(matImage, matGrey, CV_BGR2GRAY);
    
    // 高斯滤波
    cv::GaussianBlur(matGrey, matGrey, cv::Size(5,5), 0);
    
#pragma mark - // block_size ???
    int block_size = 3;
    cv::Mat matBinary;
    
    cv::adaptiveThreshold(matGrey, matBinary, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV, block_size, 5) ;
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(block_size,block_size));
    cv::morphologyEx(matBinary, matBinary, cv::MORPH_CLOSE, kernel,cv::Point(-1,-1),3);
    
    return matBinary;
    
}



#pragma mark - opencv method
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}



#pragma mark - custom method

// OSTU算法求出阈值
int  Otsu(unsigned char* pGrayImg , int iWidth , int iHeight)
{
    if((pGrayImg==0)||(iWidth<=0)||(iHeight<=0))return -1;
    int ihist[256];
    int thresholdValue=0; // „–÷µ
    int n, n1, n2 ;
    double m1, m2, sum, csum, fmax, sb;
    int i,j,k;
    memset(ihist, 0, sizeof(ihist));
    n=iHeight*iWidth;
    sum = csum = 0.0;
    fmax = -1.0;
    n1 = 0;
    for(i=0; i < iHeight; i++)
    {
        for(j=0; j < iWidth; j++)
        {
            ihist[*pGrayImg]++;
            pGrayImg++;
        }
    }
    pGrayImg -= n;
    for (k=0; k <= 255; k++)
    {
        sum += (double) k * (double) ihist[k];
    }
    for (k=0; k <=255; k++)
    {
        n1 += ihist[k];
        if(n1==0)continue;
        n2 = n - n1;
        if(n2==0)break;
        csum += (double)k *ihist[k];
        m1 = csum/n1;
        m2 = (sum-csum)/n2;
        sb = (double) n1 *(double) n2 *(m1 - m2) * (m1 - m2);
        if (sb > fmax)
        {
            fmax = sb;
            thresholdValue = k;
        }
    }
    return(thresholdValue);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
