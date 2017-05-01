//
//  ViewController.m
//  FEReactiveCocoaDemo
//
//  Created by keso on 2017/5/1.
//  Copyright © 2017年 FlyElephant. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveCocoa.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "RACDelegateProxy.h"
#import "Course.h"

@interface ViewController ()

@property (strong, nonatomic) Course *course;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (weak, nonatomic) IBOutlet UITextField *passWordTextField;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (strong, nonatomic) RACDelegateProxy *textDelegate;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setUp];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"Dealloc %@",[self class]);
}

#pragma mark - Actions

- (IBAction)courseAction:(UIButton *)sender {
    self.course.courseName = [NSString stringWithFormat:@"FlyElephant--%d",arc4random_uniform(25)];
}

#pragma mark - SetUp

- (void)setUp {
    
    self.course = [[Course alloc] init];
    
    [self setKVO];
    [self setTextField];
    [self setCombination];
    [self setButtonAction];
    [self setDelegate];
    [self setNotification];
    [self createSignal];
    [self setMapSignal];
    [self setFilterSignal];
    [self setTakeSkip];
    [self setDelay];
    [self setThrottle];
    [self setDistinctUntilChanged];
    [self setTimeOut];
    [self setIgnore];
}

- (void)setKVO { // KVO 键值对观察
    
    @weakify(self)
    
    [RACObserve(self.course, courseName)
     subscribeNext:^(id x) {
         @strongify(self)
         NSLog(@"键值对变化--%@",x);
         self.nameLabel.text = x;
     }];
}

- (void)setTextField { // TextField 事件监听
    
    @weakify(self)
    [self.textField.rac_textSignal subscribeNext:^(id x) {
       @strongify(self)
       NSLog(@"TextField变化--%@",x);
       self.course.courseName = x;
    }];
}

- (void)setCombination { // 信号组合
    
    id textFieldSignals = @[self.textField.rac_textSignal,self.passWordTextField.rac_textSignal];
    
    @weakify(self);
    
    [[RACSignal combineLatest:textFieldSignals] subscribeNext:^(RACTuple *x) {
        @strongify(self);
        
        NSString *name = [x first];
        NSString *passWord = [x second];
        
        if (name.length && passWord.length) {
            self.loginButton.backgroundColor = [UIColor redColor];
            self.loginButton.userInteractionEnabled = YES;
        } else {
            self.loginButton.backgroundColor = [UIColor darkGrayColor];
            self.loginButton.userInteractionEnabled = NO;
        }
    }];
}

- (void)setButtonAction {
    @weakify(self);
    [[self.loginButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        NSLog(@"用户名:--%@---密码:%@",self.textField.text,self.passWordTextField.text);
    }];
}

- (void)setDelegate {
    @weakify(self);
    self.textDelegate = [[RACDelegateProxy alloc] initWithProtocol:@protocol(UITextFieldDelegate)];
    [[self.textDelegate rac_signalForSelector:@selector(textFieldShouldReturn:)] subscribeNext:^(id x) {
        @strongify(self);
        NSLog(@"代理执行");
        [self.passWordTextField becomeFirstResponder];
    }];
    self.textField.delegate = (id<UITextFieldDelegate>)self.textDelegate;
}

- (void)setNotification {
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil] subscribeNext:^(id x) {
        NSLog(@"键盘弹出事件");
    }];
}

- (void)createSignal {
    //创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"FlyElephant"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    //订阅信号
    [signal subscribeNext:^(id x) {
        NSLog(@"信号值 = %@", x);
    } error:^(NSError *error) {
        NSLog(@"error = %@", error);
    } completed:^{
        NSLog(@"completed");
    }];
}


- (void)setMapSignal {
    [[self.textField.rac_textSignal map:^id(NSString *value) {
        return @(value.length);
    }] subscribeNext:^(id x) {
        NSLog(@"信号量Map:%@",x);
    }];
}

- (void)setFilterSignal {
    [[self.textField.rac_textSignal filter:^BOOL(NSString *value) {
        return [value length] > 5;
    }] subscribeNext:^(id x) {
        NSLog(@"value字符串变换 = %@", x);
    }];
}

- (void)setTakeSkip {
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        [subscriber sendNext:@"2"];
        [subscriber sendNext:@"3"];
        [subscriber sendNext:@"4"];
        [subscriber sendNext:@"5"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *takeSignal = [signal take:2];
    [takeSignal subscribeNext:^(id x) {
        NSLog(@"Take---%@", x);
    } completed:^{
        NSLog(@"Take---completed");
    }];
    
    RACSignal *skipSignal = [signal skip:2];
    [skipSignal subscribeNext:^(id x) {
        NSLog(@"Skip---%@", x);
    } completed:^{
        NSLog(@"Skip---completed");
    }];
}

- (void)setDelay {
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"FlyElephant"];
        [subscriber sendCompleted];
        return nil;
    }] delay:2];
    
    NSLog(@"FlyElephant-delay");
    
    [signal subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

- (void)setThrottle {
    [[self.textField.rac_textSignal throttle:0.5] subscribeNext:^(id x) {
        NSLog(@"Throttle---%@", x);
    }];
}

- (void)setDistinctUntilChanged {
    [[self.textField.rac_textSignal distinctUntilChanged] subscribeNext:^(id x) {
        NSLog(@"防止重复请求:%@",x);
    }];
}

- (void)setTimeOut {
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[RACScheduler mainThreadScheduler] afterDelay:3 schedule:^{
            [subscriber sendNext:@"FlyElephant--TimeOut"];
            [subscriber sendCompleted];
        }];
        return nil;
    }] timeout:2 onScheduler:[RACScheduler mainThreadScheduler]];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"TimeOut---%@", x);
    } error:^(NSError *error) {
        NSLog(@"TimeOut---%@", error);
    }];
}

- (void)setIgnore {
    [[self.textField.rac_textSignal ignore:@"FlyElephant"] subscribeNext:^(id x) {
        NSLog(@"ignore---%@", x);
    }];
}

@end
