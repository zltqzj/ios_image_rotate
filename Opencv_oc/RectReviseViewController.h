//
//  RectReviseViewController.h
//  Opencv_oc
//
//  Created by zhaojian on 9/27/17.
//  Copyright © 2017 zhaojian. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <opencv2/opencv.hpp>


using namespace cv;
@interface RectReviseViewController : UIViewController

@property(weak,nonatomic) IBOutlet UIButton* btn;
@property(weak,nonatomic) IBOutlet UIImageView* originImageView;
@property(weak,nonatomic) IBOutlet UIImageView* imageView;

-(Mat)scan:(String)file debug:(bool)debug ;

@end
