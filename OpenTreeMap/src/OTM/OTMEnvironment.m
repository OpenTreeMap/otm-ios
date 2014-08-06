// This file is part of the OpenTreeMap code.
//
// OpenTreeMap is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// OpenTreeMap is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with OpenTreeMap.  If not, see <http://www.gnu.org/licenses/>.

#import "OTMEnvironment.h"
#import "AZHttpRequest.h"
#import "OTMDetailCellRenderer.h"
#import "OTMFilterListViewController.h"
#import "OTMDetailCellRenderer.h"
#import "OTMMapDetailCellRenderer.h"
#import "OTMChoicesDetailCellRenderer.h"

@implementation OTMEnvironment

+ (id)sharedEnvironment
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

/**
 Initialize the OTMEnvironment by reading values from the appropriate plist file.
 Expects that info.plist contains a 'Configuration' key.
 */
- (id)init
{
    self = [super init];
    if (!self) { return nil; }

    // Environment

    NSString* configuration = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Configuration"];
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* environmentPListPath = [bundle pathForResource:configuration ofType:@"plist"];
    NSDictionary* environment = [[NSDictionary alloc] initWithContentsOfFile:environmentPListPath];

    // Environment - URLCache

    NSDictionary *urlCache = [environment valueForKey:@"URLCache"];

    [self setUrlCacheName:[urlCache valueForKey:@"Name"]];
    [self setUrlCacheQueueMaxContentLength:[urlCache valueForKey:@"QueueMaxContentLength"]];
    [self setUrlCacheInvalidationAgeInSeconds:[urlCache valueForKey:@"InvalidationAgeInSeconds"]];

    // Implementation

    NSString* implementationPListPath = [bundle pathForResource:@"Implementation" ofType:@"plist"];
    NSDictionary* implementation = [[NSDictionary alloc] initWithContentsOfFile:implementationPListPath];

    self.accessKey = [implementation valueForKey:@"AccessKey"];
    self.secretKey = [implementation valueForKey:@"SecretKey"];

    self.instance = [implementation objectForKey:@"instance"];
    self.allowInstanceSwitch = YES;
    if (self.instance && ![self.instance isEqualToString:@""]) {
        self.allowInstanceSwitch = NO;
    }

    self.dateFormat = @"MMMM d, yyyy h:mm a";
    self.detailLatSpan = 0.0007;

    self.currencyUnit = [implementation objectForKey:@"OTMCurrencyDBHUnit"];
    if (self.currencyUnit == nil) {
        self.currencyUnit = @"$";
    }

    self.splashDelayInSeconds = [[implementation objectForKey:@"splashDelayInSeconds"] doubleValue];
    self.pendingActive = NO;

    self.primaryColor = [self colorFromArray:[implementation objectForKey:@"primaryColor"]
                                defaultColor:colorWithHexString(@"8BAA3D")];
    self.secondaryColor = [self colorFromArray:[implementation objectForKey:@"secondaryColor"]
                                  defaultColor:colorWithHexString(@"56ABB2")];
    self.instanceLogoUrl = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"]];

    self.viewBackgroundColor = [self colorFromArray:[implementation objectForKey:@"backgroundColor"] defaultColor:[UIColor whiteColor]];
    self.buttonTextColor = [self colorFromArray:[implementation objectForKey:@"buttonFontColor"] defaultColor:[UIColor whiteColor]];
    self.buttonImage = [UIImage imageNamed:@"btn_bg"];

    NSDictionary* url = [implementation valueForKey:@"APIURL"];

    [self setBaseURL:[NSString stringWithFormat:@"%@/%@/",
                      [url valueForKey:@"base"],
                      [url valueForKey:@"version"]]];

    [self setTilerUrl:[implementation valueForKey:@"tilerurl"]];

    // Implementation - MapView
    NSDictionary *mapView = [implementation valueForKey:@"MapView"];

    MKCoordinateSpan searchZoomCoordinateSpan = MKCoordinateSpanMake(0.0026, 0.0034);

    [self setMapViewSearchZoomCoordinateSpan:searchZoomCoordinateSpan];

    [self setUseOtmGeocoder:[[mapView valueForKey:@"UseOtmGeocoder"] boolValue]];

    [self setSearchRegionRadiusInMeters:[[mapView valueForKey:@"SearchRegionRadiusInMeters"] doubleValue]];

    [self setTileQueryStringAdditionalArguments:[mapView valueForKey:@"TileQueryStringAdditionalArguments"]];

    [self setNearbyTreeRadiusInMeters:[[implementation valueForKey:@"NearbyTreeRadiusInMeters"] doubleValue]];
    if (self.nearbyTreeRadiusInMeters == 0.0) {
        self.nearbyTreeRadiusInMeters = 300.0; // 300 meters is a guess at average city block size
    }

    [self setRecentEditsRadiusInMeters:[[implementation valueForKey:@"RecentEditsRadiusInMeters"] doubleValue]];
    if (self.recentEditsRadiusInMeters == 0.0) {
        self.recentEditsRadiusInMeters = 8000.0; // There are likely going to be edits within 5 miles of the user's location
    }

    [self setSearchSuffix:[mapView valueForKey:@"SearchSuffix"]];

    [self setLocationSearchTimeoutInSeconds:[mapView valueForKey:@"LocationSearchTimeoutInSeconds"]];

    [self setMapViewTitle:[mapView valueForKey:@"MapViewTitle"]];

    self.inappropriateReportEmail = [implementation objectForKey:@"inappropriateReportEmail"];
    if (self.inappropriateReportEmail == nil) {
        self.inappropriateReportEmail = @"OpenTreeMap <info@opentreemap.org>";
    }

    OTM2API* otmApi = [[OTM2API alloc] init];

    NSString* versionPlistPath = [bundle pathForResource:@"version" ofType:@"plist"];
    NSDictionary* version = [[NSDictionary alloc] initWithContentsOfFile:versionPlistPath];
    NSString *ver = [NSString stringWithFormat:@"ios-%@-b%@",
                         [version objectForKey:@"version"],
                         [version objectForKey:@"build"]];

    NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
                                          ver, @"ApplicationVersion",
                                          nil];

    NSURL *aurl = [NSURL URLWithString:[self baseURL]];
    AZHttpRequest* req = [[AZHttpRequest alloc] initWithURL:[self baseURL]];
    req.headers = headers;
    NSString *portString = [aurl port] ? [NSString stringWithFormat:@":%@", [aurl port]] : @"";
    self.host = [NSString stringWithFormat:@"%@://%@%@",
                          [aurl scheme],[aurl host], portString];

    AZHttpRequest* reqraw = [[AZHttpRequest alloc] initWithURL:self.baseURL];
    req.headers = headers;
    req.queue.maxConcurrentOperationCount = 3;

    otmApi.request = req;
    otmApi.noPrefixRequest = reqraw;

    self.api = otmApi;
    self.api2 = otmApi;

    return self;
}

