//
//  ViewController.m
//  wangyi
//
//  Created by 黄成实 on 2018/8/29.
//  Copyright © 2018年 黄成实. All rights reserved.
//

#import "ViewController.h"
#import <NIMSDK/NIMSDK.h>
#import <NIMAVChat/NIMAVChat.h>
#import "NTESGLView.h"


@interface ViewController ()<NIMNetCallManagerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userIdTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UILabel *statuLabel;
@property (weak, nonatomic) IBOutlet UITextField *calleeTF;
@property (weak, nonatomic) IBOutlet UIView *myView;
@property (weak, nonatomic) IBOutlet UIView *otherView;
@property (weak, nonatomic) IBOutlet UIButton *muteBtn;
@property (strong,nonatomic)NTESGLView *remoteGLView;
@property (assign, nonatomic) UInt64 callId;

@end

@implementation ViewController{
    Boolean isMute;
    Boolean isAudioType;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
}


-(void)initView{
    _userIdTF.text = @"test2";
    _passwordTF.text = @"123456";
}


- (IBAction)doLogin:(id)sender {
    NSString *userId = _userIdTF.text;
    NSString *password = _passwordTF.text;
    

    __weak ViewController *weakSelf = self;
    [[[NIMSDK sharedSDK] loginManager] login:userId token:password completion:^(NSError * _Nullable error) {
        if(error == nil){
            weakSelf.statuLabel.text = @"登录成功!";
        }else{
            weakSelf.statuLabel.text = @"登录失败!";
        }
    }];
}


//拨号
- (IBAction)doCall:(id)sender {
    //先初始化 option 参数
    NIMNetCallOption *option = [self getVideoParamOption];
    option.extendMessage = @"音视频请求扩展信息";
    option.apnsContent = @"通话请求";
    option.apnsSound = @"video_chat_tip_receiver.aac";
    
    [self addWaterMark];

    //指定通话类型为 视频通话
    NIMNetCallMediaType type = NIMNetCallMediaTypeVideo;
    
    if(_calleeTF.text == nil || [_calleeTF.text isEqualToString:@""]){
        _statuLabel.text = @"请填写被叫号码";
        return;
    }
    NSArray *callee = @[_calleeTF.text];
    //开始通话
    __weak ViewController *weakSelf = self;
    [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
    [[NIMAVChatSDK sharedSDK].netCallManager start:callee type:type option:option completion:^(NSError *error, UInt64 callID) {
        if (!error) {
            //通话发起成功
            weakSelf.statuLabel.text = @"通话发起成功";

        }else{
            //通话发起失败
            weakSelf.statuLabel.text = @"通话发起失败";

        }
    }];
}

//被叫接听
- (IBAction)doRespond:(id)sender {
   
    
    //同意接听
    BOOL accept = YES;
    
    __weak ViewController *weakSelf = self;
    //被叫响应通话
    [[NIMAVChatSDK sharedSDK].netCallManager response:_callId accept:accept option: [self getVideoParamOption] completion:^(NSError *error, UInt64 callID) {
        //链接成功
        if (!error) {
            weakSelf.statuLabel.text = [NSString stringWithFormat:@"%lld被叫接听中...",weakSelf.callId];
        }
        //链接失败
        else{
        }
    }];
}



//挂断
- (IBAction)doHangup:(id)sender {
    Uint64 callId = [[NIMAVChatSDK sharedSDK].netCallManager currentCallID];
    [[NIMAVChatSDK sharedSDK].netCallManager hangup:callId];
    [[NIMAVChatSDK sharedSDK].netCallManager hangup:_callId];
    _statuLabel.text = @"已挂断";
}

//静音
- (IBAction)doMute:(id)sender {
    isMute = !isMute;
    if([[NIMAVChatSDK sharedSDK].netCallManager setMute:isMute]){
        if(isMute){
            [_muteBtn setTitle:@"静音：开" forState:UIControlStateNormal];
        }else{
            [_muteBtn setTitle:@"静音：关" forState:UIControlStateNormal];
        }
    }
    
}

//音视频切换
- (IBAction)changeAudioOrVideo:(id)sender {
    if(isAudioType){
        [[NIMAVChatSDK sharedSDK].netCallManager switchType:NIMNetCallMediaTypeVideo];
    }else{
          [[NIMAVChatSDK sharedSDK].netCallManager switchType:NIMNetCallMediaTypeAudio];
    }
    isAudioType = !isAudioType;
    
}

#pragma mark 回调


 //来电回调
-(void)onReceive:(UInt64)callID from:(NSString *)caller type:(NIMNetCallMediaType)type message:(NSString *)extendMessage{
    //弹出来电通知VC
    _callId = callID;
//    UIViewController *vc;
    switch (type) {
        case NIMNetCallTypeVideo:{
            _statuLabel.text = [NSString stringWithFormat:@"收到%lld的视频邀请",callID];

        }
            break;
        case NIMNetCallTypeAudio:{
            _statuLabel.text = [NSString stringWithFormat:@"收到%lld的语音邀请",callID];
//            vc = [[NTESAudioChatViewController alloc] initWithCaller:caller callId:callID];
        }
            break;
        default:
            break;
    }
    

}


//主叫收到被叫相应
-(void)onResponse:(UInt64)callID from:(NSString *)callee accepted:(BOOL)accepted{
    if(accepted){
         _statuLabel.text = [NSString stringWithFormat:@"%@主叫叫接听中...",callee];
    }else{
        _statuLabel.text = [NSString stringWithFormat:@"%@被叫拒接",callee];
    }
}

//被叫通话中
-(void)onResponsedByOther:(UInt64)callID accepted:(BOOL)accepted{
       _statuLabel.text = @"被叫正在通话中";
}


//通话建立成功
-(void)onCallEstablished:(UInt64)callID{
    _statuLabel.text = @"通话建立成功";
}


//挂断回调
-(void)onHangup:(UInt64)callID by:(NSString *)user{
    _statuLabel.text = @"已挂断";
}

//通话异常断开
-(void)onCallDisconnected:(UInt64)callID withError:(NSError *)error{
    _statuLabel.text = @"通话异常断开";
}


#pragma mark 视频部分
- (void)onLocalDisplayviewReady:(UIView *)displayView
{
    displayView.frame = CGRectMake(0, 0, _myView.bounds.size.width, _myView.bounds.size.height);
    [self.myView addSubview:displayView];

    _remoteGLView = [[NTESGLView alloc]initWithFrame:CGRectMake(0, 0, _otherView.bounds.size.width, _otherView.bounds.size.height)];
    [self.otherView addSubview:_remoteGLView];
    [self startCapture];
    
}


//开始采集视频
-(void)startCapture{
    NIMNetCallVideoCaptureParam *videoParam = [[NIMNetCallVideoCaptureParam alloc]init];
    videoParam.preferredVideoQuality = NIMNetCallVideoQuality720pLevel;
    //视频采集数据回调
    videoParam.videoHandler =^(CMSampleBufferRef sampleBuffer){
        //对采集数据进行外部前处理
//        [self addWaterMark];
        //把 sampleBuffer 数据发送给 SDK 进行显示，编码，发送
        [[NIMAVChatSDK sharedSDK].netCallManager sendVideoSampleBuffer:sampleBuffer];
    };
    [[NIMAVChatSDK sharedSDK].netCallManager startVideoCapture:videoParam];
}

//停止采集视频
-(void)stopCapture{
    [[NIMAVChatSDK sharedSDK].netCallManager stopVideoCapture];
}


//接收视频回调
- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    [_remoteGLView render:yuvData width:width height:height];
}

