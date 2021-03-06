//
//  MixProtocolStrategy.m
//  CJMix
//
//  Created by wangshiwen on 2019/1/28.
//  Copyright © 2019 Chan. All rights reserved.
//

#import "MixProtocolStrategy.h"
#import "MixConfig.h"
#import "MixFileStrategy.h"
#import "MixDefine.h"

@interface MixProtocolStrategy ()

@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, strong) NSArray<NSString *> *whiteFolderList; //白名单文件夹

@property (nonatomic, strong) NSMutableArray<NSString *> *resetProtocolList; //新的protocol名称
@property (nonatomic, strong) NSMutableDictionary *protocolDict;

@end

@implementation MixProtocolStrategy

+ (BOOL)startWithPath:(NSString *)path {
    
    MixProtocolStrategy *strategy = [[MixProtocolStrategy alloc] initWithRootPath:path];
    BOOL result = [strategy initResetProtocolData];
    if (!result) {
        MixLog(@"初始化ResetProtocolData数据失败\n");
        return NO;
    }
    result = [strategy findOldProtocol];
    if (!result) {
        MixLog(@"查找旧Protocol失败\n");
        return NO;
    }
    result = [strategy replaceProtocolQuote];
    if (!result) {
        MixLog(@"替换Protocol失败\n");
        return NO;
    }
    
    
    return YES;
}

- (instancetype)initWithRootPath:(NSString *)rootPath
{
    self = [super init];
    if (self) {
        _protocolDict = [NSMutableDictionary dictionaryWithCapacity:1];
        _rootPath = rootPath;
        [self initWhiteData];
    }
    return self;
}

#pragma mark - Private

- (void)initWhiteData {

    self.whiteFolderList = [MixConfig sharedSingleton].shieldPaths;
}

#pragma mark - 初始化新的protocol名称列表
- (BOOL)initResetProtocolData {
    
    //NSString *path = @"/Users/wangsw/CJMix/Reference/cache/protocol.json";
//    NSData *data = [NSData dataWithContentsOfFile:path];
//    if (data) {
//        NSError *error = nil;
//        id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
//        if ([result isKindOfClass:NSArray.class]) {
//            _resetProtocolList = [NSMutableArray arrayWithArray:result];
//        }
//    }
    
    if (!_resetProtocolList) {
        _resetProtocolList = [[NSMutableArray alloc] initWithCapacity:1];
        [self recursiveFile:[MixConfig sharedSingleton].referenceAllFile resetList:_resetProtocolList];
    }
    
    //保存到文件中
//    NSString *path = @"/Users/wangsw/CJMix/Reference/cache/protocol.json";
//    NSData *data=[NSJSONSerialization dataWithJSONObject:_resetProtocolList options:NSJSONWritingPrettyPrinted error:nil];
//    NSString *jsonStr=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    [jsonStr writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    return YES;
}

