#import "TransloaditRequest.h"

@interface TransloaditRequest ()
@property (readwrite) NSMutableDictionary *post;
@property NSString *key;
@property NSString *secret;
@end

static const NSString *host = @"http://api2.transloadit.com";

@implementation TransloaditRequest

#pragma mark - Init

/**
 * Initializes the TransloaditRequest object w/ API credentials.
 *
 * @param {NSString} API Key (see: https://transloadit.com/accounts/credentials )
 * @param {NSString} API Secret (see: https://transloadit.com/accounts/credentials )
 *
 * @returns {id}
 */
- (id)initWithCredentials:(NSString *)key secret:(NSString *)secret
{    
    self = [super initWithBaseURL:[NSURL URLWithString:[host copy]]];
    if (self) {
        // Init
        _post = [[NSMutableDictionary alloc] init];
        
        // Setup
        self.key = key;
        self.secret = secret;
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Content-Type" value:@"application/json"];
    }
    return self;
}

#pragma mark - Public methods

/**
 * Uploads a local file using the provided parameters.
 *
 * @param {NSURL} Local file path
 * @param {NSString} File name (eg: @"myFile.jpg")
 * @param {NSString} MIME type (eg: @"image/jpg")
 * @param {NSString} Template id
 *
 * @returns {block}
 */
- (void)processFile:(NSURL *)path withFileName:(NSString *)filename contentType:(NSString *)mime template:(NSString *)template success:(void (^)(id, id))success failure:(void (^)(id, id, NSError *))failure
{
    NSData *data = [NSData dataWithContentsOfURL:path];
    [self processData:data withFileName:filename contentType:mime template:template success:^(id request, id JSON) {
        success(self, JSON);
    } failure:^(id request, id JSON, NSError *error) {
        failure(self, JSON, error);
    }];
}

/**
 * Uploads an NSData object using the provided parameters.
 *
 * @param {NSData} Data object
 * @param {NSString} File name (eg: @"myFile.wav")
 * @param {NSString} MIME type (eg: @"audio/wav")
 * @param {NSString} Template id
 *
 * @returns {block}
 */
- (void)processData:(NSData *)data withFileName:(NSString *)filename contentType:(NSString *)mime template:(NSString *)template success:(void (^)(id, id))success failure:(void (^)(id, id, NSError *))failure
{
    // Set post body
    NSDictionary *params    = @{
        @"template_id": template,
        @"auth": @{
            @"key":     self.key,
            @"expires": [self generateExpires]
        }
    };
    [self.post setObject:[self generateJsonString:params] forKey:@"params"];
    [self.post setObject:[self generateSignature:[self.post objectForKey:@"params"] secret:self.secret] forKey:@"signature"];
    
    // Create request
    NSURLRequest *request = [self multipartFormRequestWithMethod:@"POST" path:@"/assemblies" parameters:self.post constructingBodyWithBlock: ^(id <AFMultipartFormData> form) {
        [form appendPartWithFileData:data name:@"upload" fileName:filename mimeType:mime];
    }];
    
    // Force allow "text/plain" as an acceptable content type
    [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"text/plain"]];
    
    // Request operation
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        success(self, JSON);
    } failure:^(NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON) {
        failure(self, JSON, error);
    }];
    
    // Progress block
    [operation setUploadProgressBlock:^(NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        [self.delegate setProgress:totalBytesWritten/totalBytesExpectedToWrite];
    }];
    
    [operation start];
}

#pragma mark - Private methods

- (NSString *)generateExpires
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
	[format setDateFormat:@"yyyy-MM-dd HH:mm-ss 'GMT'"];
    
	NSDate *localExpires            = [[NSDate alloc] initWithTimeIntervalSinceNow:60*60];
	NSTimeInterval timeZoneOffset   = [[NSTimeZone defaultTimeZone] secondsFromGMT];
	NSTimeInterval gmtTimeInterval  = [localExpires timeIntervalSinceReferenceDate] - timeZoneOffset;
	NSDate *gmtExpires              = [NSDate dateWithTimeIntervalSinceReferenceDate:gmtTimeInterval];
    
    return [format stringFromDate:gmtExpires];
}

- (NSString *)generateSignature:(NSString *)params secret:(NSString *)secret
{
    return [self stringWithHexBytes:[self hmacSha1withKey:secret forString:params]];
}

- (NSString *)generateJsonString:(id)dict
{
    NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:0 error:nil] encoding:NSUTF8StringEncoding];
    return json;
}

#pragma mark - Utility methods

// from: http://stackoverflow.com/questions/476455/is-there-a-library-for-iphone-to-work-with-hmac-sha-1-encoding
- (NSData *)hmacSha1withKey:(NSString *)key forString:(NSString *)string
{
	NSData *clearTextData = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
	
	uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
	
	CCHmacContext hmacContext;
	CCHmacInit(&hmacContext, kCCHmacAlgSHA1, keyData.bytes, keyData.length);
	CCHmacUpdate(&hmacContext, clearTextData.bytes, clearTextData.length);
	CCHmacFinal(&hmacContext, digest);
	
	return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

// from: http://notes.stripsapp.com/nsdata-to-nsstring-as-hex-bytes/
- (NSString *)stringWithHexBytes:(NSData *)data
{
	static const char hexdigits[] = "0123456789abcdef";
	const size_t numBytes = [data length];
	const unsigned char* bytes = [data bytes];
	char *strbuf = (char *)malloc(numBytes * 2 + 1);
	char *hex = strbuf;
	NSString *hexBytes = nil;
	
	for (int i = 0; i<numBytes; ++i) {
		const unsigned char c = *bytes++;
		*hex++ = hexdigits[(c >> 4) & 0xF];
		*hex++ = hexdigits[(c ) & 0xF];
	}
	*hex = 0;
	hexBytes = [NSString stringWithUTF8String:strbuf];
	free(strbuf);
	return hexBytes;
}

#pragma mark - Dealloc

- (void)dealloc
{
    _delegate = nil;
    
    _post = nil;
    _key = nil;
    _secret = nil;
}

@end