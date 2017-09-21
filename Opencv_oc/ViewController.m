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
@interface ViewController () <UIImagePickerControllerDelegate>
@property(strong,nonatomic) UIImagePickerController* picker;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    
    
//    @property (nonatomic, copy) void(^bk_didFinishPickingMediaBlock)(UIImagePickerController *, NSDictionary *);

    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)click{
    _picker = [[UIImagePickerController alloc] init];
    _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    _picker.allowsEditing = YES;
    
   __weak typeof(self) weakSelf = self;
    
    _picker.bk_didFinishPickingMediaBlock = ^(UIImagePickerController *picker , NSDictionary *info){
 
        NSDictionary* dict = [info objectForKey:UIImagePickerControllerMediaMetadata];
        
        weakSelf.label.text = [NSString stringWithFormat:@"%@",dict[@"Orientation"]];
        UIImage *selectImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        weakSelf.imageView.image = [selectImage fixOrientation];
 
        NSLog(@"%ld",(long)weakSelf.imageView.image.imageOrientation);  // 0
        weakSelf.label2.text = [NSString stringWithFormat:@"%ld",(long)weakSelf.imageView.image.imageOrientation];
        [weakSelf.picker dismissViewControllerAnimated:YES completion:nil];
    };
    _picker.bk_didCancelBlock  = ^(UIImagePickerController *picker){
         
    };
    [self presentViewController:_picker animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
