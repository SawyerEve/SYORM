//
//  NSObject+BaseDao.h
//  iDinner
//
//  Created by Sawyer on 16/11/25.
//  Copyright © 2016年 Sawyer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreFMDB.h"

@protocol SYDataBase <NSObject>

@required

/**
 *  主键
 */
+ (NSString *)sy_primaryKey;

/**
 *  泛型数组指示字典
 */
+ (NSDictionary *)sy_objectClassInArray;

@optional
/**
 *  只有这个数组中的属性名才允许进行字典和模型的转换
 */
+ (NSArray *)sy_dontRelevanceToDB;
@end

@interface NSObject (BaseDao)<SYDataBase>

#pragma mark - Tools

/**
 @desc 创建表
 */
//TODO:创建表
+ (void)createTable;
/**
 @desc 插入一条数据
 */
//TODO:插入一条数据
- (BOOL)insert;
/**
 @desc 根据sql与模型类查询所有数据
 */
//TODO:根据sql与模型类查询所有数据
+ (void)queryAll:(void (^)(NSArray * arrObject))complete
         withSql:(NSString *)sql;
/**
 @desc 根据主键值查询数据
 */
//TODO:根据主键值查询数据
+ (void)query:(void (^)(id object))complete
withPrimaryKey:(NSString *)primary;
/**
 @desc 根据sql条件与模型类更新数据
 */
//TODO:根据sql条件与模型类更新数据
- (BOOL)updateWithSqlWhere:(NSString *)sqlWhere;
/**
 @desc 根据主键更新数据
 */
//TODO:根据主键更新数据
- (BOOL)updateWithPrimaryKey:(NSString *)primary;

/**
 @desc 根据主键智能判断要插入还是更新
 */
//TODO:根据主键智能判断要插入还是更新
- (void)insertOrUpdate;

/**
 @desc 根据sql条件删除数据
 */
//TODO:根据sql条件删除数据
+ (void)delectBySqlWhere:(NSString *)sqlWhere;
/**
 @desc 根据主键删除数据
 */
//TODO:根据主键删除数据
+ (void)delectById:(NSString *)Id;
@end