//动态添加水印
-(void)addWaterMark{
    //获取 image 水印图片
    UIImage *image = [UIImage imageNamed:@"icon"];
    
    //位置为右上 在预览画面的右上角
    NIMNetCallWaterMarkLocation location = NIMNetCallWaterMarkLocationCenter;
    
    //设置水印具体位置 由于水印位置为右上 所以相对于右上角(以右上角为原点) 向下10像素 向左10像素 图片宽50像素 高50像素
    CGRect rect = CGRectMake(10, 10, 50, 50);
    
    //先清除当前水印
    [[NIMAVChatSDK sharedSDK].netCallManager cleanWaterMark];
    
    //添加静态水印
    [[NIMAVChatSDK sharedSDK].netCallManager addWaterMark:image rect:rect location: location];
}


//获取视频配置
-(NIMNetCallOption *)getVideoParamOption{
    //初始化option
    NIMNetCallOption *option = [[NIMNetCallOption alloc] init];
    
    //指定 option 中的 videoCaptureParam 参数
    NIMNetCallVideoCaptureParam *param = [[NIMNetCallVideoCaptureParam alloc] init];
    param.preferredVideoQuality = NIMNetCallVideoQuality720pLevel;
    param.videoCrop  = NIMNetCallVideoCrop16x9;
    
    NIMNetCallVideoProcessorParam *videoProcessorParam = [[NIMNetCallVideoProcessorParam alloc] init];
    videoProcessorParam.filterType = NIMNetCallFilterTypeZiran;
    
    param.videoProcessorParam = videoProcessorParam;
    option.videoCaptureParam = param;
    
    //打开初始为前置摄像头
    param.startWithBackCamera = NO;
    
    return option;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [_calleeTF resignFirstResponder];
    [_passwordTF resignFirstResponder];
    [_userIdTF resignFirstResponder];
}
@end
