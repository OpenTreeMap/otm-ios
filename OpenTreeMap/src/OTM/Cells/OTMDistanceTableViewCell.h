//
//  OTMDistanceTableViewCell.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kOTMDistaneTableViewCellRedrawDistance @"kOTMDistanceTableViewCellRedrawDistance"

@interface OTMDistanceTableViewCell : UITableViewCell

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, strong) UILabel *distLabel;
@property (nonatomic, strong) CLLocation *thisLoc;
@property (nonatomic, strong) CLLocation *curLoc;

@end
