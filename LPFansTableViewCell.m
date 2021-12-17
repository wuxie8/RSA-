//
//  LPFansTableViewCell.m
//  LesPark
//
//  Created by zhudf on 15/8/27.
//
//

#import "LPFansTableViewCell.h"
#import "LPFansCellView.h"
#import "AppDelegate.h"
#import "LPGrowingIOWrapper.h"
#import "LPLogService.h"
#import "LPUserRequest.h"
#import "LPBindCoupleService.h"
#import "Convertor.h"

@interface LPFansTableViewCell()

@property (nonatomic, strong) LPFansCellView *cellView;

@property (nonatomic, assign) BOOL following;

@property (nonatomic, assign) BOOL followed;
@property (nonatomic, assign) FriendsType friendType;

@property (nonatomic, strong) UIView *underLine;

@property (nonatomic, assign) BOOL specFollowing;//YES 表示特别关注了，NO表示没有特别关注

// 强制关掉不是会员的隐身状态
// @property (assign, nonatomic) BOOL isNinja;

@end

@implementation LPFansTableViewCell

+ (CGFloat)cellHeight
{
    return [LPFansCellView viewHeight];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _showOnlineState = YES;
//        self.delegate = self;
        _friendType = FriendsTypeUnknow;
        self.backgroundColor = [UIColor whiteColor];
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews
{
    _cellView = [[LPFansCellView alloc] initWithFrame:CGRectMake(15, 0, SCREEN_WIDTH-15, [[self class] cellHeight])];
    _cellView.showOnlineState = _showOnlineState;
    _cellView.hideDistance = _hideDistance;
    _cellView.showFollowBtn = !_hideFollowButton && _notUseSwipeFollowButton;
    __weak typeof(self) weakSelf = self;
    _cellView.onClickChatBtnBlock = ^{
        if ([weakSelf.fans_delegate respondsToSelector:@selector(fansTableViewCell:chatToUser:)]) {
            [weakSelf.fans_delegate fansTableViewCell:weakSelf chatToUser:weakSelf.data];
        }
    };
    _cellView.onClickFollowBtnBlock = ^{
        [weakSelf followUserOrNot];
    };

    _cellView.onClickAlreadyFollowBtnBlock = ^{
        [weakSelf cancleFollow];
    };
    
    _cellView.onClickSpecialFollowBtnBlock = ^{
        [weakSelf cancleFollow];
    };
    
    _cellView.onClickDeleteRecomendBtnBlock = ^{
        [weakSelf deleteRecomendClick];
    };
    
    _cellView.onClickDeleteBtnBlock = ^{
        [weakSelf deleteBlockUserClick];
    };
    
    _cellView.onClickAvatarBlock = ^{
        if (weakSelf.fans_delegate && [weakSelf.fans_delegate respondsToSelector:@selector(fansTableViewCell:avatarClickToUser:)]) {
            [weakSelf.fans_delegate fansTableViewCell:weakSelf avatarClickToUser:weakSelf.data];
        }
    };
    
    _cellView.onClickMatchBtnBlock = ^{
        if (weakSelf.fans_delegate && [weakSelf.fans_delegate respondsToSelector:@selector(fansTableViewCell:didClickMatchBtn:)]) {
            [weakSelf.fans_delegate fansTableViewCell:weakSelf didClickMatchBtn:weakSelf.data];
        }
    };

    [self.contentView addSubview:_cellView];
    
    ///
    self.underLine = [UIView new];
    self.underLine.backgroundColor = UIColorFromRGB(0xebebeb);
    [self.contentView addSubview:self.underLine];
    [self.underLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_cellView.nameLabel);
        make.trailing.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(.5);
    }];
}

- (void)underLineHidden:(BOOL)hidden
{
    self.underLine.hidden = hidden;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    _friendType = FriendsTypeUnknow;
    [_cellView prepareForReuse];
}

