//
//  LPFansTableViewCell.h
//  LesPark
//
//  Created by zhudf on 15/8/27.
//
//

#import "LPFriendSearchViewController.h"
@class LPFansTableViewCell,LPFansCellView;

@protocol LPFansTableViewCellDelegate <NSObject>

@optional
/// 拉黑
- (void)fansTableViewCell:(LPFansTableViewCell *)cell pullBlack:(BOOL)black;
- (void)fansTableViewCell:(LPFansTableViewCell *)cell didFollowOrNot:(BOOL)follow;
- (void)fansTableViewCell:(LPFansTableViewCell *)cell chatToUser:(NSDictionary *)userData;
- (void)fansTableViewCell:(LPFansTableViewCell *)cell avatarClickToUser:(NSDictionary *)userData;
- (void)fansTableViewCell:(LPFansTableViewCell *)cell deleteBlockUserData:(NSDictionary *)userData;

// 移出粉丝
- (void)fansTableViewCell:(LPFansTableViewCell *)cell didRemoveFans:(BOOL)remove;
// 跳转特别关注设置页
- (void)fansTableViewCell:(LPFansTableViewCell *)cell didSetSpecialFollow:(BOOL)specialFollow;

// 删除推荐
- (void)fansTableViewCell:(LPFansTableViewCell *)cell didDeleteRecomend:(BOOL)deleteRecomend;

// 推荐关注
- (void)fansTableViewCell:(LPFansTableViewCell *)cell didRecomendFollow:(BOOL)followRecomend;

/// 点击匹配按钮
- (void)fansTableViewCell:(LPFansTableViewCell *)cell didClickMatchBtn:(NSDictionary *)userData;

@end

@interface LPFansTableViewCell : UITableViewCell


@property (nonatomic, strong) NSMutableDictionary *data;

/* 访客列表不显示在线,显示最后访问时间 */
@property (nonatomic, assign) BOOL showOnlineState;

@property (nonatomic, assign) BOOL hideFollowButton;

@property (nonatomic, assign) BOOL hideAlreadyButton;
@property (nonatomic, assign) BOOL hideMutuallyButton;
@property (nonatomic, assign) BOOL hidenSpecialButton;
@property (nonatomic, assign) BOOL showDeleteButton;

@property (nonatomic, assign) BOOL notUseSwipeFollowButton;

@property (nonatomic, assign) BOOL hideDistance;

@property (nonatomic, weak  ) id<LPFansTableViewCellDelegate> fans_delegate;
@property (nonatomic, weak) UIViewController *parentCtrl;

/// 显示聊天按钮，用于我的匹配列表
@property (nonatomic, assign) BOOL showChatBtn;
/// 头像右上角显示红点，用于我的匹配列表
@property (nonatomic, assign) BOOL showRedDot;

@property (nonatomic, assign) CGFloat cellWidth;

@property (nonatomic, assign) BOOL hideDescLabel;
//是否是特别关注的数据
@property (nonatomic, assign) BOOL isSpecial;
// 是否是推荐关注的数据
@property (nonatomic, assign) BOOL isRecommend;

// 显示头像直播状态
@property (nonatomic, assign) BOOL isShowAvatarLiveStatus;
// 显示直播状态
@property (nonatomic, assign) BOOL isShowLiveStatus;

// 埋点记录页面
@property (nonatomic, copy) NSNumber *pageSource;

- (void)underLineHidden:(BOOL)hidden;

- (void)bindData:(NSMutableDictionary *)data friendType:(FriendsType)friendType;

+ (CGFloat)cellHeight;

- (void)changeMode:(BOOL)isUnread;

//userInteractionEnabled 改变cell上头像是否可点击 默认为NO；
- (void)avatarImageViewUserInteractionEnabled:(BOOL)succ;
/// 寻她喜欢我的 是否显示匹配按钮 默认hidden
- (void)matchButtonShowOrHidden:(BOOL)succ;
- (void)test{
    
}
@end
