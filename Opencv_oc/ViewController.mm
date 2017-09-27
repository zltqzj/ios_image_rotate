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
using namespace cv;
using namespace std;



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
    Mat preProcessImage =  [weakSelf preProcess:selectImage];
    
    // 找面积最大的外接四边形的四个顶点
//   Mat dingdian =  [weakSelf findMaxPolygon:preProcessImage];
    
    weakSelf.imageView.image = [weakSelf UIImageFromCVMat:preProcessImage]  ;
    
    NSLog(@"%ld",(long)weakSelf.imageView.image.imageOrientation);  // 0
    weakSelf.label2.text = [NSString stringWithFormat:@"%ld",(long)weakSelf.imageView.image.imageOrientation];
    [weakSelf.picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

// 找到图像上面积最大的外接四边形的四个顶点
-(Mat)findMaxPolygon:(Mat)image{
    vector<vector<cv::Point> > contours  = [self findContours:image external:YES];
    NSLog(@"size------------%lu",contours.size());
    if (contours.size() == 0)
        return image;
    
    double maxArea = 0;
    vector<cv::Point> maxContour;
    for(size_t i = 0; i < contours.size(); i++)
    {
        double area = cv::contourArea(contours[i]);
        if (area > maxArea)
        {
            maxArea = area;
            maxContour = contours[i];
        }
    }
    
    // 将轮廓转为矩形框
    cv::Rect maxRect = cv::boundingRect(maxContour);
    
    // 显示连通域
    cv::Mat result1, result2;

    image.copyTo(result1);
    image.copyTo(result2);
    
    for (size_t i = 0; i < contours.size(); i++)
    {
        cv::Rect r = cv::boundingRect(contours[i]);
        cv::rectangle(result1, r, cv::Scalar(255));
    }
    cv::rectangle(result2, maxRect, cv::Scalar(255));
    return result2;
    
#pragma mark - sort ???
    
//    sort(contours.begin(), contours.end(), conter_area_cmp);
//    float alpha = 0.0001;
//
//    while (1) {
//      vector<Point> approx = [self approxPolyDP:contours[0] alpha:alpha];
//        long size = approx.size();
//        NSLog(@"%ld",size);
//        if (size > 50) {
//            alpha *= 1.5;
//        }
//        else if(size > 10){
//            alpha *= 1.2;
//        }
//        else if(size > 4){
//                //
//            alpha *= 1.1;
//        }
//        else if (size == 4){
//
//            break;
//        }
//        else{
//            NSLog(@"error");
//        }
//
//
//    }
//    return  approx  vector<Point>

}




-(void)merge:(vector<cv::Point>)approx{
    
}


// 多边形拟合，拟合精度为轮廓周长的alpha
-(vector<cv::Point>)approxPolyDP:(vector<cv::Point> )contour alpha:(float)alpha{
    double epsilon = alpha * arcLength(contour, true) ;
    vector<cv::Point>  dest_contour ;
    approxPolyDP(contour, dest_contour, epsilon, true);
    return dest_contour ;
}

int conter_area_cmp(const vector<cv::Point> &a, const vector<cv::Point> &b) {
    return contourArea(b) > contourArea(a);
}


// 取图像的连通区域
-(vector<vector<cv::Point> >)findContours:(Mat)matImage external:(BOOL)external{
    
    int mode = external == YES? RETR_EXTERNAL : RETR_CCOMP ;
    vector<vector<cv::Point> > contours;
    findContours(matImage, contours, mode, CHAIN_APPROX_SIMPLE);
    return contours;
}


// 预处理
-(Mat)preProcess:(UIImage*)selectImage{
    
    Mat matImage = [self  cvMatFromUIImage:selectImage];

    // 灰度
    Mat matGrey;
    cvtColor(matImage, matGrey, CV_BGR2GRAY);
    
    // 高斯滤波
    Mat matBlur;
    GaussianBlur(matGrey, matBlur, cv::Size(5,5), 0);
    
#pragma mark - // block_size ???
    
    int block_size = 5;
    
//    int width = selectImage.size.width ;
//    int height = selectImage.size.height;
//    block_size  =  MAX(MAX(width / 500 * 2 +1, height / 500 * 2 + 1), 3) ;
//    NSLog(@"%d",block_size);
    
    Mat matBinary;
    IplImage blur = matBlur;
 
    unsigned char* dataImage = (unsigned char*)blur.imageData;
    int threshold = Otsu1(dataImage, blur.width, blur.height);
    printf("阈值：%d\n",threshold);
    cv::threshold(matGrey, matBinary, threshold, 255, THRESH_BINARY);
    std::vector<cv::Vec4i> lines;
    //  void HoughLinesP( InputArray image, OutputArray lines,
//    double rho, double theta, int threshold,
//    double minLineLength = 0, double maxLineGap = 0 );

    cv::HoughLinesP(matBinary, lines, 1,  CV_PI/180, 70);
    for (int i = 0; i < lines.size(); i++)
    {
        cv::Vec4i v = lines[i];
        lines[i][0] = 0;
        lines[i][1] = ((float)v[1] - v[3]) / (v[0] - v[2]) * -v[0] + v[1];
        lines[i][2] = matBinary.cols;
        lines[i][3] = ((float)v[1] - v[3]) / (v[0] - v[2]) * (matBinary.cols - v[2]) + v[3];
    }
  
    
    
    // 二值化
//    adaptiveThreshold(matBlur, matBinary, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY_INV, block_size, 5) ;
    Mat kernel = getStructuringElement(MORPH_RECT, cv::Size(block_size,block_size));
    
    // 形态学运算函数，闭运算
//    Mat matClose;
//    morphologyEx(matBinary, matClose, MORPH_CLOSE, kernel,cv::Point(-1,-1),3);
    
    return matBinary;
    
}

#pragma mark - opencv method
- (Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
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

-(UIImage *)UIImageFromCVMat:(Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from Mat
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
int  Otsu1(unsigned char* pGrayImg , int iWidth , int iHeight)
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
