//
//  ViewController.m
//  MyBonjour
//
//  Created by Hakim Hauston on 21/8/15.
//  Copyright (c) 2015 Hakim Hauston. All rights reserved.
//

#import "ViewController.h"

static ViewController *vc;

@interface ViewController ()

@end

@implementation ViewController

NSArray *recipes;

+ (ViewController*) currentViewController {
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    vc = self;
    
    // Do any additional setup after loading the view, typically from a nib.
    recipes = [NSArray arrayWithObjects:@"Egg Benedict", @"Mushroom Risotto", @"Full Breakfast", @"Hamburger", @"Ham and Egg Sandwich", @"Creme Brelee", @"White Chocolate Donut", @"Starbucks Coffee", @"Vegetable Curry", @"Instant Noodle with Egg", @"Noodle with BBQ Pork", @"Japanese Noodle with Pork", @"Green Tea", @"Thai Shrimp Cake", @"Angry Birds Cake", @"Ham and Cheese Panini", nil];
    
    Initialize();
    StartServer();
    StartClient();
}

- (void) reloadData
{
    if ( self.isViewLoaded ) {
        [self.tableView reloadData];
//        [self.tableView setContentOffset:CGPointZero animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    return [recipes count];
    BluetoothServerInfo *bsi = GetManager();
    return [bsi.arrayServices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
//    cell.textLabel.text = [recipes objectAtIndex:indexPath.row];
    BluetoothServerInfo *bsi = GetManager();
    NSNetService *service = [bsi.arrayServices objectAtIndex:indexPath.row];
    cell.textLabel.text = service.name;
//    [tableView setContentOffset:CGPointZero animated:YES];
    return cell;
}

@end