- (void)recursiveFile:(NSArray *)files resetList:(NSMutableArray *)list {
    
    for (MixFile *file in files) {
        if (file.subFiles.count>0) {
            [self recursiveFile:file.subFiles resetList:list];
        }else if (file.fileType == MixFileTypeH ||
                  file.fileType == MixFileTypeM ||
                  file.fileType == MixFileTypeMM ||
                  file.fileType == MixFileTypePch) {
            
            NSString *string = file.data;
            NSArray *lineList = [string componentsSeparatedByString:@"\n"];
            for (NSInteger index =0; index<lineList.count; index++) {
                NSString *lineString = lineList[index];
                NSString *tmpString = [lineString copy];
                if (![lineString containsString:@"@protocol"]) {
                    continue;
                }
                //去除空格
                tmpString = [lineString stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSRange curRange = [tmpString rangeOfString:@"(?<=@protocol).*(?=<)" options:NSRegularExpressionSearch];
                if (curRange.location == NSNotFound)
                    continue;
                NSString *curStr = [NSString stringWithFormat:@"%@%@",  [MixConfig sharedSingleton].mixPrefix, [tmpString substringWithRange:curRange]];
                if (![list containsObject:curStr]) {
                    [list addObject:curStr];
                }
            }
        }
    }
}

#pragma mark - 对旧的protocol名称进行处理

//查好旧的protocol
- (BOOL)findOldProtocol {
    
    [self recursiveFile:[MixConfig sharedSingleton].allFile];
    
    return YES;
}

- (void)recursiveFile:(NSArray *)files {
    
    for (MixFile *file in files) {
        if (file.subFiles.count>0) {
            if (![self checkIsWhiteFolder:file]) {
                [self recursiveFile:file.subFiles];
            }
        }else if (file.fileType == MixFileTypeH ||
            file.fileType == MixFileTypeM ||
            file.fileType == MixFileTypeMM ||
            file.fileType == MixFileTypePch) {
            
            NSString *string = file.data;
            
            if (![string containsString:@"@protocol"]) {//可过滤大部分文件
                continue;
            }
            
            NSArray *lineList = [string componentsSeparatedByString:@"\n"];
            NSMutableArray *tmpList = [NSMutableArray arrayWithArray:lineList];
            for (NSInteger index =0; index<lineList.count; index++) {
                NSString *lineString = lineList[index];
                NSString *tmpString = [lineString copy];
                //去除空格
                tmpString = [lineString stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSRange curRange = [tmpString rangeOfString:@"(?<=@protocol).*(?=<)" options:NSRegularExpressionSearch];
                if (curRange.location == NSNotFound)
                    continue;
                NSString *curStr = [tmpString substringWithRange:curRange];
                //替换新protocol
                NSString *resetProtocol = self.resetProtocolList.firstObject;
                if (!resetProtocol) {
                    MixLog(@"新的protocol个数不足,无法替换完全\n");
                    return;
                }
                tmpString = [lineString stringByReplacingOccurrencesOfString:curStr withString:resetProtocol];
                [tmpList replaceObjectAtIndex:index withObject:tmpString];
                
                //保存数据
                [self.resetProtocolList removeObjectAtIndex:0];
                [self.protocolDict setObject:resetProtocol forKey:curStr];
            }
            string = [tmpList componentsJoinedByString:@"\n"];
            if (![string isEqualToString:file.data]) { //保存
                file.data = string;
                [MixFileStrategy writeFileAtPath:file.path content:file.data];
            }
        }
    }
}

//替换protocol的使用
- (BOOL)replaceProtocolQuote {
    
    [self recursiveReplaceProtocolWithFiles:[MixConfig sharedSingleton].allFile];
    
    return YES;
}

- (void)recursiveReplaceProtocolWithFiles:(NSArray *)files {
    
    NSMutableDictionary *dict = self.protocolDict;
    //遍历文件列表
    for (MixFile *file in files) {
        if (file.subFiles.count>0) {
            [self recursiveReplaceProtocolWithFiles:file.subFiles];
        }else if (file.fileType == MixFileTypeH ||
                  file.fileType == MixFileTypeM ||
                  file.fileType == MixFileTypeMM ||
                  file.fileType == MixFileTypePch) {
            //
            NSString *string = file.data;

            //简单的过滤
            NSMutableDictionary *findDict = [NSMutableDictionary dictionaryWithCapacity:1];
            for (NSString *oldProtocol in dict) {
                if ([string containsString:oldProtocol]) {
                    [findDict setObject:dict[oldProtocol] forKey:oldProtocol];
                }
            }
            if (findDict.count==0) {
                continue;
            }
            
            
            NSArray *lineList = [string componentsSeparatedByString:@"\n"];
            NSMutableArray *tmpList = [NSMutableArray arrayWithArray:lineList];
            for (NSInteger index =0; index<lineList.count; index++) {
                NSString *lineString = lineList[index];
                NSString *tmpString = [lineString copy];
                for (NSString *oldProtocol in findDict) {
                    //简单的判断
                    if (![lineString containsString:oldProtocol]) {
                        continue;
                    }
                    NSString *newProtocol = findDict[oldProtocol];
                    //去空格处理
                    NSString *removeSpaceString = [lineString stringByReplacingOccurrencesOfString:@" " withString:@""];
                    //第一种  id<xxDelagate>   一行只有一个delegate
                    NSString *key = [NSString stringWithFormat:@"id<%@>", oldProtocol];
                    if ([removeSpaceString containsString:key]) {
                        NSRange curRange = [tmpString rangeOfString:@"(?<=id).*(?=>)" options:NSRegularExpressionSearch];
                        if (curRange.location != NSNotFound && curRange.length>0) {
                            NSString *oldStr = [tmpString substringWithRange:curRange];
                            NSRange curRange2 = [oldStr rangeOfString:@"<"];
                            if (curRange2.location != NSNotFound) {
                                oldStr = [oldStr substringFromIndex:curRange2.location+1];
                                curRange = NSMakeRange(curRange.location+curRange2.location+1, oldStr.length);
                            }
                            NSString *newStr = [oldStr stringByReplacingOccurrencesOfString:oldProtocol withString:newProtocol];
                            tmpString = [tmpString stringByReplacingCharactersInRange:curRange withString:newStr];
                            continue;
                        }
                    }
                    //第2种  @protocol xxxDelegate;  @protocol xxxDelegate, oooDelegate;
                    NSRange curRange = [removeSpaceString rangeOfString:@"(?<=@protocol).*(?=;)" options:NSRegularExpressionSearch];
                    if (curRange.location != NSNotFound && curRange.length>0) {
                        NSArray *delegateList = [tmpString componentsSeparatedByString:@","];
                        NSMutableArray *delegateTmpList = [NSMutableArray arrayWithArray:delegateList];
                        for (NSInteger subIndex=0; subIndex<delegateList.count; subIndex++) {
                            NSString *sub = delegateList[subIndex];
                            if (sub.length == 0) {
                                continue;
                            }
                            NSString *protocolString = [sub copy];
                            NSRange range = [protocolString rangeOfString:@"@protocol"];
                            if (range.location != NSNotFound) {
                                protocolString = [protocolString substringFromIndex:range.location+range.length];
                            }
                            range = [protocolString rangeOfString:@";"];
                            if (range.location != NSNotFound) {
                                protocolString = [protocolString substringToIndex:range.location];
                            }
                            if ([[protocolString stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:oldProtocol]) {
                                NSString *newStr = [sub stringByReplacingOccurrencesOfString:oldProtocol withString:newProtocol];
                                [delegateTmpList replaceObjectAtIndex:subIndex withObject:newStr];
                            }
                        }
                        tmpString = [delegateTmpList componentsJoinedByString:@","];
                    }
                    //第3种 @protocol(xxdelegate)
                    curRange = [tmpString rangeOfString:@"(?<=@protocol\\().*(?=\\))" options:NSRegularExpressionSearch];
                    if (curRange.location != NSNotFound && curRange.length>0) {
                        NSString *curStr = [tmpString substringWithRange:curRange];
                        //正则有问题  先这样处理
                        NSRange range = [curStr rangeOfString:@")"];
                        if (range.location != NSNotFound) {
                            curStr = [curStr substringToIndex:range.location];
                        }
                        if ([curStr isEqualToString:oldProtocol]) {
                            tmpString = [tmpString stringByReplacingOccurrencesOfString:oldProtocol withString:newProtocol];
                            continue;
                        }
                    }
                    //第4种 跟在类申明后面的   <xxDelegate1,xxDelegate2>
                    NSArray *delegateList = [tmpString componentsSeparatedByString:@","];
                    NSMutableArray *delegateTmpList = [NSMutableArray arrayWithArray:delegateList];
                    for (NSInteger subIndex=0; subIndex<delegateList.count; subIndex++) {
                        NSString *sub = delegateList[subIndex];
                        if (sub.length == 0) {
                            continue;
                        }
                        NSString *delegateString = [sub copy];
                        NSRange range = [sub rangeOfString:@"<"];
                        if (range.location != NSNotFound) {
                            delegateString = [delegateString substringFromIndex:range.location+range.length];
                        }
                        range = [delegateString rangeOfString:@">"];
                        if (range.location != NSNotFound) {
                            delegateString = [delegateString substringToIndex:range.location];
                        }
                        if ([[delegateString stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:oldProtocol]) {
                            NSString *newStr = [sub stringByReplacingOccurrencesOfString:oldProtocol withString:newProtocol];
                            [delegateTmpList replaceObjectAtIndex:subIndex withObject:newStr];
                        }
                    }
                    tmpString = [delegateTmpList componentsJoinedByString:@","];
                }
                if (tmpString && ![tmpString isEqualToString:lineString]) {
                    [tmpList replaceObjectAtIndex:index withObject:tmpString];
                }
            }
            
            string = [tmpList componentsJoinedByString:@"\n"];
            if (![string isEqualToString:file.data]) {
                file.data = string;
                [MixFileStrategy writeFileAtPath:file.path content:file.data];
            }
        }
    }
}

- (BOOL)checkIsWhiteFolder:(MixFile *)file {
    
    for (NSString *folder in self.whiteFolderList) {
        if (file.subFiles>0 && [folder isEqualToString:file.fileName]) {
            return YES;
        }
    }

    if (file.fileType != MixFileTypeFolder) {
        return YES;
    }
    return NO;
}

@end
