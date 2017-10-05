//
//  ViewController.m
//  Opencv_oc
//
//  Created by zhaojian on 9/13/17.
//  Copyright © 2017 zhaojian. All rights reserved.
//

#import "ViewController.h"
//#import "BlocksKit.h"
#include <stdio.h>
#include <stdlib.h>
#import "UIImage+fixOrientation.h"
#import "RectReviseViewController.h"
//#import "UIImagePickerController+BlocksKit.h"
#import <opencv2/opencv.hpp>
#import "UIImage+CVMat.h"

using namespace cv;
using namespace std;
#define ABS(a) ({typeof(a) _a = (a); _a < 0 ? -_a : _a; })
#define P_WIDTH    1280
#define P_HEIGHT 800

@interface ViewController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(strong,nonatomic) UIImagePickerController *picker;

@end

@implementation ViewController

-(IBAction)push:(id)sender{
//    RectReviseViewController* vc = UIStoryboard.
}

double angle(cv::Point pt1, cv::Point pt2, cv::Point pt0)
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    double bleh = atan(dy1/dx1)-atan(dy2/dx2);
    //std::cout << bleh << std::endl;
    return bleh;
}


 bool myfunction(std::vector<cv::Point> i, std::vector<cv::Point> j) {
    
    std::vector<cv::Point> ponto;
    std::vector<cv::Point> ponto1;
    
    double peri = cv::arcLength(i, true);
    cv::approxPolyDP(i, ponto, 0.02 * peri, true);

    double peri1 = cv::arcLength(j, true);
    cv::approxPolyDP(j, ponto1, 0.02 * peri1, true);
    
    return cv::contourArea(ponto) > cv::contourArea(ponto1);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    UIImage *selectImage = [_originImageView.image fixOrientation];
    // loading the image
    Mat img =  [UIImage cvMatFromUIImage:selectImage];
    Mat imgGrayscale;
    Mat imgBlurred;
    Mat imgCanny;
    Mat dil;
    vector<vector<cv::Point>> contours;
    
    cvtColor(img, imgGrayscale, CV_BGR2GRAY);
    GaussianBlur(imgGrayscale,imgBlurred,cv::Size(5, 5),1.8);
    
    Canny(imgBlurred,imgCanny,50,100);
    findContours(imgCanny, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    vector<cv::Point> ponto;
    sort(contours.begin(), contours.end(), myfunction);
    for (int i = 0; i < contours.size(); i++) {
        
        double peri = arcLength(contours[i], true);
        
        approxPolyDP(contours[i], ponto, 0.02 * peri, true);
        vector<vector<cv::Point>> bosta;
        
        printf("abacate %f   %ld\n", contourArea(ponto), ponto.size());
        bosta.push_back(ponto);
        Scalar color = Scalar(0, 0, 255);
        drawContours(img, bosta, 0, color, 3);
        break;
        
    }
    
    
//    Mat preProcessImage =  [self preProcess:selectImage];
    
//    Mat maxImage  = [self findMaxPolygon:[self cvMatFromUIImage:selectImage]];
    
                            // [self UIImageFromCVMat:preProcessImage]  ;
   
    self.imageView.image = [UIImage UIImageFromCVMat:img];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString* path1 = [documentsDirectory stringByAppendingPathComponent:
                       [NSString stringWithFormat: @"test9.jpg"] ];
    NSData* data1 = UIImageJPEGRepresentation(self.imageView.image , 0.9);
    [data1 writeToFile:path1 atomically:YES];
    NSLog(@"%@",path1);
    
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
    
    weakSelf.imageView.image = [UIImage UIImageFromCVMat:preProcessImage]  ;
    
    NSLog(@"%ld",(long)weakSelf.imageView.image.imageOrientation);  // 0
    weakSelf.label2.text = [NSString stringWithFormat:@"%ld",(long)weakSelf.imageView.image.imageOrientation];
    [weakSelf.picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

// 找到图像上面积最大的外接四边形的四个顶点 vector<cv::Point>
-(Mat)findMaxPolygon:(Mat)image{  // Mat
    
    
    Mat src,gray,bin;
    src = image;
    vector< vector<cv::Point> > contours;
    vector<vector<cv::Point>> squares;
    
    vector<vector<cv::Point> > poly;
    //cv::Point2f src_pt[4];
    cv::Point2f dst_pt[]={
        cv::Point2f( 0.0, 0.0),
        cv::Point2f((P_WIDTH-1)/2, 0),
        cv::Point2f((P_WIDTH-1)/2 , (P_HEIGHT-1)/2),
        cv::Point2f(0, (P_HEIGHT-1)/2)};
    
//    const int idx=-1;
//    const int thick=2;
    vector<cv::Vec4i> hierarchy;
    vector<cv::Point> approx;
    cv::cvtColor(src, gray, CV_BGR2GRAY);
    cv::threshold(gray, bin, 100, 255, cv::THRESH_BINARY|cv::THRESH_OTSU);
    
    //収縮・膨張
    cv::erode(bin, bin, cv::Mat(), cv::Point(-1,-1), 3);
    cv::erode(bin, bin, cv::Mat(), cv::Point(-1,-1), 3);
    cv::dilate(bin, bin, cv::Mat(), cv::Point(-1,-1), 1);
    cv::dilate(bin, bin, cv::Mat(), cv::Point(-1,-1), 1);
 

//    Mat imageCopy  = image.clone();
    cv::findContours(bin, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    
//    vector<vector<cv::Point> > contours  = [self findContours:imageCopy external:YES];
//    NSLog(@"size------------%lu",contours.size());
    
   cv::Point2f src_pt[4];
//    cap >> src ;
//    if (contours.size() == 0)
//        return ; //image
    for (unsigned int j = 0; j < contours.size(); j++){
        approx = contours[j];
        //輪郭を近似する
        cv::approxPolyDP(contours[j], approx, cv::arcLength(contours[j], true)*0.02, true);
        //頂点が4つの場合
        if (approx.size() == 4 && hierarchy[j][2] != -1){
            //4つの頂点を描く
            for (unsigned int k = 0; k < approx.size(); k++){
                cv::circle(src, approx[k], 5,  CV_RGB(255,0,0), 2, 8, 0);
            }
            /*外枠取得用*/
            src_pt[0] = cv::Point2f(approx[0].x,approx[0].y);
            src_pt[1] = cv::Point2f(approx[1].x,approx[1].y);
            src_pt[2] = cv::Point2f(approx[2].x,approx[2].y);
            src_pt[3] = cv::Point2f(approx[3].x,approx[3].y);
            if(approx[0].x > approx[2].x && approx[0].y > approx[2].y){
                src_pt[0] = cv::Point2f(approx[2].x,approx[2].y);
                src_pt[1] = cv::Point2f(approx[1].x,approx[1].y);
                src_pt[2] = cv::Point2f(approx[0].x,approx[0].y);
                src_pt[3] = cv::Point2f(approx[3].x,approx[3].y);
            }
            else if(approx[0].x < approx[2].x && approx[0].y > approx[2].y){
                src_pt[0] = cv::Point2f(approx[1].x,approx[1].y);
                src_pt[1] = cv::Point2f(approx[0].x,approx[0].y);
                src_pt[2] = cv::Point2f(approx[3].x,approx[3].y);
                src_pt[3] = cv::Point2f(approx[2].x,approx[2].y);
            }
            else if(approx[0].x < approx[2].x && approx[0].y < approx[2].y){
                src_pt[0] = cv::Point2f(approx[0].x,approx[0].y);
                src_pt[1] = cv::Point2f(approx[3].x,approx[3].y);
                src_pt[2] = cv::Point2f(approx[2].x,approx[2].y);
                src_pt[3] = cv::Point2f(approx[1].x,approx[1].y);
            }
            else if(approx[0].x > approx[2].x && approx[0].y < approx[2].y){
                src_pt[0] = cv::Point2f(approx[3].x,approx[3].y);
                src_pt[1] = cv::Point2f(approx[2].x,approx[2].y);
                src_pt[2] = cv::Point2f(approx[1].x,approx[1].y);
                src_pt[3] = cv::Point2f(approx[0].x,approx[0].y);
            }
        }
    }

    if(src_pt[0].x != 0){
        // homography 行列を計算
        cv::Mat homography_matrix = cv::getPerspectiveTransform(src_pt, dst_pt);
        
        // 変換
        cv::warpPerspective( src, src, homography_matrix,src.size());
    }
    return bin;
    
//    sort(contours.begin(), contours.end(), conter_area_cmp);
 
#pragma mark - sort ???
    
//    float alpha = 0.0001;
//
//    while (1) {
//        vector<cv::Point> approx = [self approxPolyDP:contours[0] alpha:alpha];
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
   
//    return  approx
 
}


void is_close(vector<cv::Point> p1,vector<cv::Point> p2,int d=10 ){
//    if ((std::abs(p1[0] - p2[0]) < d) && (std::abs(p1[1]-p2[1]) < d)) {
//
//    }
}

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
    
    Mat matImage = [UIImage  cvMatFromUIImage:selectImage];

    // 灰度
    Mat matGrey;
    cvtColor(matImage, matGrey, CV_BGR2GRAY);
    
    // 高斯滤波
    Mat matBlur;
    GaussianBlur(matGrey, matBlur, cv::Size(5,5), 0);
    
    int block_size = 3;

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


#pragma mark - custom method


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
 

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
