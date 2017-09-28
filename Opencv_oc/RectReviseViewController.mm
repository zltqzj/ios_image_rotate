//
//  RectReviseViewController.m
//  Opencv_oc
//
//  Created by zhaojian on 9/27/17.
//  Copyright © 2017 zhaojian. All rights reserved.
//

#import "RectReviseViewController.h"
#import "UIImage+fixOrientation.h"

#import <opencv2/opencv.hpp>


using namespace cv;
using namespace std;

@interface RectReviseViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(strong,nonatomic) UIImagePickerController *picker;

@end

@implementation RectReviseViewController


cv::Point2f center(0,0);

cv::Point2f computeIntersect(cv::Vec4i a,cv::Vec4i b)
{
    int x1 = a[0],y1 = a[1],x2 = a[2],y2 = a[3],x3 = b[0],y3 = b[1],x4 = b[2],y4 = b[3];
    
    if (float d = ((float)(x1 - x2)*(y3 - y4)-(y1 - y2)*(x3 - x4)))
    {
        cv::Point2f pt;
        pt.x = ((x1*y2 - y1*x2)*(x3 - x4) - (x1 - x2)*(x3*y4 - y3*x4))/d;
        pt.y = ((x1*y2 - y1*x2)*(y3 - y4) - (y1 - y2)*(x3*y4 - y3*x4))/d;
        return pt;
    }
    else
        return cv::Point2f(-1,-1);
}

void sortCorners(std::vector<cv::Point2f>& corners,cv::Point2f center)
{
    std::vector<cv::Point2f> top,bot;
    
    for (unsigned int i =0;i< corners.size();i++)
    {
        if (corners[i].y<center.y)
        {
            top.push_back(corners[i]);
        }
        else
        {
            bot.push_back(corners[i]);
        }
    }
    
    cv::Point2f tl = top[0].x > top[1].x ? top[1] : top[0];
    cv::Point2f tr = top[0].x > top[1].x ? top[0] : top[1];
    cv::Point2f bl = bot[0].x > bot[1].x ? bot[1] : bot[0];
    cv::Point2f br = bot[0].x > bot[1].x ? bot[0] : bot[1];
    
    corners.clear();
    //注意以下存放顺序是顺时针，当时这里出错了，如果想任意顺序下文开辟的四边形矩阵注意对应
    corners.push_back(tl);
    corners.push_back(tr);
    corners.push_back(br);
    corners.push_back(bl);
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    self.imageView.contentMode =  UIViewContentModeScaleAspectFit;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:
                      [NSString stringWithFormat: @"test.jpg"] ];
    NSLog(@"%@",path);
    NSData* data = UIImageJPEGRepresentation([self.originImageView.image fixOrientation], 0.9);
    [data writeToFile:path atomically:YES];

    
    Mat dst =  [self scan:[path UTF8String] debug:true];
    self.imageView.image = [self UIImageFromCVMat:dst];
    // Do any additional setup after loading the view.
}


-(void)click{
    _picker = [[UIImagePickerController alloc] init];
    _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    _picker.allowsEditing = NO;
    _picker.delegate = self;
    
    [self presentViewController:_picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
//    __weak typeof(self) weakSelf = self;
    
//    NSDictionary* dict = [info objectForKey:UIImagePickerControllerMediaMetadata];
    UIImage *selectImage = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation];
    _originImageView.image = selectImage;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:
                      [NSString stringWithFormat: @"test.png"] ];
    NSLog(@"%@",path);
    NSData* data = UIImagePNGRepresentation(selectImage);
    [data writeToFile:path atomically:YES];

   Mat dst =  [self scan:[path UTF8String] debug:true];
    self.imageView.image = [self UIImageFromCVMat:dst];
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
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
    //    IplImage blur = matBlur;
    //    unsigned char* dataImage = (unsigned char*)blur.imageData;
    //    int threshold = Otsu(dataImage, blur.width, blur.height);
    //    printf("阈值：%d\n",threshold);
    //    cv::threshold(matBlur, matBinary, threshold, 255, cv::THRESH_BINARY);
    
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



/**
 * Get edges of an image
 * @param gray - grayscale input image
 * @param canny - output edge image
 */
void getCanny(Mat gray, Mat &canny) {
    Mat thres;
    double high_thres = threshold(gray, thres, 0, 255, CV_THRESH_BINARY | CV_THRESH_OTSU), low_thres = high_thres * 0.5;
    Canny(gray, canny, low_thres, high_thres);
}

struct Line {
    cv::Point _p1;
    cv::Point _p2;
    cv::Point _center;
    
