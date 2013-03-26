//
//  Base64.h
//
//  Created by SARATH DR on 07/03/2013.
//
//

#import <Foundation/Foundation.h>

@interface Base64 : NSObject {
    
}

+ (void) initialize;

+ (NSString*) encode:(const uint8_t*) input length:(NSInteger) length;

+ (NSString*) encode:(NSData*) rawBytes;

+ (NSData*) decode:(const char*) string length:(NSInteger) inputLength;

+ (NSData*) decode:(NSString*) string;

@end