//
//  NuSwizzles.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "Nu.h"
#import "NuSwizzles.h"
#import "NuInternals.h"
#import "NuClass.h"
#import <objc/runtime.h>

#pragma mark - NuSwizzles.m

@interface NSCFDictionarySwizzles : NSObject {}
- (void)zetObject:(id)anObject forKey:(id)aKey;
@end

@implementation NSCFDictionarySwizzles

- (void)zetObject:(id)anObject forKey:(id)aKey {}

- (void)nuSetObject:(id)anObject forKey:(id)aKey
{
    [self zetObject:((anObject == nil) ? (id)Nu__null : anObject) forKey:aKey];
}

@end

@interface NSCFArraySwizzles : NSObject {}
@end

@implementation NSCFArraySwizzles

- (void)nuAddObject:(id)anObject
{
    [self nuAddObject:((anObject == nil) ? (id)Nu__null : anObject)];
}

- (void)nuInsertObject:(id)anObject atIndex:(int)index
{
    [self nuInsertObject:((anObject == nil) ? (id)Nu__null : anObject) atIndex:index];
}

- (void)nuReplaceObjectAtIndex:(int)index withObject:(id)anObject
{
    [self nuReplaceObjectAtIndex:index withObject:((anObject == nil) ? Nu__null : anObject)];
}

@end

@interface NSCFSetSwizzles : NSObject {}
@end

@implementation NSCFSetSwizzles

- (void)nuAddObject:(id)anObject
{
    [self nuAddObject:((anObject == nil) ? Nu__null : anObject)];
}

@end

void nu_swizzleContainerClasses()
{
    SEL zOFKSel = sel_registerName("zetObject:forKey:");
    SEL sOFKSel = sel_registerName("setObject:forKey:");
    Class nscfDict = objc_getClass("__NSCFDictionary");
    Method setOFKMet = class_getInstanceMethod(nscfDict, sOFKSel);
    const char *types = method_getTypeEncoding(setOFKMet);
    IMP sOFKImp = method_getImplementation(setOFKMet);
    class_addMethod(nscfDict, zOFKSel, sOFKImp, types);
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    Class NSCFDictionary = NSClassFromString(@"NSCFDictionary");
    Class NSCFArray = NSClassFromString(@"NSCFArray");
    Class NSCFSet = NSClassFromString(@"NSCFSet");
    [NSCFDictionary include:[NuClass classWithName:@"NSCFDictionarySwizzles"]];
    [NSCFArray include:[NuClass classWithName:@"NSCFArraySwizzles"]];
    [NSCFSet include:[NuClass classWithName:@"NSCFSetSwizzles"]];
    [NSCFDictionary exchangeInstanceMethod:@selector(setObject:forKey:) withMethod:@selector(nuSetObject:forKey:)];
    [NSCFArray exchangeInstanceMethod:@selector(addObject:) withMethod:@selector(nuAddObject:)];
    [NSCFArray exchangeInstanceMethod:@selector(insertObject:atIndex:) withMethod:@selector(nuInsertObject:atIndex:)];
    [NSCFArray exchangeInstanceMethod:@selector(replaceObjectAtIndex:withObject:) withMethod:@selector(nuReplaceObjectAtIndex:withObject:)];
    [NSCFSet exchangeInstanceMethod:@selector(addObject:) withMethod:@selector(nuAddObject:)];
    [pool drain];
}



