#import <XCTest/XCTest.h>

#import <string>

#import "NSExpression+MGLAdditions.h"

@interface MGLExpressionTests : XCTestCase

@end

@implementation MGLExpressionTests

- (NSComparisonPredicate *)equalityComparisonPredicateWithRightConstantValue:(id)rightConstantValue
{
    NSComparisonPredicate *predicate = [NSComparisonPredicate
        predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"foo"]
                    rightExpression:[NSExpression expressionForConstantValue:rightConstantValue]
                           modifier:NSDirectPredicateModifier
                               type:NSEqualToPredicateOperatorType
                            options:0];
    return predicate;
}

- (void)testExpressionConversionString
{
    NSComparisonPredicate *predicate = [self equalityComparisonPredicateWithRightConstantValue:@"bar"];
    mbgl::Value convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<std::string>() == true);
}

- (void)testExpressionConversionBooleanTrue
{
    NSComparisonPredicate *predicate = [self equalityComparisonPredicateWithRightConstantValue:@YES];
    mbgl::Value convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<bool>() == true);
    XCTAssert(convertedValue.get<bool>() == true);
}

- (void)testExpressionConversionBooleanFalse
{
    NSComparisonPredicate *predicate = [self equalityComparisonPredicateWithRightConstantValue:@NO];
    mbgl::Value convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<bool>() == true);
    XCTAssert(convertedValue.get<bool>() == false);
}

- (void)testExpressionConversionShort
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithShort:-SHRT_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), -SHRT_MAX);

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithShort:SHRT_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), SHRT_MAX);

}

- (void)testExpressionConversionInt
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithInt:-INT_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), -INT_MAX);

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithInt:INT_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), INT_MAX);
}

- (void)testExpressionConversionLong
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithLong:-LONG_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), -LONG_MAX);

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithLong:LONG_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), LONG_MAX);
}

- (void)testExpressionConversionLongLong
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithLongLong:-LLONG_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), -LLONG_MAX);
}

- (void)testExpressionConversionInteger
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithInteger:-NSIntegerMax]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), -NSIntegerMax);

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithInteger:NSIntegerMax]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), NSIntegerMax);
}

- (void)testExpressionConversionUnsignedChar
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedChar:0]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), 0);

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedChar:CHAR_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), CHAR_MAX);
}

- (void)testExpressionConversionUnsignedShort
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedShort:0]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), 0);

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedShort:SHRT_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), SHRT_MAX);
}

- (void)testExpressionConversionUnsignedInt
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedInt:0]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), 0);

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedInt:INT_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), INT_MAX);
}

- (void)testExpressionConversionUnsignedLong
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedLong:0]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), 0);

    // upper range is uint64_t
    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedLong:ULONG_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<uint64_t>() == true);
    XCTAssertEqual(convertedValue.get<uint64_t>(), ULONG_MAX);
}

- (void)testExpressionConversionUnsignedLongLong
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedLongLong:0]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), 0);

    // upper range is uint64_t
    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedLongLong:ULLONG_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<uint64_t>() == true);
    XCTAssertEqual(convertedValue.get<uint64_t>(), ULLONG_MAX);
}

- (void)testExpressionConversionUnsignedInteger
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedInteger:0]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), 0);

    // upper range is uint64_t
    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedInteger:NSUIntegerMax]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<uint64_t>() == true);
    XCTAssertEqual(convertedValue.get<uint64_t>(), NSUIntegerMax);
}

@end