- (void)toUserLivingRoom:(NSDictionary *)liveData
{
    NSDictionary *data = liveData[@"related_live"];
    if (IsEmpty(data)) {
        return ;
    }
    LPLiveModel *live = [LPLiveModel mj_objectWithKeyValues:data];
    
    /// 退出悬浮窗
    [AppDelegate quitSuspendWindwo];
    
    LPLiveScrollViewController *ctl = [[LPLiveScrollViewController alloc] init];
    live.pageSource = self.pageSource;
    ctl.data = @[live].mutableCopy;
    ctl.isAutoSwitchRoom = YES;
    ctl.followedUserId = _data[@"user_id"];
    ctl.hidesBottomBarWhenPushed = YES;
    [[Convertor getTopViewController].navigationController pushViewController:ctl animated:YES];
}

#pragma mark - publicMethods
- (void)bindData:(NSMutableDictionary *)data friendType:(FriendsType)friendType
{
    _friendType = friendType;
    self.data = data;
}

- (void)setData:(NSMutableDictionary *)data
{
    _data = [data mutableCopy];
    __weak typeof(self) weakSelf = self;
    // 是否显示头像的直播状态
    _cellView.isShowAvatarLiveStatus = self.isShowAvatarLiveStatus;
    _cellView.isShowLiveStatus = self.isShowLiveStatus;
    if (self.isShowAvatarLiveStatus || self.isShowLiveStatus) {
        // 猜你喜欢跳转直播间
        _cellView.onClickLiveAvaterBlock = ^{
            [weakSelf toUserLivingRoom:data];
        };
    }
    else {
        _cellView.onClickLiveAvaterBlock = nil;
    }
    
    if (_cellWidth > 0) {
        _cellView.width = _cellWidth - _cellView.left;
    }
    else {
        _cellView.width = self.contentView.width - _cellView.left;
    }
    _cellView.isRecomendView = self.isRecommend;
    
    [_cellView bindData:_data friendType:_friendType];
    
    _following = [[data objectForKey:@"following"] boolValue];
    //点赞页面的数据 key 不同
    if ([data objectForKey:@"is_follow_like_user"]) {
        _following = [[data objectForKey:@"is_follow_like_user"] boolValue];;
    }
    _followed = [[data objectForKey:@"followed"] boolValue];
    
    _specFollowing = [[data objectForKey:@"special_following"] boolValue];
    
    _cellView.specialFollowBtn.hidden = YES;
    
    BOOL isSelf = [data[@"user_id"] isEqualToString:[User getInstance].UserID];
    if (isSelf) {
        _cellView.addFollowBtn.hidden = YES;
        _cellView.alreadyFollowBtn.hidden = YES;
        _cellView.mutuallyFollowBtn.hidden = YES;
        return;
    }
    
    if (_hideFollowButton == NO) {
        if (_following && _followed) {
            _cellView.addFollowBtn.hidden = YES;
            _cellView.alreadyFollowBtn.hidden = YES;
            if (_hideMutuallyButton == NO) {
                _cellView.mutuallyFollowBtn.hidden = NO;
            }
        }
        else if (_following) {
            _cellView.mutuallyFollowBtn.hidden = YES;
            _cellView.addFollowBtn.hidden = YES;
            if (_hideAlreadyButton == NO) {
                _cellView.alreadyFollowBtn.hidden = NO;
            }
        }
        else {
            _cellView.addFollowBtn.hidden = NO;
            _cellView.alreadyFollowBtn.hidden = YES;
            _cellView.mutuallyFollowBtn.hidden = YES;
        }
        
        if (_specFollowing) {
            _cellView.addFollowBtn.hidden = YES;
            _cellView.mutuallyFollowBtn.hidden = YES;
            _cellView.alreadyFollowBtn.hidden = YES;
            _cellView.specialFollowBtn.hidden = NO;
        }
    }
    else {
        _cellView.addFollowBtn.hidden = YES;
        _cellView.alreadyFollowBtn.hidden = YES;
        _cellView.mutuallyFollowBtn.hidden = YES;
    }
    
    if (self.isRecommend && !_following) {
        _cellView.deleteRecomendBtn.hidden = NO;
    }else {
        _cellView.deleteRecomendBtn.hidden = YES;
    }
}

