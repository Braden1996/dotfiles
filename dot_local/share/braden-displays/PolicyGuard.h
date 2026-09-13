#import <Foundation/Foundation.h>

/// Small deterministic guard shared by the watcher and the command-line entry points.
@interface DisplayPolicyGuard : NSObject
- (BOOL)observeTopology:(NSString *)fingerprint at:(NSTimeInterval)now;
- (BOOL)allowAction:(NSString *)action at:(NSTimeInterval)now;
- (void)didAttemptMutationAt:(NSTimeInterval)now;
/// A real system wake starts a fresh bounded recovery epoch, even if cables stayed put.
- (void)didWakeAt:(NSTimeInterval)now;
@end
