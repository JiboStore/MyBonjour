//
//  BluetoothUtil.h
//  MyBonjour
//
//  Created by Hakim Hauston on 21/8/15.
//  Copyright (c) 2015 Hakim Hauston. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BluetoothDeviceInfo : NSObject

    @property (nonatomic, retain) NSInputStream*    inputStream;
    @property (nonatomic, retain) NSOutputStream*   outputStream;

@end

@interface BluetoothServerInfo : NSObject <NSNetServiceDelegate, NSStreamDelegate>

    @property (nonatomic, retain)   NSNetService*   theServer;

- (void) startServer;

@end

extern "C" {
    void StartAdvertising();
    void StartSearch();
}