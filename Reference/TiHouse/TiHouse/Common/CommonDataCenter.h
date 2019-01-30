//
//  CommonDataCenter.h
//  TiHouse
//
//  Created by Teen Ma on 2018/4/10.
//  Copyright © 2018年 Confused小伟. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KnowledgeAdvertisementsDataModel;

@interface CommonDataCenter : NSObject

+ (instancetype)shareCommonDataCenter;

@property (nonatomic, strong ) KnowledgeAdvertisementsDataModel *knowledgeAdvertisementsModel;

@property (nonatomic, assign ) BOOL                             hasKnowledgeAdvertisements;//是否有广告

@end