-(void)setGeoRev:(NSString *)grev {
    if (![grev isEqualToString:_geoRev]) {
        _geoRev = grev;
        [[NSNotificationCenter defaultCenter] postNotificationName:kOTMGeoRevChangeNotification object:grev];
    }
}

-(void)setInstance:(NSString *)instance {
    _instance = instance;
    _api2.request.baseURL = [self.baseURL stringByAppendingFormat:@"instance/%@/",instance];
}

-(UIColor *)colorFromArray:(NSArray *)array defaultColor:(UIColor *)c {
    if (array == nil || [array count] != 4) {
        return c;
    } else {
        return [UIColor colorWithRed:[[array objectAtIndex:0] floatValue]
                               green:[[array objectAtIndex:1] floatValue]
                                blue:[[array objectAtIndex:2] floatValue]
                               alpha:[[array objectAtIndex:3] floatValue]];
    }
}

-(NSArray *)fieldKeys {
    return (NSArray* )self.fields;
}

- (void)updateEnvironmentWithDictionary:(NSDictionary *)dict {
    self.instance = [dict objectForKey:@"url"];
    self.instanceId = [dict objectForKey:@"id"];
    self.geoRev = [dict objectForKey:@"geoRevHash"];
    self.fields = [self fieldsFromDict:[dict objectForKey:@"fields"] orderedAndGroupedByDictArray:[dict objectForKey:@"field_key_groups"]];
    self.sectionTitles = [self sectionTitlesFromDictArray:[dict objectForKey:@"field_key_groups"]];
    self.config = [dict objectForKey:@"config"];
    self.mapViewTitle = [dict objectForKey:@"name"];
    self.photoFieldWritable = [[[[[dict objectForKey:@"fields"] objectForKey:@"treephoto.image"] objectForKey:@"can_write"] stringValue] isEqualToString:@"0"] ? NO : YES;

    NSDictionary *missingAndStandardFilters = [dict objectForKey:@"search"];

    NSArray *regFilters = [self filtersFromDictArray:missingAndStandardFilters[@"standard"]];
    NSArray *missingFilters = [self missingFiltersFromDictArray:missingAndStandardFilters[@"missing"]];

    self.filters = [regFilters arrayByAddingObjectsFromArray:missingFilters];

    self.ecoFields = [self ecoFieldsFromDict:[dict objectForKey:@"eco"]];
    NSDictionary* center = [dict objectForKey:@"center"];

    CGFloat lat = [[center objectForKey:@"lat"] floatValue];
    CGFloat lng = [[center objectForKey:@"lng"] floatValue];

    CLLocationCoordinate2D initialLatLon =
        CLLocationCoordinate2DMake(lat, lng);

    MKCoordinateSpan initialCoordinateSpan =
        MKCoordinateSpanMake(1.0, 1.0);

    [self setMapViewInitialCoordinateRegion:
              MKCoordinateRegionMake(initialLatLon,
                                     initialCoordinateSpan)];

    NSString *primaryHexColor = [[self.config objectForKey:@"scss_variables"] objectForKey:@"primary-color"];
    if (primaryHexColor) {
        self.primaryColor = colorWithHexString(primaryHexColor);
    }

    NSString *secondayHexColor = [[self.config objectForKey:@"scss_variables"] objectForKey:@"secondary-color"];
    if (secondayHexColor) {
        self.secondaryColor = colorWithHexString(secondayHexColor);
    }

    NSString* logoUrl = [dict objectForKey:@"logoUrl"];
    if (logoUrl) {
        self.instanceLogoUrl = [NSURL URLWithString:logoUrl];
    }

    NSString* inappropriateReportEmail =[dict objectForKey:@"inappropriateReportEmail"];
    if (inappropriateReportEmail) {
        self.inappropriateReportEmail = inappropriateReportEmail;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kOTMEnvironmentChangeNotification object:self];
}

