//
//  LPAccountInfoViewController.m
//  LesPark
//
//  Created by he on 16/7/12.
//
//

#import "LPAccountInfoViewController.h"
#import "LPAccountBindingController.h"
// Delete
#import "LPWebViewController.h"
#import "LPValidationViewController.h"
#import "LPAccountSecurityController.h"
#import "LPLandViewController.h"

#import "LPAccountBindInfoCell.h"
#import "LPSettingArrowCell.h"
#import "LPAccountInfoTableFooter.h"

#import "LPAccountInfo.h"

#import "LPPrimordialThirdLoginManager.h"

#import "LPLiveIMManager.h"

#import "Convertor.h"
#import "LPAlertHelper.h"
#import "LPToast.h"
#import "User+keychain.h"
#import "LPLoginPrivacyView.h"

#import <SobotKit/SobotKit.h>

#import "LPBlurNavigationBarView.h"
#import "LPAccountChangePwdViewController.h"
#import "LPPhoneCodeViewController.h"
#import "LPForgotPasswordViewController.h"

#import "LPAccountInfoNewGetAuthCodeViewController.h"

static NSString *const kBindCellIdentifier   = @"BindCell";
static NSString *const kNormalCellIdentifier = @"NormalCell";

@interface LPAccountInfoViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy) NSArray *titles;

@property (nonatomic, strong) LPAccountInfo *accountInfo;

@end

@implementation LPAccountInfoViewController

- (void)dealloc
{
    NSLog(@"LPAccountInfoViewController#dealloc...");
    NSLog(@"dasdasdasdasd");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //替换为自定义navigationbar
    self.navigationController.navigationBar.translucent = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.navigationController.view setBackgroundColor:[UIColor whiteColor]];
    
    LPBlurNavigationBarView *bar = [LPBlurNavigationBarView blurNaivgationBarView];
    [bar addLeftBtnTarget:self action:@selector(onClickLeftBtn:)];
    [bar addTitleLabelWithTitle:MyLocal(@"new_me_account")];
    
    [self.view addSubview:bar];
    
    
    self.titles = @[@[LPLocalizedString(@"new_me_profile_verify",  @"我的认证")],
                    @[LPLocalizedString(@"Bind social accounts",  @"账号绑定"),
//                    LPLocalizedString(@"Credit",@"个人等级"),
//                      LPLocalizedString(@"account_safe",@"账户安全"),
//                      LPLocalizedString( @"me_setpassword", @"设置密码"),
                      LPLocalizedString(@"close_my_account",  @"注销账号")]];
    
    CGRect frame = self.tableView.frame;
    frame.origin.y += bar.frame.size.height;
    frame.size.height -= bar.frame.size.height;
    self.tableView.frame = frame;
    [self.view addSubview:self.tableView];
}


