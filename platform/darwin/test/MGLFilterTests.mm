#import "MGLStyleLayerTests.h"

#import "NSPredicate+MGLAdditions.h"
#import "MGLValueEvaluator.h"

@interface MGLFilterTests : MGLStyleLayerTests {
    MGLGeoJSONSource *source;
    MGLLineStyleLayer *layer;
}
@end

@implementation MGLFilterTests

- (void)setUp
{
    [super setUp];
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"amsterdam" ofType:@"geojson"];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSData *geoJSONData = [NSData dataWithContentsOfURL:url];
    source = [[MGLGeoJSONSource alloc] initWithSourceIdentifier:@"test-source" geoJSONData:geoJSONData];
    [self.mapView.style addSource:source];
    layer = [[MGLLineStyleLayer alloc] initWithLayerIdentifier:@"test-layer" sourceIdentifier:@"test-source"];
}

- (void)tearDown
{
    [self.mapView.style removeLayer:layer];
    [self.mapView.style removeSource:source];
}

- (NSArray<NSPredicate *> *)predicates
{
    NSPredicate *equalPredicate = [NSPredicate predicateWithFormat:@"type == 'neighbourhood'"];
    NSPredicate *notEqualPredicate = [NSPredicate predicateWithFormat:@"type != 'park'"];
    NSPredicate *greaterThanPredicate = [NSPredicate predicateWithFormat:@"%K > %@", @"stroke-width", @2.1];
    NSPredicate *greaterThanOrEqualToPredicate = [NSPredicate predicateWithFormat:@"%K >= %@", @"stroke-width", @2.1];
    NSPredicate *lessThanOrEqualToPredicate = [NSPredicate predicateWithFormat:@"%K <= %@", @"stroke-width", @2.1];
    NSPredicate *lessThanPredicate = [NSPredicate predicateWithFormat:@"%K < %@", @"stroke-width", @2.1];
    NSPredicate *inPredicate = [NSPredicate predicateWithFormat:@"type IN %@", @[@"park", @"neighbourhood"]];
    NSPredicate *notInPredicate = [NSPredicate predicateWithFormat:@"NOT (type IN %@)", @[@"park", @"neighbourhood"]];
    NSPredicate *inNotInPredicate = [NSPredicate predicateWithFormat:@"type IN %@ AND NOT (type IN %@)", @[@"park"], @[@"neighbourhood", @"test"]];
    NSPredicate *typePredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"$type", @"Feature"];
    NSPredicate *idPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"$id", @"1234123"];
    NSPredicate *specialCharsPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"ty-’pè", @"sŒm-ethįng"];
    NSPredicate *booleanPredicate = [NSPredicate predicateWithFormat:@"%K != %@", @"cluster", [NSNumber numberWithBool:YES]];
    return @[equalPredicate,
             notEqualPredicate,
             greaterThanPredicate,
             greaterThanOrEqualToPredicate,
             lessThanOrEqualToPredicate,
             lessThanPredicate,
             inPredicate,
             notInPredicate,
             inNotInPredicate,
             typePredicate,
             idPredicate,
             specialCharsPredicate,
             booleanPredicate];
}

- (void)testAllPredicates
{
    for (NSPredicate *predicate in self.predicates) {
        layer.predicate = predicate;
        XCTAssertEqualObjects(layer.predicate, predicate);
    }
    [self.mapView.style addLayer:layer];
}

- (void)testIntermittentEncoding
{
    NSPredicate *specialCharsPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"ty-’pè", @"sŒm-ethįng"];
    layer.predicate = specialCharsPredicate;
    
    NSComparisonPredicate *getPredicate = (NSComparisonPredicate *)layer.predicate;
    mbgl::style::EqualsFilter filter = layer.predicate.mgl_filter.get<mbgl::style::EqualsFilter>();
    
    id objcKey = getPredicate.leftExpression.keyPath;
    id cppKey = @(filter.key.c_str());
    id objcValue = mbgl::Value::visit(getPredicate.rightExpression.mgl_filterValue, ValueEvaluator());
    id cppValue = mbgl::Value::visit(filter.value, ValueEvaluator());
    
    XCTAssertEqualObjects(objcKey, cppKey);
    XCTAssertEqualObjects(objcValue, cppValue);
    
    [self.mapView.style addLayer:layer];
}

- (void)testNestedFilters
{
    NSPredicate *equalPredicate = [NSPredicate predicateWithFormat:@"type == 'neighbourhood'"];
    NSPredicate *notEqualPredicate = [NSPredicate predicateWithFormat:@"type != 'park'"];
    
    NSPredicate *allPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[equalPredicate, notEqualPredicate]];
    NSPredicate *anyPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[equalPredicate, notEqualPredicate]];
    
    layer.predicate = allPredicate;
    XCTAssertEqualObjects(layer.predicate, allPredicate);
    layer.predicate = anyPredicate;
    XCTAssertEqualObjects(layer.predicate, anyPredicate);
    
    [self.mapView.style addLayer:layer];
}

- (void)testAndPredicates
{
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:self.predicates];
    layer.predicate = predicate;
    XCTAssertEqualObjects(predicate, layer.predicate);
    [self.mapView.style addLayer:layer];
}

- (void)testOrPredicates
{
    NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:self.predicates];
    layer.predicate = predicate;
    XCTAssertEqualObjects(predicate, layer.predicate);
    [self.mapView.style addLayer:layer];
}

- (void)testNotAndPredicates
{
    NSPredicate *predicates = [NSCompoundPredicate andPredicateWithSubpredicates:self.predicates];
    NSCompoundPredicate *predicate = [NSCompoundPredicate notPredicateWithSubpredicate:predicates];
    layer.predicate = predicate;
    XCTAssertEqualObjects(predicate, layer.predicate);
    [self.mapView.style addLayer:layer];
}

- (void)testNotOrPredicates
{
    NSPredicate *predicates = [NSCompoundPredicate orPredicateWithSubpredicates:self.predicates];
    NSCompoundPredicate *predicate = [NSCompoundPredicate notPredicateWithSubpredicate:predicates];
    layer.predicate = predicate;
    XCTAssertEqualObjects(predicate, layer.predicate);
    [self.mapView.style addLayer:layer];
}

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

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedLong:ULONG_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), ULONG_MAX);
}

- (void)testExpressionConversionUnsignedLongLong
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedLongLong:0]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), 0);

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedLongLong:ULLONG_MAX]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<int64_t>() == true);
    XCTAssertEqual(convertedValue.get<int64_t>(), ULLONG_MAX);
}

- (void)testExpressionConversionUnsignedInteger
{
    NSComparisonPredicate *predicate;
    mbgl::Value convertedValue;

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedInteger:0]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<uint64_t>() == true);
    XCTAssertEqual(convertedValue.get<uint64_t>(), 0);

    predicate = [self equalityComparisonPredicateWithRightConstantValue:[NSNumber numberWithUnsignedInteger:NSUIntegerMax]];
    convertedValue = predicate.rightExpression.mgl_filterValue;
    XCTAssert(convertedValue.is<uint64_t>() == true);
    XCTAssertEqual(convertedValue.get<uint64_t>(), NSUIntegerMax);
}

@end
