//
//  InterpreterListener.m
//  Nu
//
//  Created by Matt Beshara on 8/3/21.
//

#import "InterpreterListener.h"
#import "Nu.h"

@implementation InterpreterListener

- (id _Nullable)init {
    nw_parameters_t parameters = nw_parameters_create_secure_tcp(NW_PARAMETERS_DISABLE_PROTOCOL, NW_PARAMETERS_DEFAULT_CONFIGURATION);
    self.listener = nw_listener_create(parameters);
    if (self.listener == nil) {
        return nil;
    }

    nw_listener_set_queue(self.listener, dispatch_get_main_queue());

    nw_advertise_descriptor_t descriptor = nw_advertise_descriptor_create_bonjour_service("NuApp", "_nu._tcp", nil);
    nw_listener_set_advertise_descriptor(self.listener, descriptor);

    nw_listener_set_state_changed_handler(self.listener, ^(nw_listener_state_t state, nw_error_t  _Nullable error) {
        [self handleChangeToState:state withError:error];
    });

    nw_listener_set_new_connection_handler(self.listener, ^(nw_connection_t  _Nonnull connection) {
        [self receiveOnConnection:connection];
        nw_connection_set_queue(connection, dispatch_get_main_queue());
        nw_connection_start(connection);
    });

    return self;
}

- (void)receiveOnConnection:(nw_connection_t _Nonnull )connection {
    nw_connection_receive(connection, 0, UINT32_MAX, ^(dispatch_data_t  _Nullable content, nw_content_context_t  _Nullable context, bool is_complete, nw_error_t  _Nullable error) {
        if (error != nil && nw_error_get_error_code(error) != 0) {
            NSString *errorString = [NSString stringWithFormat:@"Error receiving from client: %@\n", error];
            self.evalResultHandler(errorString);
            return;
        }

        [self handleReceiveFromConnection:connection data:content withContext:context isComplete:is_complete error:error];
        [self receiveOnConnection:connection];
    });
}

- (void)listenWithCompletionHandler:(void (^_Nullable)(uint16_t))completionHandler {
    self.listenCompletionHandler = completionHandler;
    nw_listener_start(self.listener);
}

- (void)handleChangeToState:(nw_listener_state_t)state withError:(nw_error_t _Nullable)error {
    if (self.listenCompletionHandler != nil && state == nw_listener_state_ready) {
        self.listenCompletionHandler(nw_listener_get_port(self.listener));
        self.listenCompletionHandler = nil;
    }
}

- (void)handleReceiveFromConnection:(nw_connection_t _Nonnull )connection data:(dispatch_data_t  _Nullable)content withContext:(nw_content_context_t _Nullable) context isComplete:(bool)is_complete error:(nw_error_t _Nullable)error {
    if (content != nil) {
        dispatch_data_apply(content, ^bool(dispatch_data_t  _Nonnull region, size_t offset, const void * _Nonnull buffer, size_t size) {
            NSData *data = [NSData dataWithBytes:buffer length:size];
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [string autorelease];

            string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];

            id cell = nil;
            @try {
                cell = [[Nu sharedParser] parse:string];
            } @catch (NSException *exception) {
                NSString *exceptionMessage = [NSString stringWithFormat:@"!!! Caught exception in parse, resetting parser: %@", exception];
                [self handleEvalResult:exceptionMessage withConnection:connection];
                [[Nu sharedParser] reset];
                return YES;
            }

            if (![[Nu sharedParser] incomplete]) {
                @try {
                    id result = [[Nu sharedParser] eval:cell];
                    if (result != nil) {
                        [self handleEvalResult:result withConnection:connection];
                    }
                } @catch (NSException *exception) {
                    NSString *exceptionMessage = [NSString stringWithFormat:@"!!! Caught exception in eval: %@", exception];
                    [self handleEvalResult:exceptionMessage withConnection:connection];
                }
            }

            return YES;
        });
    }
}

- (void)handleEvalResult:(id _Nonnull)result withConnection:(nw_connection_t _Nonnull)connection {
    if (self.evalResultHandler != nil) {
        self.evalResultHandler(result);
    }

    NSString *resultString = [NSString stringWithFormat:@"%@\n", result];
    NSData *resultData = [resultString dataUsingEncoding:NSUTF8StringEncoding];
    dispatch_data_t data = dispatch_data_create([resultData bytes], [resultData length], dispatch_get_main_queue(), DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    nw_connection_send(connection, data, NW_CONNECTION_DEFAULT_MESSAGE_CONTEXT, YES, ^(nw_error_t  _Nullable error) {
        if (error != nil && self.evalResultHandler != nil) {
            NSString *errorString = [NSString stringWithFormat:@"Error sending result string to client: %@\n", error];
            self.evalResultHandler(errorString);
        }
    });
}

@end
