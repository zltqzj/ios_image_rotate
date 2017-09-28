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
    UIImage *selectImage = [_originImageView.image fixOrientation];

    Mat preProcessImage =  [self preProcess:selectImage];
    
//    [self findMaxPolygon:preProcessImage];
        self.imageView.image = [self UIImageFromCVMat:preProcessImage];
                            // [self UIImageFromCVMat:preProcessImage]  ;

    
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
-(vector<cv::Point>)findMaxPolygon:(Mat)image{
    Mat imageCopy  = image.clone();
    vector<vector<cv::Point> > contours  = [self findContours:imageCopy external:YES];
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
    
    sort(contours.begin(), contours.end(), conter_area_cmp);
    float alpha = 0.0001;
    
    while (1) {
        vector<cv::Point> approx = [self approxPolyDP:contours[0] alpha:alpha];
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
//    return  approx
 
}


//(void)is_close()

-(void)merge:(vector<vector<cv::Point> >)approx{
    vector<vector<cv::Point> > approxCopy = approx;
    vector<cv::Point> list   =  approxCopy[0];
    bool flag = false ;
    for (int i = 1; i< approxCopy.size(); i++) {
        flag = false;
        for (int j = 1; j< list.size(); j++) {
            
        }
    }
    
    
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
    
    int block_size = 5;

    Mat matBinary;
//    IplImage blur = matBlur;
 
//    unsigned char* dataImage = (unsigned char*)blur.imageData;
//    int threshold = Otsu1(dataImage, blur.width, blur.height);
//    printf("阈值：%d\n",threshold);
//    cv::threshold(matGrey, matBinary, threshold, 255, THRESH_BINARY);
//    std::vector<cv::Vec4i> lines;

    
    
    // 二值化
    adaptiveThreshold(matBlur, matBinary, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY_INV, block_size, 5) ;
    Mat kernel = getStructuringElement(MORPH_RECT, cv::Size(block_size,block_size));
    
    // 形态学运算函数，闭运算
    Mat matClose;
    morphologyEx(matBinary, matClose, MORPH_CLOSE, kernel,cv::Point(-1,-1),3);
    
    return matClose;
    
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


#pragma mark -
#pragma mark =========== 寻找最大边框 ===========
int findLargestSquare(const vector<vector<cv::Point> >& squares, vector<cv::Point>& biggest_square)
{
    if (!squares.size()) return -1;
    
    int max_width = 0;
    int max_height = 0;
    int max_square_idx = 0;
    for (int i = 0; i < squares.size(); i++)
    {
        cv::Rect rectangle = boundingRect(Mat(squares[i]));
        if ((rectangle.width >= max_width) && (rectangle.height >= max_height))
        {
            max_width = rectangle.width;
            max_height = rectangle.height;
            max_square_idx = i;
        }
    }
    biggest_square = squares[max_square_idx];
    return max_square_idx;
}

/**
 根据三个点计算中间那个点的夹角   pt1 pt0 pt2
 */
double getAngle(cv::Point pt1, cv::Point pt2, cv::Point pt0)
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

/**
 点到点的距离
 
 @param p1 点1
 @param p2 点2
 @return 距离
 */
double getSpacePointToPoint(cv::Point p1, cv::Point p2)
{
    int a = p1.x-p2.x;
    int b = p1.y-p2.y;
    return sqrt(a * a + b * b);
}

/**
 两直线的交点
 
 @param a 线段1
 @param b 线段2
 @return 交点
 */
//cv::Point2f computeIntersect(cv::Vec4i a, cv::Vec4i b)
//{
//    int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3], x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
//
//    if (float d = ((float)(x1 - x2) * (y3 - y4)) - ((y1 - y2) * (x3 - x4)))
//    {
//        cv::Point2f pt;
//        pt.x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / d;
//        pt.y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / d;
//        return pt;
//    }
//    else
//        return cv::Point2f(-1, -1);
//}

/**
 对多个点按顺时针排序
 
 @param corners 点的集合
 */
//void sortCorners(std::vector<cv::Point2f>& corners)
//{
//    if (corners.size() == 0) return;
//    //先延 X轴排列
//    cv::Point pl = corners[0];
//    int index = 0;
//    for (int i = 1; i < corners.size(); i++)
//    {
//        cv::Point point = corners[i];
//        if (pl.x > point.x)
//        {
//            pl = point;
//            index = i;
//        }
//    }
//    corners[index] = corners[0];
//    corners[0] = pl;
//
//    cv::Point lp = corners[0];
//    for (int i = 1; i < corners.size(); i++)
//    {
//        for (int j = i+1; j<corners.size(); j++)
//        {
//            cv::Point point1 = corners[i];
//            cv::Point point2 = corners[j];
//            if ((point1.y-lp.y*1.0)/(point1.x-lp.x)>(point2.y-lp.y*1.0)/(point2.x-lp.x))
//            {
//                cv::Point temp = point1;
//                corners[i] = corners[j];
//                corners[j] = temp;
//            }
//        }
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