- (void)changeMode:(BOOL)isUnread
{
    if (isUnread) {
        self.backgroundColor = UIColorFromRGB(0xfafafa);
        _cellView.avatarBackGroundView.image = [UIImage imageNamed:@"avatar_mask_fafafa"];
        [_cellView.avatarLiveStatusBorderView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_cellView.avatarImageView);
            make.height.equalTo(_cellView.avatarLiveStatusBorderView.mas_width);
            make.width.equalTo(_cellView.avatarImageView).multipliedBy(52.0/49.0).offset(-3.5);
        }];
        
    }
    else{
        self.backgroundColor = [UIColor whiteColor];
        _cellView.avatarBackGroundView.image = [UIImage imageNamed:@"avatar_mask"];
        [_cellView.avatarLiveStatusBorderView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_cellView.avatarImageView);
            make.height.equalTo(_cellView.avatarLiveStatusBorderView.mas_width);
            make.width.equalTo(_cellView.avatarImageView).multipliedBy(52.0/49.0);
        }];
    }
}

#pragma mark - private methods
- (void)deleteBlockUserClick {
    if ([self.fans_delegate respondsToSelector:@selector(fansTableViewCell:deleteBlockUserData:)]) {
        [self.fans_delegate fansTableViewCell:self deleteBlockUserData:self.data];
    }
}
// 删除推荐关注
- (void)deleteRecomendClick {
    __weak typeof(self) weakSelf = self;
    if (_fans_delegate && [_fans_delegate respondsToSelector:@selector(fansTableViewCell:didDeleteRecomend:)]) {
        [LPLogService addlogContent:@"删除推荐关注" topic:@"推荐关注" source:@"删除推荐关注" isError:NO];
        [LPUserRequest scoreRecommendUser:self.data[@"user_id"] score:-1 completion:nil];
        
        [_fans_delegate fansTableViewCell:weakSelf didDeleteRecomend:YES];
    }
}

/// 取消关注或拉黑
- (void)cancleFollow {
    __weak typeof(self) weakSelf = self;
    AppDelegate *delegate = [AppDelegate sharedInstance];
    UITabBarController *tabbar =  (UITabBarController *)delegate.window.rootViewController;
    UINavigationController *navigationController = tabbar.selectedViewController;
    UIViewController *contro = navigationController.viewControllers.lastObject;
    if (_parentCtrl) {
        contro = _parentCtrl;
    }
    
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:_data[@"nickname"] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancleFollow = [UIAlertAction actionWithTitle:MyLocal(@"new_homepage_unfollow") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf followUserOrNot];
    }];
    /// 拉黑
    UIAlertAction *black = [UIAlertAction actionWithTitle:MyLocal(@"new_chat_blacklist") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIAlertController *blackAlert = [UIAlertController alertControllerWithTitle:nil message:MyLocal(@"blacklist_popup_text") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *sure = [UIAlertAction actionWithTitle:MyLocal(@"new_nearby_vchat_exit_tip_btn") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf pullBlack];
        }];
        UIAlertAction *cancle = [UIAlertAction actionWithTitle:MyLocal(@"new_cancel") style:UIAlertActionStyleCancel handler:nil];
        [blackAlert addAction:sure];
        [blackAlert addAction:cancle];
        [contro presentViewController:blackAlert animated:YES completion:nil];
        
    }];
    
    
    if (_friendType == FriendsTypeFollowers || _friendType == FriendsTypeFollowing || _friendType == FriendsTypeFriends) {
        //好友，粉丝，关注页面弹出窗口变化，其它不变
       
        if (self.following) {
            [alert addAction:cancleFollow];
        }
        
        if (_followed) {
            /// 移除粉丝
            UIAlertAction *removeFans = [UIAlertAction actionWithTitle:MyLocal(@"new_chat_btn_remove") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UIAlertController *blackAlert = [UIAlertController alertControllerWithTitle:nil message:MyLocal(@"remove_fans_popup") preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *sure = [UIAlertAction actionWithTitle:MyLocal(@"new_nearby_vchat_exit_tip_btn") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSLog(@"移除粉丝==========");
                    
                    [weakSelf removeFans];
                    
                }];
                UIAlertAction *cancle = [UIAlertAction actionWithTitle:MyLocal(@"new_cancel") style:UIAlertActionStyleCancel handler:nil];
                [blackAlert addAction:sure];
                [blackAlert addAction:cancle];
                [contro presentViewController:blackAlert animated:YES completion:nil];
                
            }];
            [alert addAction:removeFans];
        }
        
        [alert addAction:black];
        
        NSString *specFollowText;
        if (_specFollowing) {
            specFollowText = MyLocal(@"new_chat_btn_removespecial");
        }else {
            specFollowText = MyLocal(@"new_chat_btn_special");
        }
        
        
        /// 特别关注
        UIAlertAction *setSpecFollow = [UIAlertAction actionWithTitle:specFollowText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [weakSelf setSpecialFollow];
            
            
        }];
        
        if (self.cellView.addFollowBtn.hidden == YES) {
            [alert addAction:setSpecFollow];
        }
        
    } else {
        
        [alert addAction:cancleFollow];
        [alert addAction:black];
    }
    
    if (IsEmpty([User getInstance].coupleId)) {
        /// 邀请绑定情侣
        UIAlertAction *coupleAction = [UIAlertAction actionWithTitle:MyLocal(@"new_homepage_couple_invite_btn") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [LPBindCoupleService inviteUserBindCoupleUserId:self.data[@"user_id"] nickName:self.data[@"nickname"] avatar:self.data[@"avatar"] block:^(BOOL success) {
                
            }];
        }];
        [alert addAction:coupleAction];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:MyLocal(@"new_cancel") style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:cancel];
    
    
    [contro presentViewController:alert animated:YES completion:nil];
    
    
}