    Line(cv::Point p1, cv::Point p2) {
        _p1 = p1;
        _p2 = p2;
        _center = cv::Point((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
    }
};

bool cmp_y(const Line &p1, const Line &p2) {
    return p1._center.y < p2._center.y;
}

bool cmp_x(const Line &p1, const Line &p2) {
    return p1._center.x < p2._center.x;
}

/**
 * Compute intersect point of two lines l1 and l2
 * @param l1
 * @param l2
 * @return Intersect Point
 */
Point2f computeIntersect(Line l1, Line l2) {
    int x1 = l1._p1.x, x2 = l1._p2.x, y1 = l1._p1.y, y2 = l1._p2.y;
    int x3 = l2._p1.x, x4 = l2._p2.x, y3 = l2._p1.y, y4 = l2._p2.y;
    if (float d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)) {
        Point2f pt;
        pt.x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / d;
        pt.y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / d;
        return pt;
    }
    return Point2f(-1, -1);
}

-(Mat)scan:(String)file debug:(bool)debug  {
    debug = true;
    /* get input image */
    Mat img = imread(file);
    // resize input image to img_proc to reduce computation
    Mat img_proc;
    int w = img.size().width, h = img.size().height, min_w = 200;
    double scale = min(10.0, w * 1.0 / min_w);
    int w_proc = w * 1.0 / scale, h_proc = h * 1.0 / scale;
    resize(img, img_proc, cv::Size(w_proc, h_proc));
    Mat img_dis = img_proc.clone();
    
    /* get four outline edges of the document */
    // get edges of the image
    Mat gray, canny,bina;
    cvtColor(img_proc, gray, CV_BGR2GRAY);
 
    getCanny(gray, canny);
    
    // extract lines from the edge image
    vector<Vec4i> lines;
    vector<Line> horizontals, verticals;
    HoughLinesP(canny, lines, 1, CV_PI / 180, w_proc / 3, w_proc / 3, 20);
    for (size_t i = 0; i < lines.size(); i++) {
        Vec4i v = lines[i];
        double delta_x = v[0] - v[2], delta_y = v[1] - v[3];
        Line l(cv::Point(v[0], v[1]), cv::Point(v[2], v[3]));
        // get horizontal lines and vertical lines respectively
        if (fabs(delta_x) > fabs(delta_y)) {
            horizontals.push_back(l);
        } else {
            verticals.push_back(l);
        }
        // for visualization only
        if (debug)
            line(img_proc, cv::Point(v[0], v[1]), cv::Point(v[2], v[3]), Scalar(0, 0, 255), 1, CV_AA);
    }
    
    // edge cases when not enough lines are detected
    if (horizontals.size() < 2) {
        if (horizontals.size() == 0 || horizontals[0]._center.y > h_proc / 2) {
            horizontals.push_back(Line(cv::Point(0, 0), cv::Point(w_proc - 1, 0)));
        }
        if (horizontals.size() == 0 || horizontals[0]._center.y <= h_proc / 2) {
            horizontals.push_back(Line(cv::Point(0, h_proc - 1), cv::Point(w_proc - 1, h_proc - 1)));
        }
    }
    if (verticals.size() < 2) {
        if (verticals.size() == 0 || verticals[0]._center.x > w_proc / 2) {
            verticals.push_back(Line(cv::Point(0, 0), cv::Point(0, h_proc - 1)));
        }
        if (verticals.size() == 0 || verticals[0]._center.x <= w_proc / 2) {
            verticals.push_back(Line(cv::Point(w_proc - 1, 0), cv::Point(w_proc - 1, h_proc - 1)));
        }
    }
    // sort lines according to their center point
    sort(horizontals.begin(), horizontals.end(), cmp_y);
    sort(verticals.begin(), verticals.end(), cmp_x);
    // for visualization only
    if (debug) {
        line(img_proc, horizontals[0]._p1, horizontals[0]._p2, Scalar(0, 255, 0), 2, CV_AA);
        line(img_proc, horizontals[horizontals.size() - 1]._p1, horizontals[horizontals.size() - 1]._p2, Scalar(0, 255, 0), 2, CV_AA);
        line(img_proc, verticals[0]._p1, verticals[0]._p2, Scalar(255, 0, 0), 2, CV_AA);
        line(img_proc, verticals[verticals.size() - 1]._p1, verticals[verticals.size() - 1]._p2, Scalar(255, 0, 0), 2, CV_AA);
    }
    
    /* perspective transformation */
    
    // define the destination image size: A4 - 200 PPI
    int w_a4 = 1654, h_a4 = 2339;
    //int w_a4 = 595, h_a4 = 842;
    Mat dst = Mat::zeros(h_a4, w_a4, CV_8UC3);
    
    // corners of destination image with the sequence [tl, tr, bl, br]
    vector<Point2f> dst_pts, img_pts;
    dst_pts.push_back(cv::Point(0, 0));
    dst_pts.push_back(cv::Point(w_a4 - 1, 0));
    dst_pts.push_back(cv::Point(0, h_a4 - 1));
    dst_pts.push_back(cv::Point(w_a4 - 1, h_a4 - 1));
    
    // corners of source image with the sequence [tl, tr, bl, br]
    img_pts.push_back(computeIntersect(horizontals[0], verticals[0]));
    img_pts.push_back(computeIntersect(horizontals[0], verticals[verticals.size() - 1]));
    img_pts.push_back(computeIntersect(horizontals[horizontals.size() - 1], verticals[0]));
    img_pts.push_back(computeIntersect(horizontals[horizontals.size() - 1], verticals[verticals.size() - 1]));
    
    // convert to original image scale
    for (size_t i = 0; i < img_pts.size(); i++) {
        // for visualization only
        if (debug) {
            circle(img_proc, img_pts[i], 10, Scalar(255, 255, 0), 3);
        }
        img_pts[i].x *= scale;
        img_pts[i].y *= scale;
    }
    
    // get transformation matrix
    Mat transmtx = getPerspectiveTransform(img_pts, dst_pts);
    
    // apply perspective transformation
    warpPerspective(img, dst, transmtx, dst.size());
    return dst;
 
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
 

@end
