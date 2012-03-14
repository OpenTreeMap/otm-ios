//
//  OTMTreeDetailViewController.h
//  OpenTreeMap
//
//  Created by Adam Hinz on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTMTreeDetailViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>


/**
 * Dictionary[String,String] of tree detail key-value pairs
 */
@property (nonatomic, strong) NSDictionary* data;

/**
 * Array[Array[String]] keys to display in the main table
 *
 * Each element in the outher array represents a section
 * and each element in the inner array represents a row.
 * 
 * The first row is the title of the section (which can
 * be the empty string)
 */
@property (nonatomic, strong) NSArray* keys;

@end
