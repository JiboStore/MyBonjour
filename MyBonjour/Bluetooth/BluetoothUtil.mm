//
//  BluetoothUtil.mm
//  MyBonjour
//
//  Created by Hakim Hauston on 21/8/15.
//  Copyright (c) 2015 Hakim Hauston. All rights reserved.
//

#import "BluetoothUtil.h"

#import "ViewController.h"

static NSString * kWiTapBonjourType = @"_witap2._tcp.";
static NSString * kWiTapBonjourLocal = @"local";

static uint iMessageExpander = 2048;    // 1024; max: 4096 will have recepient receive in 4 chunks of 928 + 1 chunk of 384
static uint iSendRepeater = 1;          // 2; max

static BluetoothServerInfo *meServer;

@implementation BluetoothDeviceInfo

     - (id) initializeAsServer:(BOOL)bServer withService:(NSNetService*)server inputStream:(NSInputStream*)iStream outputStream:(NSOutputStream*)oStream
        {
            self = [super init];
            if ( self ) {
                self.isServer = bServer;
                self.theService = server;
                self.inputStream = iStream;
                self.outputStream = oStream;
            }
            return self;
        }

- (void) openStreams
{
    [self.inputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    
    [self.outputStream setDelegate:self];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
}

- (void) closeStreams
{
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream close];
    self.inputStream = nil;
    
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream close];
    self.outputStream = nil;
}

- (void) sendData:(const char*)pbyData withLength:(int)length
{
    uint uiMessageSize = sizeof(char) * length;
    long bytesWritten = -1;
    bytesWritten = [self.outputStream write:(const uint8_t*)pbyData maxLength:uiMessageSize];
    NSLog(@"sendData: %d sent: %ld", uiMessageSize, bytesWritten);
}

#pragma NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"stream handleEvent: %d", eventCode);
    switch ( eventCode ) {
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventHasSpaceAvailable:
            break;
        case NSStreamEventHasBytesAvailable:
        {
            int iReadSize = 1024;
            int iBytesRead = 0;
            char *pbyRead = (char*)malloc(sizeof(char) * iReadSize);
            iBytesRead = [self.inputStream read:(unsigned char*)pbyRead maxLength:iReadSize];
            NSLog(@"read data: %s length: %d", pbyRead, iBytesRead);
            if ( !self.isServer ) {
                // receive from client, then try to broadcast to other clients
                SendBroadcast(pbyRead, iBytesRead);
            }
            ReceiveBroadcast(pbyRead, iBytesRead);
            free(pbyRead);
        }
            break;
        case NSStreamEventErrorOccurred:
        {
            NSError *e = [aStream streamError];
            NSString *szError = [NSString stringWithFormat:@"ERROR: %i (%@)", [e code], [e localizedDescription]];
            NSLog(@"NSStreamEventErrorOccurred: %@", szError);
        }
            break;
        case NSStreamEventEndEncountered:
            // disconnected
            break;
    }
}

@end