- (void)setSpecialFollow {
    
    __weak typeof(self) weakSelf = self;
    
    if (_specFollowing) {
        
        [LPLogService addlogContent:@"取消特别关注" topic:@"特别关注" source:@"设置特别关注" isError:NO];
        NSLog(@"取消特别关注");
        [HttpUtils unSpecialFollowUser:self.data[@"user_id"] params:nil onCompletion:^(NSDictionary *data, NSError *error) {
            if (error) {
                [Toast show:error.localizedDescription];
                [LPLogService addlogContent:[NSString stringWithFormat:@"取消特别关注失败:%@",error] topic:@"特别关注" source:@"设置特别关注" isError:YES];
                return;
            }
            [LPLogService addlogContent:@"取消特别关注成功" topic:@"特别关注" source:@"设置特别关注" isError:NO];
            
            [Toast show:MyLocal(@"special_follow_removed")];
            
            weakSelf.specFollowing = NO;
            weakSelf.data[@"special_following"] = [NSNumber numberWithBool:NO];
            if (_fans_delegate && [_fans_delegate respondsToSelector:@selector(fansTableViewCell:didSetSpecialFollow:)]) {
                [_fans_delegate fansTableViewCell:weakSelf didSetSpecialFollow:NO];
            }
        }];
    }else {
        
        
        if ([User getInstance].IsVip) {
            
            [LPLogService addlogContent:@"添加特别关注" topic:@"特别关注" source:@"设置特别关注" isError:NO];
            
            [HttpUtils specialFollowUser:self.data[@"user_id"] param:@{@"action_type": @"special_follow"} onCompletion:^(NSDictionary *data, NSError *error) {
                if (error) {
                    [Toast show:error.localizedDescription];
                    [LPLogService addlogContent:[NSString stringWithFormat:@"添加特别关注失败:%@",error] topic:@"特别关注" source:@"设置特别关注" isError:YES];
                    return;
                }
                
                [LPLogService addlogContent:@"添加特别关注成功" topic:@"特别关注" source:@"设置特别关注" isError:NO];
                
                [Toast show:MyLocal(@"special_follow_has_set")];
                
                weakSelf.specFollowing = YES;
                weakSelf.data[@"special_following"] = [NSNumber numberWithBool:YES];
                if (_fans_delegate && [_fans_delegate respondsToSelector:@selector(fansTableViewCell:didSetSpecialFollow:)]) {
                    [_fans_delegate fansTableViewCell:weakSelf didSetSpecialFollow:YES];
                }
            }];
            
        }else {
            if (_fans_delegate && [_fans_delegate respondsToSelector:@selector(fansTableViewCell:didSetSpecialFollow:)]) {
                [_fans_delegate fansTableViewCell:weakSelf didSetSpecialFollow:YES];
            }
        }
    }
}

