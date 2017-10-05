//
//  UIImage+CVMat.h
//  Opencv_oc
//
//  Created by 赵健 on 05/10/2017.
//  Copyright © 2017 zhaojian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>
using namespace cv;
using namespace std;

@interface UIImage (CVMat)

+ (Mat)cvMatFromUIImage:(UIImage *)image;
+(UIImage *)UIImageFromCVMat:(Mat)cvMat;

@end