/**
 * All missing filters are boolean filters with "existenceFilter"
 * set to true.
 */
- (NSArray *)missingFiltersFromDictArray:(NSArray *)filterlist {
    NSMutableArray *filterArray = [NSMutableArray array];

    [filterlist enumerateObjectsUsingBlock:^(NSDictionary *filter, NSUInteger idx, BOOL *stop) {
            NSString *fieldKey = filter[@"identifier"];
            NSString *fieldName = filter[@"label"];

            OTMFilter *afilter = [[OTMBoolFilter alloc] initWithName:fieldName
                                                                 key:fieldKey
                                                     existanceFilter:YES];
            [filterArray addObject:afilter];
        }];

    return filterArray;
}

- (NSArray *)filtersFromDictArray:(NSArray *)filterlist {
    NSMutableArray *filterArray = [NSMutableArray array];

    [filterlist enumerateObjectsUsingBlock:^(NSDictionary *filter, NSUInteger idx, BOOL *stop) {
            NSString *fieldKey = filter[@"identifier"];
            NSString *fieldName = filter[@"label"];
            NSString *filterType = filter[@"search_type"];

            OTMFilter *afilter = nil;

            if ([filterType isEqualToString:@"CHOICES"]) {
                NSArray *filterChoices = filter[@"choices"];

                afilter = [[OTMChoiceFilter alloc] initWithName:fieldName
                                                           key:fieldKey
                                                       choices:filterChoices];
            }
            else if ([filterType isEqualToString:@"BOOL"]) {
                afilter = [[OTMBoolFilter alloc] initWithName:fieldName
                                                         key:fieldKey];
            }
            else if ([filterType isEqualToString:@"RANGE"]) {
                afilter = [[OTMRangeFilter alloc] initWithName:fieldName
                                                          key:fieldKey];

            }
            else if ([filterType isEqualToString:@"SPACE"]) {
                CGFloat space = [[filter valueForKey:@"space"] floatValue];

                afilter = [[OTMFilterSpacer alloc] initWithSpace:space];
            }

            if (afilter != nil) {
                [filterArray addObject:afilter];
            }
        }];

    return filterArray;
}

