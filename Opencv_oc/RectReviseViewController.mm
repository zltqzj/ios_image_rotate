//
//  RectReviseViewController.m
//  Opencv_oc
//
//  Created by zhaojian on 9/27/17.
//  Copyright © 2017 zhaojian. All rights reserved.
//

#import "RectReviseViewController.h"
#import "UIImage+fixOrientation.h"
#import "UIImage+CVMat.h"

using namespace cv;
using namespace std;

@interface RectReviseViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(strong,nonatomic) UIImagePickerController *picker;
@end

@implementation RectReviseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    self.imageView.contentMode =  UIViewContentModeScaleAspectFit;
    
    UIImage *selectImage = [_originImageView.image fixOrientation];
    [self operateImage:selectImage];
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


-(void)operateImage:(UIImage*)selectImage{
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
    sort(contours.begin(), contours.end(), myfunction3);
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
    
    self.originImageView.image = [UIImage UIImageFromCVMat:img];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString* path_contour = [documentsDirectory stringByAppendingPathComponent:
                       [NSString stringWithFormat: @"test9.jpg"] ];
    NSData* data_contour = UIImageJPEGRepresentation(self.originImageView.image , 0.9);
    [data_contour writeToFile:path_contour atomically:YES];
    NSLog(@"%@",path_contour);
    
    Mat dst =  [self scan:[path_contour UTF8String] debug:true];
    self.imageView.image = [UIImage UIImageFromCVMat:dst];
    
    NSString* revise_path = [documentsDirectory stringByAppendingPathComponent:
                       [NSString stringWithFormat: @"test10.jpg"] ];
    NSData* revise_data = UIImageJPEGRepresentation(self.imageView.image , 0.9);
    [revise_data writeToFile:revise_path atomically:YES];
}


#pragma mark - uiimagepicker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
 
    UIImage *selectImage = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation];
    self.originImageView.image = selectImage;
    [self operateImage:selectImage];
    [picker dismissViewControllerAnimated:YES completion:nil];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma  custom method
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
//    threshold(gray, bina, 100, 255, THRESH_BINARY|THRESH_OTSU);
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



bool myfunction3(vector<cv::Point> i, vector<cv::Point> j) {
    
    vector<cv::Point> ponto;
    vector<cv::Point> ponto1;
    
    double peri = arcLength(i, true);
    approxPolyDP(i, ponto, 0.02 * peri, true);
    
    double peri1 = arcLength(j, true);
    approxPolyDP(j, ponto1, 0.02 * peri1, true);
    
    return contourArea(ponto) > contourArea(ponto1);
}



Point2f center(0,0);

Point2f computeIntersect(Vec4i a,Vec4i b)
{
    int x1 = a[0],y1 = a[1],x2 = a[2],y2 = a[3],x3 = b[0],y3 = b[1],x4 = b[2],y4 = b[3];
    
    if (float d = ((float)(x1 - x2)*(y3 - y4)-(y1 - y2)*(x3 - x4)))
    {
        Point2f pt;
        pt.x = ((x1*y2 - y1*x2)*(x3 - x4) - (x1 - x2)*(x3*y4 - y3*x4))/d;
        pt.y = ((x1*y2 - y1*x2)*(y3 - y4) - (y1 - y2)*(x3*y4 - y3*x4))/d;
        return pt;
    }
    else
        return Point2f(-1,-1);
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
 

@end