- (void)removeFans {
    
    __weak typeof(self) weakSelf = self;
    [LPLogService addlogContent:@"移出粉丝" topic:@"特别关注" source:@"移出粉丝" isError:NO];
    
    [HttpUtils removeFans:self.data[@"user_id"] onCompletion:^(NSDictionary *data, NSError *error) {
        
        if (error) {
            [Toast show:error.localizedDescription];
            [LPLogService addlogContent:[NSString stringWithFormat:@"移出粉丝失败:%@",error] topic:@"特别关注" source:@"移出粉丝" isError:YES];
            
            return;
            
        }
        
        [LPLogService addlogContent:@"移出粉丝成功" topic:@"特别关注" source:@"移出粉丝" isError:NO];
        
        _followed = !_followed;
        [weakSelf.data setObject:[NSNumber numberWithBool:self.followed] forKey:@"followed"];
        
        _cellView.data = weakSelf.data;
        
        if (_following && _followed) {
            _cellView.addFollowBtn.hidden = YES;
            _cellView.alreadyFollowBtn.hidden = YES;
            if (_hideMutuallyButton == NO) {
                _cellView.mutuallyFollowBtn.hidden = NO;
            }
        }
        else if (_following) {
            _cellView.mutuallyFollowBtn.hidden = YES;
            _cellView.addFollowBtn.hidden = YES;
            if (_hideAlreadyButton == NO) {
                _cellView.alreadyFollowBtn.hidden = NO;
            }
        }
        else {
            _cellView.addFollowBtn.hidden = NO;
            _cellView.alreadyFollowBtn.hidden = YES;
            _cellView.mutuallyFollowBtn.hidden = YES;
        }
        if (_specFollowing) {
            _cellView.addFollowBtn.hidden = YES;
            _cellView.mutuallyFollowBtn.hidden = YES;
            _cellView.alreadyFollowBtn.hidden = YES;
            _cellView.specialFollowBtn.hidden = NO;
        }
        
        
        if (_fans_delegate && [_fans_delegate respondsToSelector:@selector(fansTableViewCell:didRemoveFans:)]) {
            [_fans_delegate fansTableViewCell:weakSelf didRemoveFans:YES];
        }
        
    }];
}