- (void)addSpeciesFieldsToArray:(NSMutableArray *)modelFields
                            key:(NSString *)key
                     isWritable:(BOOL)writable
{
    OTMDetailCellRenderer *commonNameRenderer =
        [[OTMLabelDetailCellRenderer alloc]
            initWithDataKey:[NSString stringWithFormat:@"%@.common_name", key]
               editRenderer:nil
                      label:@"Species Common Name"
                  formatter:nil
                     isDate:NO];

    OTMDetailCellRenderer *sciNameRenderer =
        [[OTMLabelDetailCellRenderer alloc]
            initWithDataKey:[NSString stringWithFormat:@"%@.scientific_name", key]
               editRenderer:nil
                      label:@"Species Scientific Name"
                  formatter:nil
                     isDate:NO];

    [modelFields addObject:sciNameRenderer];
    [modelFields addObject:commonNameRenderer];

    if (writable) {
        self.speciesFieldWritable = YES;
    } else {
        self.speciesFieldWritable = NO;
    }
}

- (void)addFieldsToArray:(NSMutableArray *)modelFields fromDict:(NSDictionary *)dict {
    NSString *field = [dict objectForKey:@"field_name"];
    NSString *dType = [dict objectForKey:@"data_type"];
    NSString *displayField = [dict objectForKey:@"display_name"];
    NSString *key = [dict objectForKey:@"field_key"];
    BOOL writable = [[dict objectForKey:@"can_write"] boolValue];
    NSArray *choices = [dict objectForKey:@"choices"];
    BOOL isCollection = [[dict objectForKey:@"is_collection"] integerValue] == 1 ? YES : NO;

    if ((id)[NSNull null] == choices) {
        choices = nil;
    }

    NSString *unit = dict[@"units"];
    NSString *digitsV = dict[@"digits"];

    NSUInteger digits = digitsV != nil && digitsV != (id)[NSNull null]  ? [digitsV intValue] : 0;

    OTMFormatter *fmt = nil;
    if (unit != nil && ![unit isEqualToString:@""]) {
        fmt = [[OTMFormatter alloc] initWithDigits:digits
                                             label:unit];
    }

    if ([field isEqualToString:@"geom"] ||
        [field isEqualToString:@"readonly"]) {
        // skip
    } else if ([field isEqualToString:@"species"]) {
        [self addSpeciesFieldsToArray:modelFields key:key isWritable:writable];
    } else if ([field isEqualToString:@"diameter"]) {
        _dbhFormat = fmt;
        OTMDBHEditDetailCellRenderer *dbhEditRenderer = nil;
        if (writable) {
            dbhEditRenderer =
                [[OTMDBHEditDetailCellRenderer alloc] initWithDataKey:key
                                                            formatter:fmt];
        }

        [modelFields addObject:[[OTMLabelDetailCellRenderer alloc]
                                                   initWithDataKey:key
                                                      editRenderer:dbhEditRenderer
                                                             label:displayField
                                                         formatter:fmt
                                                            isDate:NO]];
    } else if ([choices count] > 0) {
        OTMChoicesDetailCellRenderer *renderer =
            [[OTMChoicesDetailCellRenderer alloc] initWithDataKey:key
                                                            label:displayField
                                                         clickUrl:nil
                                                          choices:choices
                                                         writable:writable];

        [modelFields addObject:renderer];
    } else if (isCollection) {

        /*
        OTMEditDetailCellRenderer *udfEditRenderer = [[OTMEditDetailCellRenderer alloc] init];
        OTMUdfAddMoreRenderer *addMore =
            [[OTMUdfAddMoreRenderer alloc]
                initWithDataStructure:(NSArray *)dType
                                field:field
                                  key:key
                          displayName:displayField];
         */
        NSDictionary *addMoreDict = @{
                                      @"key" : key,
                                      @"field" : field,
                                      @"displayField" : displayField,
                                      @"data" : dType
                                      };
        [_udfAddRenderers addObject:addMoreDict];

        OTMUdfCollectionEditCellRenderer *collectionEditRenderer =
            [[OTMUdfCollectionEditCellRenderer alloc] initWithDataKey:key
                                                            typeDict:dType
                                                           sortField:[self.sortKeys objectForKey:key]];

        OTMCollectionUDFCellRenderer *collectionRenderer =
            [[OTMCollectionUDFCellRenderer alloc] initWithDataKey:key
                                                         typeDict:dType
                                                        sortField:[self.sortKeys objectForKey:key]
                                                     editRenderer:collectionEditRenderer
                                                  addMoreRenderer:nil];
        [modelFields addObject:collectionRenderer];
    }
    else {
        OTMLabelEditDetailCellRenderer *editRenderer = nil;

        if (writable) {
            editRenderer = [[OTMLabelEditDetailCellRenderer alloc]
               initWithDataKey:key
                         label:displayField
                      keyboard:fmt ? UIKeyboardTypeDecimalPad : UIKeyboardTypeDefault
                     formatter:fmt
                        isDate:[dType isEqualToString:@"date"] ? YES : NO];
        }
        [modelFields addObject:[[OTMLabelDetailCellRenderer alloc]
                   initWithDataKey:key
                      editRenderer:editRenderer
                             label:displayField
                         formatter:fmt
                            isDate:[dType isEqualToString:@"date"] ? YES : NO]];
    }
}

