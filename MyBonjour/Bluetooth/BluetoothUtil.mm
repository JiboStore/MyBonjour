//
//  BluetoothUtil.mm
//  MyBonjour
//
//  Created by Hakim Hauston on 21/8/15.
//  Copyright (c) 2015 Hakim Hauston. All rights reserved.
//

#import "BluetoothUtil.h"

static NSString * kWiTapBonjourType = @"_witap2._tcp.";

static uint iMessageExpander = 2048;    // 1024; max: 4096 will have recepient receive in 4 chunks of 928 + 1 chunk of 384
static uint iSendRepeater = 1;          // 2; max

static BluetoothServerInfo *meServer;

@implementation BluetoothDeviceInfo
{
    
}

@end

@implementation BluetoothServerInfo

    - (void) startServer
    {
        self.theServer = [[NSNetService alloc] initWithDomain:@"local." type:kWiTapBonjourType name:[UIDevice currentDevice].name port:0];
        self.theServer.includesPeerToPeer = YES;
        [self.theServer setDelegate:self];
        [self.theServer publishWithOptions:NSNetServiceListenForConnections];
    }


@end

extern "C"
{
    
    void StartAdvertising()
    {
        meServer = [[BluetoothServerInfo alloc] init];
        [meServer startServer];
    }
    
    void StartSearch()
    {
        
    }
    
}// end extern "C"