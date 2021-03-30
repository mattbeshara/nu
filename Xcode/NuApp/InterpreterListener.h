//
//  InterpreterListener.h
//  Nu
//
//  Created by Matt Beshara on 8/3/21.
//

#import <Foundation/Foundation.h>
#import <Network/Network.h>

@interface InterpreterListener : NSObject

@property (copy, nonatomic, nullable) void (^evalResultHandler)(id _Nullable);
@property (assign, nonatomic, nullable) nw_listener_t listener;
@property (copy, nonatomic, nullable) void (^listenCompletionHandler)(uint16_t);

- (id _Nullable)init;
- (void)receiveOnConnection:(nw_connection_t _Nonnull )connection;
- (void)listenWithCompletionHandler:(void (^_Nullable)(uint16_t))completionHandler;
- (void)handleChangeToState:(nw_listener_state_t)state withError:(nw_error_t _Nullable)error;
- (void)handleReceiveFromConnection:(nw_connection_t _Nonnull )connection data:(dispatch_data_t  _Nullable)content withContext:(nw_content_context_t _Nullable) context isComplete:(bool)is_complete error:(nw_error_t _Nullable)error;
- (void)parseEval:(NSString * _Nonnull)string;
- (void)parseEval:(NSString * _Nonnull)string withConnection:(nw_connection_t _Nullable)connection;
- (void)handleEvalResult:(id _Nonnull)result withConnection:(nw_connection_t _Nullable)connection;

@end