- (NSArray *)sectionTitlesFromDictArray:(NSArray *)fieldKeyGroups {
    NSMutableArray *sectionTitles = [NSMutableArray array];

    [fieldKeyGroups enumerateObjectsUsingBlock:^(id keyGroupDict, NSUInteger idx, BOOL *stop) {
        NSString *header = [keyGroupDict objectForKey:@"header"];
        if (header != nil) {
            [sectionTitles addObject:header];
        } else {
            [sectionTitles addObject:@""];
        }
    }];

    // Eco is always shown at the bottom
    [sectionTitles addObject:@"Ecosystem Benefits"];

    return sectionTitles;
}

- (NSArray *)fieldsFromDict:(NSDictionary *)fields orderedAndGroupedByDictArray:(NSArray *)fieldKeyGroups {
    NSMutableArray *fieldArray = [NSMutableArray array];
    _udfAddRenderers = [[NSMutableArray alloc] init];
    for (id keyGroupDict in fieldKeyGroups) {

        // Both fieldKeys and udfGroupingKeys can't be set at once. So we can
        // Set up both and loop over both without causing any issues.
        NSArray *fieldKeys = [keyGroupDict objectForKey:@"field_keys"];
        NSArray *udfGroupingKeys = [keyGroupDict objectForKey:@"collection_udf_keys"];
        NSString *sortKey = [keyGroupDict objectForKey:@"sort_key"];


        NSMutableArray *modelFields = [NSMutableArray array];

        for (id fieldKey in fieldKeys) {
            [self addFieldsToArray:modelFields fromDict:[fields objectForKey:fieldKey]];
        }

        for (id udf in udfGroupingKeys) {
            NSMutableDictionary *tempSortKeys = self.sortKeys ? [self.sortKeys mutableCopy] : [[NSMutableDictionary alloc] init];
            [tempSortKeys setObject:sortKey forKey:udf];
            self.sortKeys = [tempSortKeys copy];
            [self addFieldsToArray:modelFields fromDict:[fields objectForKey:udf]];
        }

        [self buildFieldsFromArray:[self combineUdfAddRenderers] attachToArray:modelFields];
        [fieldArray addObject:modelFields];

    }

    return fieldArray;
}

- (void)buildFieldsFromArray:(NSArray *)adders attachToArray:(NSMutableArray *)existingArray
{
    for (NSArray *adder in adders) {
        OTMUdfAddMoreRenderer *addMore = [[OTMUdfAddMoreRenderer alloc]
                                          initWithDataStructure:adder
                                                          field:nil
                                                            key:nil
                                                    displayName:nil];

        OTMCollectionUDFCellRenderer *collectionRenderer =
        [[OTMCollectionUDFCellRenderer alloc] initWithDataKey:nil
                                                     typeDict:nil
                                                    sortField:nil
                                                 editRenderer:addMore
                                              addMoreRenderer:nil];
        [existingArray addObject:collectionRenderer];
    }
}