@implementation BluetoothServerInfo

    - (id) init
    {
        self = [super init];
        if ( self ) {
            NSMutableDictionary *theServers = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *theClients = [[NSMutableDictionary alloc] init];
            NSMutableArray *theServices = [[NSMutableArray alloc] init];
            self.listServers = theServers;
            self.listClients = theClients;
            self.arrayServices = theServices;
            [theServers release];
            [theClients release];
            [theServices release];
            self.theServer = nil;
            self.theClient = nil;
        }
        return self;
    }

    /**
     *  return 1 if I am the server
     *  return 0 if I am the client
     */
    - (int) meServer
    {
        if ( self.theServer != nil ) {
            return 1;
        } else if ( self.theClient != nil ) {
            return 0;
        } else {
            return -1;
        }
    }

    - (void) startServer
    {
        self.theServer = [[NSNetService alloc] initWithDomain:@"local." type:kWiTapBonjourType name:[UIDevice currentDevice].name port:0];
        self.theServer.includesPeerToPeer = YES;
        [self.theServer setDelegate:self];
        [self.theServer publishWithOptions:NSNetServiceListenForConnections];
    }

    - (void) startClient
    {
        self.theClient = [[NSNetServiceBrowser alloc] init];
        self.theClient.includesPeerToPeer = YES;
        [self.theClient setDelegate:self];
        [self.theClient searchForServicesOfType:kWiTapBonjourType inDomain:kWiTapBonjourLocal];
    }

    - (void) onClientConnected:(NSNetService*)server inputStream:(NSInputStream*)iStream outputStream:(NSOutputStream*)oStream
    {
        BluetoothDeviceInfo *bdiClient = [[BluetoothDeviceInfo alloc] initializeAsServer:NO withService:server inputStream:iStream outputStream:oStream];
//        [self.listClients setObject:bdiClient forKey:server.name]; // cannot use my name
        NSString* nsi = [NSString stringWithFormat:@"%ld", (long)CFAbsoluteTimeGetCurrent()];
        [self.listClients setObject:bdiClient forKey:nsi];
        [bdiClient openStreams];
    }

    - (BOOL) connectToServer:(NSNetService*)server
    {
        BOOL bSuccess = NO;
        NSInputStream *iStream;
        NSOutputStream *oStream;
        
        // Create and open streams for the service.
        //
        // -getInputStream:outputStream: just creates the streams, it doesn't hit the
        // network, and thus it shouldn't fail under normal circumstances (in fact, its
        // CFNetService equivalent, CFStreamCreatePairWithSocketToNetService, returns no status
        // at all).  So, I didn't spend too much time worrying about the error case here.  If
        // we do get an error, you end up staying in the picker.  OTOH, actual connection errors
        // get handled via the NSStreamEventErrorOccurred event.
        bSuccess = [server getInputStream:&iStream outputStream:&oStream];
        if ( bSuccess ) {
            BluetoothDeviceInfo *bdiServer = [[BluetoothDeviceInfo alloc] initializeAsServer:YES withService:server inputStream:iStream outputStream:oStream];
            [self.listServers setObject:bdiServer forKey:server.name];
            [bdiServer openStreams];
            [self.theServer stop];
            [self.theServer release];
            self.theServer = nil;
            
            [self.theClient stop];
            
            [bdiServer sendData:"Hello World" withLength:11];
        }
        return bSuccess;
    }

    - (void) sendBroadcast:(const char*)pbyData withLength:(int)length
    {
        NSArray *arrayPeers = nil;
        if ( self.meServer == 0 ) {
            arrayPeers = [self.listServers allValues];
        } else {
            arrayPeers = [self.listClients allValues];
        }
        BluetoothDeviceInfo *pDevice = nil;
        for ( int i = 0; i < [arrayPeers count]; i++ ) {
            pDevice = [arrayPeers objectAtIndex:i];
            [pDevice sendData:pbyData withLength:length];
        }
    }

