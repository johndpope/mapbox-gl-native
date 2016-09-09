#import "NSExpression+MGLAdditions.h"

#import <mbgl/platform/log.hpp>

#import <CoreGraphics/CGBase.h>

@implementation NSExpression (MGLAdditions)

- (std::vector<mbgl::Value>)mgl_filterValues
{
    if ([self.constantValue isKindOfClass:NSArray.class]) {
        NSArray *values = self.constantValue;
        std::vector<mbgl::Value>convertedValues;
        for (id value in values) {
            convertedValues.push_back([self mgl_convertedValueWithValue:value]);
        }
        return convertedValues;
    }
    [NSException raise:@"Values not handled" format:@""];
    return { };
}

- (mbgl::Value)mgl_filterValue
{
    return [self mgl_convertedValueWithValue:self.constantValue];
}

- (mbgl::Value)mgl_convertedValueWithValue:(id)value
{
    if ([value isKindOfClass:NSString.class]) {
        return { std::string([(NSString *)value UTF8String]) };
    } else if ([value isKindOfClass:NSNumber.class]) {
        NSNumber *number = (NSNumber *)value;
        NSLog(@"NSNumber %@ (%s)", number, [number objCType]);

        // 32/64-bit check based on CGFloat storage size
        // per https://developer.apple.com/library/ios/documentation/General/Conceptual/CocoaTouch64BitGuide/
        BOOL thirtyTwoBit = sizeof(CGFloat) == sizeof(float);
        BOOL sixtyFourBit = sizeof(CGFloat) == sizeof(double);
        NSAssert((thirtyTwoBit || sixtyFourBit) && ! (thirtyTwoBit && sixtyFourBit), @"Fault in 32/64-bit determination");
        NSLog(@"Running in %@-bit mode", (thirtyTwoBit ? @"32" : @"64"));

        if ((strcmp([number objCType], @encode(char)) == 0) ||
            (strcmp([number objCType], @encode(BOOL)) == 0)) {
            // char: 32-bit boolean
            // BOOL: 64-bit boolean
            return { (bool)number.boolValue };
        } else if (strcmp([number objCType], @encode(short))     == 0 ||
                   strcmp([number objCType], @encode(int))       == 0 ||
                   strcmp([number objCType], @encode(long))      == 0 ||
                   strcmp([number objCType], @encode(long long)) == 0 ||
                   strcmp([number objCType], @encode(NSInteger)) == 0) {
            // Triggered for most non-boolean whole numbers as converted
            // by NSExpression regardless of signedness. NSNumber seems
            // to try to save space where possible.
            return { (int64_t)number.integerValue };
        } else if (strcmp([number objCType], @encode(unsigned char))      == 0 ||
                   strcmp([number objCType], @encode(unsigned short))     == 0 ||
                   strcmp([number objCType], @encode(unsigned int))       == 0 ||
                   strcmp([number objCType], @encode(unsigned long))      == 0 ||
                   strcmp([number objCType], @encode(unsigned long long)) == 0 ||
                   strcmp([number objCType], @encode(NSUInteger))         == 0) {
            // Triggered for very large numbers, e.g. NSUIntegerMax. Handling
            // all unsigned types here anyway for consistency. 
            return { (uint64_t)number.unsignedIntegerValue };
        } else if (strcmp([number objCType], @encode(double)) == 0) {
            // Double values on all platforms are interpreted precisely.
            return { (double)number.doubleValue };
        } else if (strcmp([number objCType], @encode(float)) == 0) {
            // Float values when taken as double introduce precision problems,
            // so warn the user to avoid them. This would require them to
            // explicitly use -[NSNumber numberWithFloat:] arguments anyway.
            // We still do this conversion in order to provide a valid value.
            mbgl::Log::Warning(mbgl::Event::Style, "float values are converted to double and can introduce imprecision; please use double values explicitly in predicate arguments");
            return { (double)number.doubleValue };
        }
    }
    [NSException raise:@"Value not handled"
                format:@"Can’t convert %s:%@ to mbgl::Value", [value objCType], value];
    return { };
}

@end