- (NSArray *)combineUdfAddRenderers
{
    NSMutableArray *combinedRenderers = [[NSMutableArray alloc] init];
    NSMutableSet *fieldSet = [[NSMutableSet alloc] init];
    for (NSDictionary *rendererData in _udfAddRenderers) {
        [fieldSet addObject:[rendererData objectForKey:@"field"]];
    }

    for (NSString *fieldString in fieldSet) {
        NSPredicate *matchPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *evaluatedObject, NSDictionary *bindings) {
            return [[evaluatedObject objectForKey:@"field"] isEqualToString:fieldString];
        }];
        NSPredicate *unmatchedPredicate = [NSCompoundPredicate notPredicateWithSubpredicate: matchPredicate];
        NSArray *filtered = [_udfAddRenderers filteredArrayUsingPredicate:matchPredicate];
        NSMutableArray *choices = [[NSMutableArray alloc] init];
        NSMutableDictionary *keyedChoices = [[NSMutableDictionary alloc] init];
        for (NSDictionary *filteredRendererData in filtered) {
            [choices addObject:[filteredRendererData objectForKey:@"key"]];
            [keyedChoices setObject:[filteredRendererData objectForKey:@"data"] forKey:[filteredRendererData objectForKey:@"key"]];
        }

        NSDictionary *udfFieldTypeData = @{
                                           @"type" : @"choice",
                                           @"choices" : choices,
                                           @"name" : @"Type"
                                           };

        NSDictionary *udfFieldTypeChoiceData = @{
                                                 @"type" : @"udf_keyed_grouping",
                                                 @"choices" : keyedChoices,
                                                 @"name" : @""
                                                 };


        [combinedRenderers addObject:[[NSArray alloc] initWithObjects:udfFieldTypeData, udfFieldTypeChoiceData, nil]];
        NSArray *remaining = [_udfAddRenderers filteredArrayUsingPredicate:unmatchedPredicate];
        _udfAddRenderers = [remaining mutableCopy];
    }
    return [combinedRenderers copy];
}

- (NSArray*)ecoFieldsFromDict:(NSDictionary*)ecoDict {
    if ([ecoDict objectForKey:@"supportsEcoBenefits"]) {
        NSMutableArray *fieldArray = [NSMutableArray array];
        NSArray *benefits = [ecoDict objectForKey:@"benefits"];
        [benefits enumerateObjectsUsingBlock:^(NSDictionary *benefitsDict, NSUInteger idx, BOOL *stop) {
            // Currently, we create the same type of cell renderer without regard to
            // any of the field details
            NSString *model = [benefitsDict objectForKey:@"model"];
            NSArray *keys = [benefitsDict objectForKey:@"keys"];
            [keys enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
                [fieldArray addObject:[[OTMBenefitsDetailCellRenderer alloc] initWithModel:model key:key]];
            }];
        }];
        // To be consistant with the editable fields, the eco fields are wrapped in a containing
        // array that represents the field group. This may be useful
        // in the future when there may be multiple sets of eco benefits.
        return [NSArray arrayWithObject:fieldArray];
    } else {
        return [[NSArray alloc] init];
    }
}

// Photo urls returned from the API may be relative to the application, or absolute S3 urls.
- (NSString *)absolutePhotoUrlFromPhotoUrl:(NSString *)photoUrl {
    if (![photoUrl hasPrefix:@"http"]) {
        NSURL *url = [NSURL URLWithString:self.baseURL];
        NSString *host = [url host];
        NSString *scheme = [url scheme];
        NSNumber *port = [url port];
        return [NSString stringWithFormat:@"%@://%@:%@%@", scheme, host, port, photoUrl];
    } else {
        return photoUrl;
    }
}

- (BOOL) speciesFieldIsWritable {
    return self.speciesFieldWritable;
}

- (BOOL) photoFieldIsWritable {
    return self.photoFieldWritable;
}

//
// Functions from DB5
// https://github.com/quartermaster/DB5/blob/7e41cef54e7ae9d3e97c2f8f23fc5cf14df72114/Source/VSTheme.m
//

static BOOL stringIsEmpty(NSString *s) {
        return s == nil || [s length] == 0;
}

static UIColor *colorWithHexString(NSString *hexString) {

        /*Picky. Crashes by design.*/

        if (stringIsEmpty(hexString))
                return [UIColor blackColor];

        NSMutableString *s = [hexString mutableCopy];
        [s replaceOccurrencesOfString:@"#" withString:@"" options:0 range:NSMakeRange(0, [hexString length])];
        CFStringTrimWhitespace((__bridge CFMutableStringRef)s);

        NSString *redString = [s substringToIndex:2];
        NSString *greenString = [s substringWithRange:NSMakeRange(2, 2)];
        NSString *blueString = [s substringWithRange:NSMakeRange(4, 2)];

        unsigned int red = 0, green = 0, blue = 0;
        [[NSScanner scannerWithString:redString] scanHexInt:&red];
        [[NSScanner scannerWithString:greenString] scanHexInt:&green];
        [[NSScanner scannerWithString:blueString] scanHexInt:&blue];

        return [UIColor colorWithRed:(CGFloat)red/255.0f green:(CGFloat)green/255.0f blue:(CGFloat)blue/255.0f alpha:1.0f];
}

@end