#pragma NSNetServiceDelegate

    /* Sent to the NSNetService instance's delegate prior to advertising the service on the network. If for some reason the service cannot be published, the delegate will not receive this message, and an error will be delivered to the delegate via the delegate's -netService:didNotPublish: method.
     */
    - (void)netServiceWillPublish:(NSNetService *)sender
    {
        NSLog(@"netServiceWillPublish: %@", sender.name);
    }

    /* Sent to the NSNetService instance's delegate when the publication of the instance is complete and successful.
     */
    - (void)netServiceDidPublish:(NSNetService *)sender
    {
        NSLog(@"netServiceDidPublish: %@", sender.name);
    }

    /* Sent to the NSNetService instance's delegate when an error in publishing the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants). It is possible for an error to occur after a successful publication.
     */
    - (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
    {
        NSLog(@"netServiceDidNotPublish: %@", sender.name);
    }

    /* Sent to the NSNetService instance's delegate prior to resolving a service on the network. If for some reason the resolution cannot occur, the delegate will not receive this message, and an error will be delivered to the delegate via the delegate's -netService:didNotResolve: method.
     */
    - (void)netServiceWillResolve:(NSNetService *)sender
    {
        NSLog(@"netServiceWillResolve: %@", sender.name);
    }

    /* Sent to the NSNetService instance's delegate when one or more addresses have been resolved for an NSNetService instance. Some NSNetService methods will return different results before and after a successful resolution. An NSNetService instance may get resolved more than once; truly robust clients may wish to resolve again after an error, or to resolve more than once.
     */
    - (void)netServiceDidResolveAddress:(NSNetService *)sender
    {
        NSLog(@"netServiceDidResolveAddress: %@", sender.name);
    }

    /* Sent to the NSNetService instance's delegate when an error in resolving the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants).
     */
    - (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
    {
        NSLog(@"netServiceDidNotResolve: %@", sender.name);
    }

    /* Sent to the NSNetService instance's delegate when the instance's previously running publication or resolution request has stopped.
     */
    - (void)netServiceDidStop:(NSNetService *)sender
    {
        NSLog(@"netServiceDidStop: %@", sender.name);
    }

    /* Sent to the NSNetService instance's delegate when the instance is being monitored and the instance's TXT record has been updated. The new record is contained in the data parameter.
     */
    - (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
    {
        NSLog(@"netServiceDidUpdateTXTRecordData: %@", sender.name);
    }

    /* Sent to a published NSNetService instance's delegate when a new connection is
     * received. Before you can communicate with the connecting client, you must -open
     * and schedule the streams. To reject a connection, just -open both streams and
     * then immediately -close them.
     
     * To enable TLS on the stream, set the various TLS settings using
     * kCFStreamPropertySSLSettings before calling -open. You must also specify
     * kCFBooleanTrue for kCFStreamSSLIsServer in the settings dictionary along with
     * a valid SecIdentityRef as the first entry of kCFStreamSSLCertificates.
     */
    - (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
    {
        NSLog(@"netServiceDidAcceptConnectionWithInputStream: %@", sender.name);
        
        // I am server
        if ( self.theClient != nil ) {
            [self.theClient stop];      // stop searching
            [self.theClient release];   // release
            self.theClient = nil;       // mark as server
        }
        
        // Due to a bug <rdar://problem/15626440>, this method is called on some unspecified
        // queue rather than the queue associated with the net service (which in this case
        // is the main queue).  Work around this by bouncing to the main queue.
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self onClientConnected:sender inputStream:inputStream outputStream:outputStream];
        }];
    }

#pragma NSNetServiceBrowserDelegate

    /* Sent to the NSNetServiceBrowser instance's delegate before the instance begins a search. The delegate will not receive this message if the instance is unable to begin a search. Instead, the delegate will receive the -netServiceBrowser:didNotSearch: message.
     */
    - (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
    {
        NSLog(@"netServiceBrowserWillSearch");
    }

    /* Sent to the NSNetServiceBrowser instance's delegate when the instance's previous running search request has stopped.
     */
    - (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
    {
        NSLog(@"netServiceBrowserDidStopSearch");
    }

    /* Sent to the NSNetServiceBrowser instance's delegate when an error in searching for domains or services has occurred. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants). It is possible for an error to occur after a search has been started successfully.
     */
    - (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
    {
        NSLog(@"netServiceBrowserDidNotSearch");
    }

    /* Sent to the NSNetServiceBrowser instance's delegate for each domain discovered. If there are more domains, moreComing will be YES. If for some reason handling discovered domains requires significant processing, accumulating domains until moreComing is NO and then doing the processing in bulk fashion may be desirable.
     */
    - (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
    {
        NSLog(@"netServiceBrowserDidFindDomain: %@, %d", domainString, moreComing ? 1 : 0);
    }

    /* Sent to the NSNetServiceBrowser instance's delegate for each service discovered. If there are more services, moreComing will be YES. If for some reason handling discovered services requires significant processing, accumulating services until moreComing is NO and then doing the processing in bulk fashion may be desirable.
     */
    - (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
    {
        NSLog(@"netServiceBrowserDidFindService: %@, %d", aNetService.name, moreComing ? 1 : 0);
        
        [self.arrayServices addObject:aNetService];
        [self refreshViewController];
    }

    /* Sent to the NSNetServiceBrowser instance's delegate when a previously discovered domain is no longer available.
     */
    - (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing
    {
        NSLog(@"netServiceBrowserDidRemoveDomain: %@, %d", domainString, moreComing ? 1 : 0);
    }

    /* Sent to the NSNetServiceBrowser instance's delegate when a previously discovered service is no longer published.
     */
    - (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
    {
        NSLog(@"netServiceBrowserDidRemoveService: %@, %d", aNetService.name, moreComing ? 1 : 0);
        
        [self.arrayServices removeObject:aNetService];
        [self refreshViewController];
    }


- (void) refreshViewController
{
    [[ViewController currentViewController] reloadData];
}

@end

extern "C"
{
    void Initialize()
    {
        meServer = [[BluetoothServerInfo alloc] init];
    }
    
    void StartServer()
    {
        [meServer startServer];
    }
    
    void StartClient()
    {
        [meServer startClient];
    }
    
    BluetoothServerInfo* GetManager()
    {
        return meServer;
    }
    
    void SendBroadcast(const char* pbyData, int iLength)
    {
        [meServer sendBroadcast:pbyData withLength:iLength];
    }
    
    void ReceiveBroadcast(const char* pbyData, int iLength)
    {
        [[ViewController currentViewController].dataLabel setText:[NSString stringWithFormat:@"RECEIVED: %s", pbyData]];
    }
    
}// end extern "C"