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
 
@interface ViewController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(strong,nonatomic) UIImagePickerController *picker;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self operateImage:[_originImageView.image fixOrientation]];
}


-(void)click{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        _picker = [[UIImagePickerController alloc] init];
        _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        _picker.allowsEditing = NO;
        _picker.delegate = self;
        [self presentViewController:_picker animated:YES completion:nil];
    }
    else{
        NSLog(@"设备不支持相机");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"该设备不支持相机" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
   
}

#pragma mark - imagepicker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    __weak typeof(self) weakSelf = self;

    NSDictionary* dict = [info objectForKey:UIImagePickerControllerMediaMetadata];
    
    weakSelf.label.text = [NSString stringWithFormat:@"%@",dict[@"Orientation"]];
    UIImage *selectImage = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation];
    self.originImageView.image = selectImage;
    [self operateImage:selectImage];

    [weakSelf.picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma custom method
bool myfunction2(std::vector<cv::Point> i, std::vector<cv::Point> j) {
    return cv::contourArea(i) > cv::contourArea(j);
}
bool myfunctionOrder(cv::Point2f i, cv::Point2f j) {
    return i.y > j.y;
}



-(void)operateImage:(UIImage*)selectImage{
    //    UIImage *selectImage = [_originImageView.image fixOrientation];
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
        if (ponto.size() == 4) {
            printf("\nVIVA USTRA %d, %d\n", ponto[0].x, ponto[0].y);
            printf("\nVIVA USTRA %d, %d\n", ponto[1].x, ponto[1].y);
            printf("\nVIVA USTRA %d, %d\n", ponto[2].x, ponto[2].y);
            printf("\nVIVA USTRA %d, %d\n", ponto[3].x, ponto[3].y);
            printf("abacate %f   %ld\n", contourArea(ponto), ponto.size());
            bosta.push_back(ponto);
            Scalar color = Scalar(0, 0, 255);
            drawContours(img, bosta, 0, color, 3);
            break;
        }
    }
    
    self.imageView.image = [UIImage UIImageFromCVMat:img];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString* path_contours = [documentsDirectory stringByAppendingPathComponent:
                       [NSString stringWithFormat: @"test9.jpg"] ];
    NSData* data_contours = UIImageJPEGRepresentation(self.imageView.image , 0.9);
    [data_contours writeToFile:path_contours atomically:YES];
    NSLog(@"%@",path_contours);
}

// 多边形拟合，拟合精度为轮廓周长的alpha
-(vector<cv::Point>)approxPolyDP:(vector<cv::Point> )contour alpha:(float)alpha{
    double epsilon = alpha * arcLength(contour, true) ;
    vector<cv::Point>  dest_contour ;
    approxPolyDP(contour, dest_contour, epsilon, true);
    return dest_contour ;
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
 
    // 二值化
    adaptiveThreshold(matBlur, matBinary, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY_INV, block_size, 5) ;
    Mat kernel = getStructuringElement(MORPH_RECT, cv::Size(block_size,block_size));
    
    // 形态学运算函数，闭运算
    Mat matClose;
    morphologyEx(matBinary, matClose, MORPH_CLOSE, kernel,cv::Point(-1,-1),3);
    return matClose;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
