//
//  ViewController.h
//  MyBonjour
//
//  Created by Hakim Hauston on 21/8/15.
//  Copyright (c) 2015 Hakim Hauston. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Bluetooth/BluetoothUtil.h"

@interface ViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property(nonatomic) IBOutlet UITableView *tableView;

+ (ViewController*) currentViewController;

- (void) reloadData;

@end

