//
//  BluetoothUtil.h
//  MyBonjour
//
//  Created by Hakim Hauston on 21/8/15.
//  Copyright (c) 2015 Hakim Hauston. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BluetoothDeviceInfo : NSObject<NSStreamDelegate>

    @property (nonatomic)           BOOL                isServer;
    @property (nonatomic, retain)   NSNetService*       theService;
    @property (nonatomic, retain)   NSInputStream*      inputStream;
    @property (nonatomic, retain)   NSOutputStream*     outputStream;

    - (id) initializeAsServer:(BOOL)bServer withService:(NSNetService*)server inputStream:(NSInputStream*)iStream outputStream:(NSOutputStream*)oStream;

    - (void) openStreams;
    - (void) closeStreams;

    - (void) sendData:(const char*)pbyData withLength:(int)length;

#pragma NSStreamDelegate

    - (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;

@end

@interface BluetoothServerInfo : NSObject <NSNetServiceDelegate, NSNetServiceBrowserDelegate, NSStreamDelegate>

    @property (nonatomic, retain)   NSNetService*           theServer;
    @property (nonatomic, retain)   NSNetServiceBrowser*    theClient;

    @property (nonatomic, retain)   NSMutableDictionary*    listServers;    // NSString => NSNetService
    @property (nonatomic, retain)   NSMutableDictionary*    listClients;    // NSString => NSNetService

    @property (nonatomic, retain)   NSMutableArray*         arrayServices;  // NSNetService

- (int) meServer;
- (void) startServer;
- (void) startClient;

- (void) onClientConnected:(NSNetService*)server inputStream:(NSInputStream*)iStream outputStream:(NSOutputStream*)oStream;
- (BOOL) connectToServer:(NSNetService*)server;

- (void) sendBroadcast:(const char*)pbyData withLength:(int)length;

#pragma NSNetServiceDelegate

/* Sent to the NSNetService instance's delegate prior to advertising the service on the network. If for some reason the service cannot be published, the delegate will not receive this message, and an error will be delivered to the delegate via the delegate's -netService:didNotPublish: method.
 */
- (void)netServiceWillPublish:(NSNetService *)sender;

/* Sent to the NSNetService instance's delegate when the publication of the instance is complete and successful.
 */
- (void)netServiceDidPublish:(NSNetService *)sender;

/* Sent to the NSNetService instance's delegate when an error in publishing the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants). It is possible for an error to occur after a successful publication.
 */
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict;

/* Sent to the NSNetService instance's delegate prior to resolving a service on the network. If for some reason the resolution cannot occur, the delegate will not receive this message, and an error will be delivered to the delegate via the delegate's -netService:didNotResolve: method.
 */
- (void)netServiceWillResolve:(NSNetService *)sender;

/* Sent to the NSNetService instance's delegate when one or more addresses have been resolved for an NSNetService instance. Some NSNetService methods will return different results before and after a successful resolution. An NSNetService instance may get resolved more than once; truly robust clients may wish to resolve again after an error, or to resolve more than once.
 */
- (void)netServiceDidResolveAddress:(NSNetService *)sender;

/* Sent to the NSNetService instance's delegate when an error in resolving the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants).
 */
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict;

/* Sent to the NSNetService instance's delegate when the instance's previously running publication or resolution request has stopped.
 */
- (void)netServiceDidStop:(NSNetService *)sender;

/* Sent to the NSNetService instance's delegate when the instance is being monitored and the instance's TXT record has been updated. The new record is contained in the data parameter.
 */
- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data;

/* Sent to a published NSNetService instance's delegate when a new connection is
 * received. Before you can communicate with the connecting client, you must -open
 * and schedule the streams. To reject a connection, just -open both streams and
 * then immediately -close them.
 
 * To enable TLS on the stream, set the various TLS settings using
 * kCFStreamPropertySSLSettings before calling -open. You must also specify
 * kCFBooleanTrue for kCFStreamSSLIsServer in the settings dictionary along with
 * a valid SecIdentityRef as the first entry of kCFStreamSSLCertificates.
 */
- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;

#pragma NSNetServiceBrowserDelegate

/* Sent to the NSNetServiceBrowser instance's delegate before the instance begins a search. The delegate will not receive this message if the instance is unable to begin a search. Instead, the delegate will receive the -netServiceBrowser:didNotSearch: message.
 */
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser;

/* Sent to the NSNetServiceBrowser instance's delegate when the instance's previous running search request has stopped.
 */
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser;

/* Sent to the NSNetServiceBrowser instance's delegate when an error in searching for domains or services has occurred. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants). It is possible for an error to occur after a search has been started successfully.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict;

/* Sent to the NSNetServiceBrowser instance's delegate for each domain discovered. If there are more domains, moreComing will be YES. If for some reason handling discovered domains requires significant processing, accumulating domains until moreComing is NO and then doing the processing in bulk fashion may be desirable.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing;

/* Sent to the NSNetServiceBrowser instance's delegate for each service discovered. If there are more services, moreComing will be YES. If for some reason handling discovered services requires significant processing, accumulating services until moreComing is NO and then doing the processing in bulk fashion may be desirable.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;

/* Sent to the NSNetServiceBrowser instance's delegate when a previously discovered domain is no longer available.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing;

/* Sent to the NSNetServiceBrowser instance's delegate when a previously discovered service is no longer published.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;



- (void) refreshViewController;

@end

extern "C" {
    void Initialize();
    void StartServer();
    void StartClient();
    void SendBroadcast(const char* pbyData, int iLength);
    void ReceiveBroadcast(const char* pbyData, int iLength);
    BluetoothServerInfo* GetManager();
}