- (void)requestAccountInfo
{
    [LPHTTPClient GET:@"/v2/modify_password" parameters:nil onSuccess:^(NSURLSessionDataTask *task, id response) {
        NSInteger errorCode = [response[@"error"] integerValue];
        if (errorCode == 0) {
            NSDictionary *data = response[@"data"];
            [self.accountInfo resetAccountPageInfo];
            if (data[@"mask_phone"]) {
                self.accountInfo.bindSecPhoneCode = data[@"mask_phone"];
            }
            if (data[@"phone"]) {
                self.accountInfo.bindPhoneCode = data[@"phone"];
            }
            if (data[@"has_set_passwd"]) {
                self.accountInfo.isSettedPassword = [data[@"has_set_passwd"] boolValue];
            }
            if (data[@"email"]) {
                self.accountInfo.bindedEmail = data[@"email"];
            }
            // || !IsEmptyOrNull(self.accountInfo.bindedEmail)
            if (!IsEmptyOrNull(self.accountInfo.bindPhoneCode)) {
                self.titles = @[@[LPLocalizedString(@"new_me_profile_verify",  @"我的认证")],
                                @[LPLocalizedString(@"Bind social accounts",  @"账号绑定"),
                                  self.accountInfo.isSettedPassword?LPLocalizedString(@"CHANGE_PASSWORD", @"修改密码"):MyLocal(@"me_setpassword"),
                                  LPLocalizedString(@"close_my_account",  @"注销账号")]];
            }else {
                self.titles = @[@[LPLocalizedString(@"new_me_profile_verify",  @"我的认证")],
                                @[LPLocalizedString(@"Bind social accounts",  @"账号绑定"),
                                  LPLocalizedString(@"close_my_account",  @"注销账号")]];
            }
            [self.tableView reloadData];
        }
    } onFailure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    [self requestAccountInfo];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

#pragma mark - actions
- (void)onClickLeftBtn:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setUserData:(NSMutableDictionary *)userData
{
    _userData = userData;
    
    self.accountInfo = [[LPAccountInfo alloc] initWithDictionary:userData];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.titles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return IsOutOfArrayCount(section, self.titles) ? 0 : [self.titles[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    if (IsOutOfArrayCount(section, _titles) || IsOutOfArrayCount(row, _titles[section])) {
        return [UITableViewCell new];
    }
    
    NSString *title = self.titles[section][row];
    
    if ([title isEqualToString:LPLocalizedString(@"Bind social accounts",  @"账号绑定")]) {
        LPAccountBindInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:kBindCellIdentifier forIndexPath:indexPath];
        cell.accountInfo = nil;
        cell.title = title;
        [cell updateBottomLine:YES];
        return cell;
    }else {
       LPSettingArrowCell *cell = [tableView dequeueReusableCellWithIdentifier:kNormalCellIdentifier forIndexPath:indexPath];
        cell.title = title;
        cell.cellSwitch.hidden = YES;
        cell.arrowImageView.hidden = NO;
        UIView *la = [cell.contentView viewWithTag:1000];
        if (la) {
            [la removeFromSuperview];
        }
        if ([title isEqualToString:LPLocalizedString(@"new_me_profile_verify",  @"我的认证")]) {
            if ([User getInstance].real_verify != 1 && [User getInstance].video_verify != 1) {
                UILabel *label = [[UILabel alloc] init];
                label.font = [UIFont systemFontOfSize:15];
                label.textColor = UIColorFromRGB(0xa8a8a8);
                label.text = MyLocal(@"PK_VERTIFY_NOTVERTIFY");
                label.tag = 1000;
                [cell.contentView addSubview:label];
                [label mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(cell.arrowImageView.mas_left).offset(-2);
                    make.centerY.equalTo(cell.arrowImageView.mas_centerY);
                }];
            }
        }
        [cell updateBottomLine:(row == [_titles[section] count]-1)];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 8;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"headerView"];
    return view;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 49.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    if (IsOutOfArrayCount(section, _titles) || IsOutOfArrayCount(row, _titles[section])) {
        return;
    }
    
    NSString *title = self.titles[section][row];
    if ([title isEqualToString:LPLocalizedString(@"Bind social accounts",  @"账号绑定")]) {
        [LPGrowingIOWrapper trackAccountInfomationClickEvent:1];
        LPAccountBindingController *bindingController = [LPAccountBindingController new];
        bindingController.accountInfo = self.accountInfo;
        [self.navigationController pushViewController:bindingController animated:YES];
    }
    else if ([title isEqualToString:LPLocalizedString(@"new_me_profile_verify",  @"我的认证")]) {
        LPValidationViewController *vc = [[LPValidationViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([title isEqualToString:LPLocalizedString(@"Credit",@"个人等级")]) {
        LPWebViewController *webViewController = [[LPWebViewController alloc] initWithURLString:[MY_CREDIT_LINK stringByAppendingString:[[self generateCommonHeaders] queryString]]];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    else if ([title isEqualToString:LPLocalizedString(@"account_safe",@"账户安全")]) {
        LPAccountSecurityController *securityController = [LPAccountSecurityController new];
        [self.navigationController pushViewController:securityController animated:YES];
    }
    else if ([title isEqualToString:LPLocalizedString(@"close_my_account",  @"注销账号")]) {
        [LPGrowingIOWrapper trackAccountInfomationClickEvent:4];
        [LPAlertHelper showWithTitle:LPLocalizedString(@"new_chat_tip_tip", nil)
                             message:LPLocalizedString(@"close_account_tips", nil)
                   cancelButtonTitle:LPLocalizedString(@"new_cancel", nil)
                   otherButtonTitles:@[LPLocalizedString(@"new_nearby_vchat_exit_tip_btn", nil)]
                            tapBlock:^(NSInteger buttonIndex) {
                                if (buttonIndex == LPAlertHelperButtonTypeCancel) return;
                                [self deleteAccount];
                            }];
    }else if ([title isEqualToString:self.accountInfo.isSettedPassword?LPLocalizedString(@"CHANGE_PASSWORD", @"修改密码"):MyLocal(@"me_setpassword")]) {
        
        [LPGrowingIOWrapper trackAccountInfomationClickEvent:3];
        if (!IsEmptyOrNull(self.accountInfo.bindPhoneCode)) {
            LPAccountInfoNewGetAuthCodeViewController *auth = [LPAccountInfoNewGetAuthCodeViewController new];
            auth.accountInfo = self.accountInfo;
            auth.title = self.accountInfo.isSettedPassword?LPLocalizedString(@"CHANGE_PASSWORD", @"修改密码"):MyLocal(@"me_setpassword");
            [self.navigationController pushViewController:auth animated:YES];
        }
        else {
            [alertClass showMessage:LPLocalizedString(@"Sorry,you're logging with the 3rd-party,can't change password!", nil)
                 alertType:AlertTypeInfo
                      view:self.view
                afterDelay:2.0
            useDetailLable:YES];
        }
        
    }else if ([title isEqualToString:LPLocalizedString( @"me_setpassword", @"设置密码")]) {
        if ([[_UD valueForKey:[NSString stringWithFormat:@"LOGIN_%@",[User getInstance].UserID]] integerValue] == 3) {
            [alertClass showMessage:LPLocalizedString(@"Sorry,you're logging with the 3rd-party,can't change password!", nil)
                          alertType:AlertTypeInfo
                               view:self.view
                         afterDelay:2.0
                     useDetailLable:YES];
        } else {
            if ([[_UD valueForKey:[NSString stringWithFormat:@"LOGIN_%@",[User getInstance].UserID]] integerValue] == 1) {
                LPPhoneCodeViewController *ctl = [LPPhoneCodeViewController new];
                ctl.ctlType = LPPhoneCodeCtlTypeSetPwd;
                ctl.showContactLisa = YES;
                [self.navigationController pushViewController:ctl animated:YES];
            } else {
                LPForgotPasswordViewController *forgotPwdVC = [LPForgotPasswordViewController new];
                forgotPwdVC.type = LPLoginTypeEmail;
                forgotPwdVC.showContactLisa = YES;
                [self.navigationController pushViewController:forgotPwdVC animated:YES];
            }
        }
    }
}

#pragma mark - Actions

/// 删除账号
- (void)deleteAccount
{
    [User clearKeyChainUser];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [LPHTTPClient POST:@"setting/deactivate"
            parameters:nil
             onSuccess:^(NSURLSessionDataTask *task, id response) {
                 NSInteger error = [[response objectForKey:@"error"] integerValue];
                 if(error != 0) {
                     [LPToast toast:response[@"msg"] inView:self.view];
                     return;
                 }
                 
                 [self onLogoutSuccess];
                 
             } onFailure:^(NSURLSessionDataTask *task, NSError *error) {
                 [MBProgressHUD hideHUDForView:self.view animated:YES];
             }];
}

- (void)onLogoutSuccess
{
    [User removeInstance];
    //remove nsuserdefaults
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d removeObjectForKey:@"ExpireDate"];
    [d removeObjectForKey:@"PassCode"];
    [d removeObjectForKey:@"MatchUserID"];
    //clear message key
    [d removeObjectForKey:@"message_all"];
    //clear user info
    [_UD removeObjectForKey:[NSString stringWithFormat:@"LOGIN_%@",[User getInstance].UserID]];
    [User removeInstance];
    [User getInstance].accessToken = nil;
    [User getInstance].refreshToken = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lp_default_refresh_token"];
    
    [_UD removeObjectForKey:kInstalledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[LPLiveIMManager sharedInstance] logout];
    
    
    // 取消授权
    [LPPrimordialThirdLoginManager logoutAllPlatform];
    
    LPLandViewController *landViewController = [[LPLandViewController alloc] initWithNibName:nil
                                                                                      bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:landViewController];
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate.window setRootViewController:nav];
    [delegate.window makeKeyAndVisible];
    [Convertor clearMenu];
    
    [[LPHTTPClient sharedClient] reloadConfig];
    
    [ZCLibClient closeAndoutZCServer:YES];
    
    BOOL showPrivacyView = ![_UD boolForKey:kInstalledKey] && [LPLocalHelper isInChina];
    if (showPrivacyView) {
        LPLoginPrivacyView *view = [[LPLoginPrivacyView alloc] init];
        [view showInView:delegate.window.rootViewController.view];
    }
}

#pragma mark - Private

- (NSMutableDictionary*)generateCommonHeaders
{
    NSMutableDictionary *commonHeaders = [NSMutableDictionary dictionary];
    [commonHeaders setValue:CURRENT_BUNDLE_ID forKey:@"bundle_id"];
    [commonHeaders setValue:CURRENT_LANGUAGE forKey:@"lang"];
    [commonHeaders setValue:CURRENT_LOCALE forKey:@"locale"];
    [commonHeaders setValue:[User getInstance].UserID forKey:@"user_id"];
    [commonHeaders setValue:[User getInstance].accessToken forKey:@"token"];
    [commonHeaders setValue:[NSString stringWithFormat:@"%d",(int)[User getInstance].Stars] forKey:@"star"];
    [commonHeaders setValue:[NSString stringWithFormat:@"%d",(int)[User getInstance].Credits] forKey:@"credit"];
    [commonHeaders setValue:[NSString stringWithFormat:@"%ld",(long)[[NSTimeZone defaultTimeZone] secondsFromGMT]] forKey:@"tz"];
    return commonHeaders;
}

#pragma makr - Getters

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
        _tableView.sectionHeaderHeight = 8;
        _tableView.sectionFooterHeight = CGFLOAT_MIN;
        
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableFooterView = [[LPAccountInfoTableFooter alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, [LPAccountInfoTableFooter viewHeight])];
        
        [_tableView registerClass:[LPAccountBindInfoCell class] forCellReuseIdentifier:kBindCellIdentifier];
        [_tableView registerClass:[LPSettingArrowCell class] forCellReuseIdentifier:kNormalCellIdentifier];
        [_tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"headerView"];
    }
    return _tableView;
}
   
@end