- (void)pullBlack {
    __weak typeof(self) weakSelf = self;
    [LPLogService addlogContent:@"拉黑" topic:@"特别关注" source:@"拉黑" isError:NO];
    
    [HttpUtils blockUser:_data[@"user_id"] params:nil onCompletion:^(NSDictionary *data, NSError *error) {
        if (!error) {
            [LPLogService addlogContent:@"拉黑成功" topic:@"特别关注" source:@"拉黑" isError:NO];
            [LPToast toast:MyLocal(@"ERROR_5001") inView:[UIApplication sharedApplication].keyWindow];
            if (_fans_delegate && [_fans_delegate respondsToSelector:@selector(fansTableViewCell:pullBlack:)]) {
                [_fans_delegate fansTableViewCell:weakSelf pullBlack:YES];
            }
        }else {
            [Toast show:error.localizedDescription];
            [LPLogService addlogContent:[NSString stringWithFormat:@"拉黑失败:%@",error] topic:@"特别关注" source:@"拉黑" isError:YES];
        }
    }];
}
- (void)followUserOrNot
{
    _following = !_following;
    [self updateFollowStatus];
    __weak typeof(self) weakSelf = self;
    if (_following) {
        if (self.isRecommend) {
            _cellView.deleteRecomendBtn.hidden = YES;
        }
        if (_friendType == FriendsTypeFollowing && self.isRecommend) {
            ///个人-关注页 为你推荐 关注量
            [LPGrowingIOWrapper trackMyHomeRecommedFollowNumber];
        }
        
        if (_friendType == FriendsTypeFollowers && self.isRecommend) {
            ///个人-粉丝页 为你推荐 关注量
            [LPGrowingIOWrapper trackMyFansRecommedFollowNumber];
        }
        
        if (_friendType == FriendsTypeFriends && self.isRecommend) {
            ///个人-好友页 为你推荐 关注量
            [LPGrowingIOWrapper trackMyFriendRecommedFollowNumber];
        }
        
        
        if (self.isRecommend) {
            [HttpUtils recomFollowUser:_data[@"user_id"] WithDaGuanId:_data[@"user_id"] WithDaGuanSource:3 params:nil onCompletion:^(NSDictionary *data, NSError *error) {
                if (error) {
                    [Toast show:error.localizedDescription];
                    [weakSelf updateFollowStatus];
                    if (weakSelf.isRecommend) {
                       _cellView.deleteRecomendBtn.hidden = NO;
                    }
                }
                else {
                    
                    if (weakSelf.isRecommend) {
                        if ([weakSelf.fans_delegate respondsToSelector:@selector(fansTableViewCell:didRecomendFollow:)]) {
                            [weakSelf.fans_delegate fansTableViewCell:weakSelf didRecomendFollow:YES];
                        }
                    }else {
                        if ([weakSelf.fans_delegate respondsToSelector:@selector(fansTableViewCell:didFollowOrNot:)]) {
                            [weakSelf.fans_delegate fansTableViewCell:weakSelf didFollowOrNot:weakSelf.following];
                        }
                    }
                }
            }];
        }else {
            [HttpUtils followUser:_data[@"user_id"] params:nil onCompletion:^(NSDictionary *data, NSError *error) {
                if (error) {
                    [Toast show:error.localizedDescription];
                    [weakSelf updateFollowStatus];
                    if (weakSelf.isRecommend) {
                       _cellView.deleteRecomendBtn.hidden = NO;
                    }
                }
                else {
                    
                    if (weakSelf.isRecommend) {
                        if ([weakSelf.fans_delegate respondsToSelector:@selector(fansTableViewCell:didRecomendFollow:)]) {
                            [weakSelf.fans_delegate fansTableViewCell:weakSelf didRecomendFollow:YES];
                        }
                    }else {
                        if ([weakSelf.fans_delegate respondsToSelector:@selector(fansTableViewCell:didFollowOrNot:)]) {
                            [weakSelf.fans_delegate fansTableViewCell:weakSelf didFollowOrNot:weakSelf.following];
                        }
                    }
                }
            }];
        }
    }
    else {
        if (self.isRecommend) {
            _cellView.deleteRecomendBtn.hidden = NO;
        }
        [HttpUtils unfollowUser:_data[@"user_id"] params:nil onCompletion:^(NSDictionary *data, NSError *error) {
            if (error) {
                [Toast show:error.localizedDescription];
                [weakSelf updateFollowStatus];
                if (weakSelf.isRecommend) {
                    _cellView.deleteRecomendBtn.hidden = YES;
                }
            }
            else {
                
                if (weakSelf.isRecommend) {
                    if ([weakSelf.fans_delegate respondsToSelector:@selector(fansTableViewCell:didRecomendFollow:)]) {
                        [weakSelf.fans_delegate fansTableViewCell:weakSelf didRecomendFollow:NO];
                    }
                }else {
                    if ([weakSelf.fans_delegate respondsToSelector:@selector(fansTableViewCell:didFollowOrNot:)]) {
                        [weakSelf.fans_delegate fansTableViewCell:weakSelf didFollowOrNot:weakSelf.following];
                    }
                }
            }
        }];
    }
}

