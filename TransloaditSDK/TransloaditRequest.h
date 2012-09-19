#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>

#import "AFNetworking.h"

@interface TransloaditRequest : AFHTTPClient

@property (readonly) NSMutableDictionary *post;

- (id)initWithCredentials:(NSString *)key secret:(NSString *)secret;
- (void)processFile:(NSURL *)path withFileName:(NSString *)filename contentType:(NSString *)mime template:(NSString *)template success:(void (^)(id request, id JSON))success failure:(void (^)(id request, NSError *error))failure;
- (void)processData:(NSData *)data withFileName:(NSString *)filename contentType:(NSString *)mime template:(NSString *)template success:(void (^)(id request, id JSON))success failure:(void (^)(id request, NSError *error))failure;

@end