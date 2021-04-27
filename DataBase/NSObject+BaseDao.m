//
//  NSObject+BaseDao.m
//  iDinner
//
//  Created by Sawyer on 16/11/25.
//  Copyright © 2016年 Sawyer. All rights reserved.
//

#import "NSObject+BaseDao.h"
#import "MJExtension.h"

@implementation NSObject (BaseDao)

#pragma mark - Database Delegate

/**
 @desc 创建表
 */
//TODO:创建表
+ (void)createTable {
    NSMutableArray *arrTypeAndName = [[[self class] allPropertyNames] mutableCopy];
    NSString * primaryKey;
    if ([[self class] respondsToSelector:@selector(sy_primaryKey)]) {
        primaryKey = [[self class] sy_primaryKey];
    }
    NSMutableArray * arrtan = [NSMutableArray array];
    for (int i = 0; i < arrTypeAndName.count; i++) {
        NSMutableDictionary * dic = [arrTypeAndName[i] mutableCopy];
        if ([dic[@"propertyName"] isEqualToString:primaryKey]) {
            dic[@"propertyName"]= [dic[@"propertyName"] stringByAppendingString:@" text primary key"];
        }else {
            dic[@"propertyName"] = [dic[@"propertyName"] stringByAppendingString:@" text not null default ''"];
        }
        [arrtan addObject:dic[@"propertyName"]];
    }
    //示例 @"create table if not exists ChatUserInfo(f_iams_1406061302_019 text primary key,f_iams_1406061302_011 text not null default '',f_iams_1406061302_P01 text not null default '',f_iams_1406061302_012 text not null default '',f_iams_1406061302_018 text not null default '',f_ease_1603221720_017 text not null default '',f_iams_1406061302_015 text not null default '',f_ease_1603221720_027 text not null default '');"
    NSString * sql = [NSString stringWithFormat:@"create table if not exists %@(%@);",NSStringFromClass([self class]),[arrtan componentsJoinedByString:@","]];
    BOOL res =  [CoreFMDB executeUpdate:sql];
    if(!res){
        NSLog(@"创表执行失败");
    }else {
        NSLog(@"sql:%@",sql);
        [self fieldsCheck:NSStringFromClass([self class]) ivars:arrTypeAndName];
    }
}



+(void)fieldsCheck:(NSString *)table ivars:(NSArray *)ivars{
    
    NSArray *columns=[CoreFMDB executeQueryColumnsInTable:table];
    
    NSMutableArray *columnsM=[NSMutableArray arrayWithArray:columns];
    if(columnsM.count>=ivars.count) return;
    
    for (NSDictionary *ivar in ivars) {
        
        if([columnsM containsObject:ivar[@"propertyName"]]) continue;
        
        NSMutableString *sql_addM=[NSMutableString stringWithFormat:@"ALTER TABLE '%@' ADD COLUMN %@ TEXT NOT NULL DEFAULT ''",table,ivar[@"propertyName"]];
        
        NSString *sql=[NSString stringWithFormat:@"%@;",sql_addM];
        
        BOOL addRes = [CoreFMDB executeUpdate:sql];
        
        if(!addRes){
            NSLog(@"模型%@字段新增失败！",table);
            return;
        }
    }
}

/**
 @desc 插入一条数据
 */