- (void)updateFollowStatus
{
    if (self.hideFollowButton) {
        return;
    }
    if ([self.data.allKeys containsObject:@"is_follow_like_user"]) {
        [self.data setObject:[NSNumber numberWithBool:self.following] forKey:@"is_follow_like_user"];
    }
    else {
        [self.data setObject:[NSNumber numberWithBool:self.following] forKey:@"following"];
    }
    _cellView.data = self.data;
    
    if (_following && _followed) {
        _cellView.addFollowBtn.hidden = YES;
        _cellView.alreadyFollowBtn.hidden = YES;
        if (_hideMutuallyButton == NO) {
            _cellView.mutuallyFollowBtn.hidden = NO;
        }
    }
    else if (_following) {
        _cellView.mutuallyFollowBtn.hidden = YES;
        _cellView.addFollowBtn.hidden = YES;
        if (_hideAlreadyButton == NO) {
            _cellView.alreadyFollowBtn.hidden = NO;
        }
    }
    else {
        _cellView.addFollowBtn.hidden = NO;
        _cellView.alreadyFollowBtn.hidden = YES;
        _cellView.mutuallyFollowBtn.hidden = YES;
    }
    _cellView.specialFollowBtn.hidden = YES;
    if (_specFollowing && _following) {
        _cellView.specialFollowBtn.hidden = NO;
    }
    
}

#pragma mark -

- (void)setShowOnlineState:(BOOL)showOnlineState
{
    _showOnlineState = showOnlineState;
    _cellView.showOnlineState = showOnlineState;
}

- (void)setHideDistance:(BOOL)hideDistance
{
    _hideDistance = hideDistance;
    _cellView.hideDistance = hideDistance;
}

- (void)setShowChatBtn:(BOOL)showChatBtn
{
    _showChatBtn = showChatBtn;
    _cellView.showChatBtn = showChatBtn;
}

- (void)setShowRedDot:(BOOL)showRedDot
{
    _showRedDot = showRedDot;
    _cellView.showRedDot = showRedDot;
}

- (void)setNotUseSwipeFollowButton:(BOOL)notUseSwipeFollowButton
{
    _notUseSwipeFollowButton = notUseSwipeFollowButton;
    _cellView.showFollowBtn = !_hideFollowButton && _notUseSwipeFollowButton;
}

- (void)setHideFollowButton:(BOOL)hideFollowButton
{
    _hideFollowButton = hideFollowButton;
    _cellView.showFollowBtn = !_hideFollowButton && _notUseSwipeFollowButton;
}

- (void)setHideDescLabel:(BOOL)hideDescLabel
{
    _hideDescLabel = hideDescLabel;
    _cellView.hideDescLabel = hideDescLabel;
    NSLog(@"ichksufksdhfis ");
}
- (void)setHideAlreadyButton:(BOOL)hideAlreadyButton {
    _hideAlreadyButton = hideAlreadyButton;
    _cellView.alreadyFollowBtn.hidden = _hideAlreadyButton;
}
- (void)setHideMutuallyButton:(BOOL)hideMutuallyButton {
    _hideMutuallyButton = hideMutuallyButton;
    _cellView.mutuallyFollowBtn.hidden = hideMutuallyButton;
}

- (void)setHidenSpecialButton:(BOOL)hidenSpecialButton
{
    _hidenSpecialButton = hidenSpecialButton;
    _cellView.specialFollowBtn.hidden = hidenSpecialButton;
}

- (void)setShowDeleteButton:(BOOL)showDeleteButton {
    _showDeleteButton = showDeleteButton;
    _cellView.deleteButton.hidden = !showDeleteButton;
}

- (void)avatarImageViewUserInteractionEnabled:(BOOL)succ {
    _cellView.avatarImageView.userInteractionEnabled = succ;
}

- (void)matchButtonShowOrHidden:(BOOL)succ {
    _cellView.matchBtn.hidden = succ;
    return;
}

@end
