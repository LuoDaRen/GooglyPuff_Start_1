//  PhotoManager.m
//  PhotoFilter
//
//  Created by A Magical Unicorn on A Sunday Night.
//  Copyright (c) 2014 Derek Selander. All rights reserved.
//

@import CoreImage;
@import AssetsLibrary;
#import "PhotoManager.h"

@interface PhotoManager ()
@property (nonatomic, strong) NSMutableArray *photosArray;
@end

@implementation PhotoManager

+ (instancetype)sharedManager
{
    //单列设计模式：用于当一个类只能有一个实例的时候，或是某种不可以有多个实例同时存在的虚拟资源或是系统属性比如一个程序的某个引擎或是数据。addPhoto
    static PhotoManager *sharedPhotoManager = nil;
    if (!sharedPhotoManager) {
        sharedPhotoManager = [[PhotoManager alloc] init];
        sharedPhotoManager->_photosArray = [NSMutableArray array];
    }

    return sharedPhotoManager;
}

//*****************************************************************************/
#pragma mark - Unsafe Setter/Getters
//*****************************************************************************/

- (NSArray *)photos
{
    return _photosArray;
}

- (void)addPhoto:(Photo *)photo
{
    if (photo) {
        [_photosArray addObject:photo];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self postContentAddedNotification];
        });
    }
}

//*****************************************************************************/
#pragma mark - Public Methods
//*****************************************************************************/

- (void)downloadPhotosWithCompletionBlock:(BatchPhotoDownloadingCompletionBlock)completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        __block NSError *error;
        
        dispatch_group_t downloadGroup = dispatch_group_create();
        
        for (NSInteger i = 0; i < 3; i++) {
            NSURL *url;
            switch (i) {
                case 0:
                    url = [NSURL URLWithString:kOverlyAttachedGirlfriendURLString];
                    break;
                case 1:
                    url = [NSURL URLWithString:kSuccessKidURLString];
                    break;
                case 2:
                    url = [NSURL URLWithString:kLotsOfFacesURLString];
                    break;
                default:
                    break;
            }
            
            dispatch_group_enter(downloadGroup);
            
            Photo *photo = [[Photo alloc] initwithURL:url
                                  withCompletionBlock:^(UIImage *image, NSError *_error) {
                                      if (_error) {
                                          error = _error;
                                      }
                                      dispatch_group_leave(downloadGroup);
                                  }];
            
            [[PhotoManager sharedManager] addPhoto:photo];
        }
        dispatch_group_wait(downloadGroup, DISPATCH_TIME_FOREVER);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(error);
            }
        });
    });
}

//*****************************************************************************/
#pragma mark - Private Methods
//*****************************************************************************/

- (void)postContentAddedNotification
{
    static NSNotification *notification = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notification = [NSNotification notificationWithName:kPhotoManagerAddedContentNotification object:nil];
    });
    
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
}

@end