//TODO:插入一条数据
- (BOOL)insert{
    @try {
        id entity = self;
        [[self class] createTable];
        NSMutableDictionary * dic = [[self class] filterDontRelevanceToDB:entity];
        NSString *strKeys = [dic.allKeys componentsJoinedByString:@","];
        NSString *strValues = @"";
        for (NSString *str in dic.allKeys) {
            if ([dic[str] isKindOfClass:[NSString class]]||[dic[str] isKindOfClass:[NSDate class]]) {
                NSString *strT = @"";
                if([dic[str] isKindOfClass:[NSString class]]) {
                    strT = [dic[str] stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
                }else {
                    strT = dic[str];
                }
                strValues = [strValues stringByAppendingString:[NSString stringWithFormat:@"'%@',",strT]];
            }else if ([dic[str] isKindOfClass:[NSArray class]]){
                if ([[self class] respondsToSelector:@selector(sy_objectClassInArray)] && [[self class] sy_objectClassInArray][str]) {
                    strValues = [strValues stringByAppendingString:[NSString stringWithFormat:@"'%@',",[dic[str] mj_JSONString]]];
                }else{
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic[str]
                                                                       options:NSJSONWritingPrettyPrinted
                                                                         error:nil];
                    strValues = [strValues stringByAppendingString:[NSString stringWithFormat:@"'%@',",[[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding]]];
                }
            }else if ([dic[str] isKindOfClass:[NSDictionary class]]){
                strValues = [strValues stringByAppendingString:[NSString stringWithFormat:@"'%@',",[dic[str] mj_JSONString]]];
            }else {
                strValues = [strValues stringByAppendingString:[NSString stringWithFormat:@"%@,",dic[str]]];
            }
        }
        strValues = [strValues substringToIndex:strValues.length-1];
        NSString *sql = [NSString stringWithFormat:@"insert into %@ (%@) values(%@)",[NSString stringWithUTF8String:object_getClassName(entity)],strKeys,strValues];
        //添加数据
        return [CoreFMDB executeUpdate:sql];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    @finally {
        
    }
}

/**
 @desc 根据sql与模型类查询所有数据
 */
//TODO:根据sql与模型类查询所有数据
+ (void)queryAll:(void (^)(NSArray * arrObject))complete
         withSql:(NSString *)sql {
    @try {
        [[self class] createTable];
        [CoreFMDB executeQuery:sql queryResBlock:^(FMResultSet *set) {
            NSMutableArray *arr = [NSMutableArray array];
            NSArray *arrTypeAndName=[[self class] allPropertyNames];
            while ([set next]) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                id result;
                for (int j = 0; j<arrTypeAndName.count; j++) {
                    result = [[self class] objectFromTypeName:arrTypeAndName[j][@"propertyType"] columnName:arrTypeAndName[j][@"propertyName"] resultSet:set];
                    [dic setObject: [result isKindOfClass:[NSString class]]?STRING_NOT_EMPTY(result):result forKey:arrTypeAndName[j][@"propertyName"]];
                }
                [arr addObject:[[self class] mj_objectWithKeyValues:dic]];
            }
            complete([NSArray arrayWithArray:arr]);
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    @finally {
        
    }
}

/**
 @desc 根据主键值查询数据
 */
//TODO:根据主键值查询数据
+ (void)query:(void (^)(id object))complete
         withPrimaryKey:(NSString *)primary {
    @try {
        [[self class] createTable];
        //示例：select * from ChatUserInfo where f_iams_1406061302_019='%@';
        NSString * primaryKey;
        if ([[self class] respondsToSelector:@selector(sy_primaryKey)]) {
            primaryKey = [[self class] sy_primaryKey];
        } else {
            NSLog(@"%@ 未设置主键",[self class]);
            complete(nil);
            return;
        }
        NSString * sql = [NSString stringWithFormat:@"select * from %@ where %@='%@';",NSStringFromClass([self class]),primaryKey,primary];
        [self queryAll:^(NSArray * arrObject) {
            if (arrObject.count) {
                complete(arrObject[0]);
            }else{
                complete(nil);
            }
        } withSql:sql];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    @finally {
        
    }
}

/**
 @desc 根据sql条件与模型类更新数据
 */
//TODO:根据sql条件与模型类更新数据
- (BOOL)updateWithSqlWhere:(NSString *)sqlWhere{
    @try {
        id entity = self;
        NSMutableDictionary * dic = [[self class] filterDontRelevanceToDB:entity];
        NSString *strValues = @"";
        for (NSString *str in dic.allKeys) {
            if ([dic[str] isKindOfClass:[NSString class]]||[dic[str] isKindOfClass:[NSDate class]]) {
                NSString *strT = @"";
                if([dic[str] isKindOfClass:[NSString class]]) {
                    strT = [dic[str] stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
                }else {
                    strT = dic[str];
                }
                strValues = [strValues stringByAppendingString:[NSString stringWithFormat:@"%@ = '%@',",str,strT]];
            }else if ([dic[str] isKindOfClass:[NSArray class]]){
                if ([[self class] respondsToSelector:@selector(sy_objectClassInArray)] && [[self class] sy_objectClassInArray][str]) {
                    strValues = [strValues stringByAppendingString:[NSString stringWithFormat:@"%@ = '%@',",str,[dic[str] mj_JSONString]]];
                }else{
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic[str]
                                                                       options:NSJSONWritingPrettyPrinted
                                                                         error:nil];
                    strValues = [strValues stringByAppendingString:[NSString stringWithFormat:@"%@ = '%@',",str,[[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding]]];
                }
            }else if ([dic[str] isKindOfClass:[NSDictionary class]]){
                strValues = [strValues stringByAppendingString:[NSString stringWithFormat:@"%@ = '%@',",str,[dic[str] mj_JSONString]]];
            }else {
                strValues = [strValues stringByAppendingString:[NSString stringWithFormat:@"%@ = %@,",str,dic[str]]];
            }
        }
        strValues = [strValues substringToIndex:strValues.length-1];
        NSString *sql = [NSString stringWithFormat:@"update %@ set %@ where %@",[NSString stringWithUTF8String:object_getClassName(entity)],strValues,sqlWhere];
        
        return [CoreFMDB executeUpdate:sql];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
        return false;
    }
    @finally {
        return false;
    }
}

/**
 @desc 根据主键更新数据
 */
//TODO:根据主键更新数据
- (BOOL)updateWithPrimaryKey:(NSString *)primary{
    @try {
        //示例：f_iams_1406061302_019 = %@;
        NSString * primaryKey;
        if ([[self class] respondsToSelector:@selector(sy_primaryKey)]) {
            primaryKey = [[self class] sy_primaryKey];
        } else {
            NSLog(@"%@ 未设置主键",[self class]);
            return NO;
        }
        NSString * sqlWhere = [NSString stringWithFormat:@"%@ = '%@';",primaryKey,primary];
        return [self updateWithSqlWhere:sqlWhere];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
        return false;
    }
    @finally {
        return false;
    }
}

/**
 @desc 根据主键智能判断要插入还是更新
 */
//TODO:根据主键智能判断要插入还是更新
- (void)insertOrUpdate {
    NSString * primaryKey;
    if ([[self class] respondsToSelector:@selector(sy_primaryKey)]) {
        primaryKey = [[self class] sy_primaryKey];
    } else {
        NSLog(@"%@ 未设置主键",[self class]);
        return;
    }
    NSString * primary = [self valueForKeyPath:primaryKey];
    __block id tempObj = nil;
    [[self class] query:^(id arr) {
        if (arr) {
            tempObj = arr;
        }
    } withPrimaryKey:primary];
    if (!tempObj) {
        [self insert];
    } else {
        [self updateWithPrimaryKey:primary];
    }
}

/**
 @desc 根据sql条件删除数据
 */
//TODO:根据sql条件删除数据
+ (void)delectBySqlWhere:(NSString *)sqlWhere{
    NSString *sql;
    if(sqlWhere.length == 0){
        sql = [NSString stringWithFormat:@"delete from %@;",[NSString stringWithUTF8String:object_getClassName(self)]];
    } else{
        sql = [NSString stringWithFormat:@"delete from %@ where %@;",[NSString stringWithUTF8String:object_getClassName(self)],sqlWhere];
    }
    [CoreFMDB executeUpdate:sql];
}

/**
 @desc 根据主键删除数据
 */
//TODO:根据主键删除数据
+ (void)delectById:(NSString *)Id{
    NSString * primaryKey;
    if ([[self class] respondsToSelector:@selector(sy_primaryKey)]) {
        primaryKey = [[self class] sy_primaryKey];
    } else {
        NSLog(@"%@ 未设置主键",[self class]);
        return;
    }
    [self delectBySqlWhere:[NSString stringWithFormat:@"%@ = '%@'",primaryKey,Id]];
}

#pragma mark - Tools

///根据类型穷举判断从FMResultSet拿数据的方式
+ (id )objectFromTypeName:(NSString *)type columnName:(NSString *)columnName resultSet:(FMResultSet*)resultSet{
    if ([type isEqualToString:@"NSString"]) {
        return [resultSet stringForColumn:columnName];
    }else if ([type isEqualToString:@"NSDate"]) {
        return [resultSet dateForColumn:columnName];
    }else if ([type isEqualToString:@"NSInteger"]) {
        return [NSNumber numberWithInt:[resultSet intForColumn:columnName]];
    }else if ([type isEqualToString:@"NSNumber"]) {
        return [NSNumber numberWithDouble:[resultSet doubleForColumn:columnName]];
    }else if ([type isEqualToString:@"NSArray"]) {
        NSArray *arr;
        if ([[self class] respondsToSelector:@selector(sy_objectClassInArray)] && [[self class] sy_objectClassInArray][columnName]) {
            arr = [[[self class] sy_objectClassInArray][columnName] mj_objectArrayWithKeyValuesArray:JSONDATA_TO_OBJECT(STRING_TO_DATA([resultSet stringForColumn:columnName]))];
        }else{
            arr = [NSJSONSerialization JSONObjectWithData:[[resultSet stringForColumn:columnName] dataUsingEncoding:NSUTF8StringEncoding]
                                                           options:NSJSONReadingAllowFragments
                                                             error:nil];
        }
        return arr?arr:[NSArray array];
    }else if ([type isEqualToString:@"CGFloat"]) {
        NSLog(@"%@是未处理类型",type);
        return nil;
    }else {
        return [objc_getClass(type.UTF8String) mj_objectWithKeyValues:JSONDATA_TO_OBJECT(STRING_TO_DATA([resultSet stringForColumn:columnName]))];
    }
}

///通过运行时获取当前对象的所有属性类型和名称，以数组的形式返回
+ (NSArray *) allPropertyNames {
    Class modelClass = [self class];
    ///存储所有的属性名称
    NSMutableArray *allNames = [[NSMutableArray alloc] init];
    
    ///存储属性的个数
    unsigned int propertyCount = 0;
    
    ///通过运行时获取当前类的属性
    objc_property_t *propertys = class_copyPropertyList(modelClass, &propertyCount);
    
    
    NSArray * arrDontRelevanceToDB;
    if ([modelClass respondsToSelector:@selector(sy_dontRelevanceToDB)]) {
        arrDontRelevanceToDB = [modelClass sy_dontRelevanceToDB];
    }
    
    //把属性放到数组中
    for (int i = 0; i < propertyCount; i ++) {
        ///取出第一个属性
        objc_property_t property = propertys[i];
        const char * propertyName = property_getName(property);
        BOOL isDrkey = NO;
        for (NSString * drkey in arrDontRelevanceToDB) {
            if ([drkey isEqualToString:[NSString stringWithUTF8String:propertyName]]) {
                isDrkey = YES;
            }
        }
        if (isDrkey) continue;
        NSString * strAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
        [allNames addObject:@{@"propertyType":[strAttributes componentsSeparatedByString:@"\""][1],@"propertyName":[NSString stringWithUTF8String:propertyName]}];
    }
    
    ///释放
    free(propertys);
    
    return allNames;
}

+ (NSMutableDictionary *)filterDontRelevanceToDB:(id) entity{
    NSArray * arrKeyValue = [self allPropertyNames];
    NSDictionary *fatherDic = [entity mj_keyValues];
    NSMutableDictionary * dic = [NSMutableDictionary dictionary];
    NSArray * arrDontRelevanceToDB;
    if ([[entity class] respondsToSelector:@selector(sy_dontRelevanceToDB)]) {
        arrDontRelevanceToDB = [[entity class] sy_dontRelevanceToDB];
    }
    for (NSDictionary * KeyValue in arrKeyValue) {
        NSString * key = KeyValue[@"propertyName"];
        BOOL flag = NO;
        for (NSString * drkey in arrDontRelevanceToDB) {
            if ([drkey isEqualToString:key]) {
                flag = YES;
                break;
            }
        }
        if (!flag) {
            [dic setObject:fatherDic[key]?fatherDic[key]:@"" forKey:key];
        }
    }
    return dic;
}

@end
