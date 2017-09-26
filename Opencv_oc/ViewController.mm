//
//  ViewController.m
//  Opencv_oc
//
//  Created by zhaojian on 9/13/17.
//  Copyright © 2017 zhaojian. All rights reserved.
//

#import "ViewController.h"
//#import "BlocksKit.h"
#import "UIImage+fixOrientation.h"
//#import "UIImagePickerController+BlocksKit.h"
#import <opencv2/opencv.hpp>
@interface ViewController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(strong,nonatomic) UIImagePickerController *picker;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
}

-(void)click{
    _picker = [[UIImagePickerController alloc] init];
    _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    _picker.allowsEditing = NO;
    _picker.delegate = self;
    
    [self presentViewController:_picker animated:YES completion:nil];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    __weak typeof(self) weakSelf = self;

    NSDictionary* dict = [info objectForKey:UIImagePickerControllerMediaMetadata];
    
    weakSelf.label.text = [NSString stringWithFormat:@"%@",dict[@"Orientation"]];
    UIImage *selectImage = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation];
    
    // 预处理
    cv::Mat preProcessImage =  [weakSelf preProcess:selectImage];
    
    // 找面积最大的外接四边形的四个顶点
//    [weakSelf findMaxPolygon:preProcessImage];
    
    weakSelf.imageView.image = [weakSelf UIImageFromCVMat:preProcessImage]  ;
    
    NSLog(@"%ld",(long)weakSelf.imageView.image.imageOrientation);  // 0
    weakSelf.label2.text = [NSString stringWithFormat:@"%ld",(long)weakSelf.imageView.image.imageOrientation];
    [weakSelf.picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

// 找到图像上面积最大的外接四边形的四个顶点
-(void)findMaxPolygon:(cv::Mat)image{
    std::vector<std::vector<cv::Point> > contours  = [self findContours:image external:YES];
    NSLog(@"%lu",contours.size());
    if (contours.size() == 0)
        return ;
#pragma mark - sort ???
    
    std::sort(contours.begin(), contours.end(), conter_area_cmp);
    float alpha = 0.0001;
    
    while (1) {
      std::vector<cv::Point> approx = [self approxPolyDP:contours[0] alpha:alpha];
        long size = approx.size();
        NSLog(@"%ld",size);
        if (size > 50) {
            alpha *= 1.5;
        }
        else if(size > 10){
            alpha *= 1.2;
        }
        else if(size > 4){
                //
            alpha *= 1.1;
        }
        else if (size == 4){

            break;
        }
        else{
            NSLog(@"error");
        }


    }
//    return  approx  std::vector<cv::Point>

}




-(void)merge:(std::vector<cv::Point>)approx{
    
}


// 多边形拟合，拟合精度为轮廓周长的alpha
-(std::vector<cv::Point>)approxPolyDP:(std::vector<cv::Point> )contour alpha:(float)alpha{
    double epsilon = alpha * cv::arcLength(contour, true) ;
    std::vector<cv::Point>  dest_contour ;
    cv::approxPolyDP(contour, dest_contour, epsilon, true);
    return dest_contour ;
}

int conter_area_cmp(const std::vector<cv::Point> &a, const std::vector<cv::Point> &b) {
    return cv::contourArea(b) > cv::contourArea(a);
}


// 取图像的连通区域
-(std::vector<std::vector<cv::Point> >)findContours:(cv::Mat)matImage external:(BOOL)external{
    
    int mode = external == YES? cv::RETR_EXTERNAL : cv::RETR_CCOMP ;
    std::vector<std::vector<cv::Point> > contours;
    cv::findContours(matImage, contours, mode, cv::CHAIN_APPROX_SIMPLE);
    return contours;
}


// 预处理
-(cv::Mat)preProcess:(UIImage*)selectImage{
    
    cv::Mat matImage = [self  cvMatFromUIImage:selectImage];

    // 灰度
    cv::Mat matGrey;
    cv::cvtColor(matImage, matGrey, CV_BGR2GRAY);
    
    // 高斯滤波
    cv::Mat matBlur;
    cv::GaussianBlur(matGrey, matBlur, cv::Size(5,5), 0);
    
#pragma mark - // block_size ???
    
    int block_size = 5;
    
//    int width = selectImage.size.width ;
//    int height = selectImage.size.height;
//    block_size  =  MAX(MAX(width / 500 * 2 +1, height / 500 * 2 + 1), 3) ;
//    NSLog(@"%d",block_size);
    
    cv::Mat matBinary;
    
    // 二值化
    cv::adaptiveThreshold(matBlur, matBinary, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV, block_size, 5) ;
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(block_size,block_size));
    
    // 形态学运算函数，闭运算
    cv::Mat matClose;
    cv::morphologyEx(matBinary, matClose, cv::MORPH_CLOSE, kernel,cv::Point(-1,-1),3);
    
    return matClose;
    
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
