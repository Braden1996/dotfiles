#import "PolicyGuard.h"

@interface DisplayPolicyGuard ()
@property(nonatomic,copy) NSString *stableTopology;
@property(nonatomic,copy) NSString *candidateTopology;
@property(nonatomic) NSTimeInterval candidateSince;
@property(nonatomic) NSTimeInterval graceUntil;
@property(nonatomic,strong) NSMutableDictionary<NSString *,NSNumber *> *counts;
@property(nonatomic,strong) NSMutableDictionary<NSString *,NSNumber *> *lastAttempts;
@end

@implementation DisplayPolicyGuard
- (instancetype)init {
    if((self=[super init])) {_counts=[NSMutableDictionary dictionary];_lastAttempts=[NSMutableDictionary dictionary];}
    return self;
}
- (BOOL)observeTopology:(NSString *)fingerprint at:(NSTimeInterval)now {
    if(now<self.graceUntil)return NO;
    if(![fingerprint isEqualToString:self.candidateTopology]) {
        self.candidateTopology=fingerprint;self.candidateSince=now;return NO;
    }
    if(now-self.candidateSince<2.0)return NO;
    if(![fingerprint isEqualToString:self.stableTopology]) {
        self.stableTopology=fingerprint;
        [self.counts removeAllObjects];[self.lastAttempts removeAllObjects];
    }
    return YES;
}
- (BOOL)allowAction:(NSString *)action at:(NSTimeInterval)now {
    if(!self.stableTopology||now<self.graceUntil)return NO;
    if([self.counts[action] unsignedIntegerValue]>=2)return NO;
    NSNumber *last=self.lastAttempts[action];
    if(last&&now-last.doubleValue<30.0)return NO;
    self.counts[action]=@([self.counts[action] unsignedIntegerValue]+1);
    self.lastAttempts[action]=@(now);return YES;
}
- (void)didAttemptMutationAt:(NSTimeInterval)now {
    self.graceUntil=now+3.0;
    // Ignore topology fluctuations produced by the mutation itself, then re-settle.
    // A reappearing identical topology does not replenish the action budget.
    self.candidateTopology=nil;
}
- (void)didWakeAt:(NSTimeInterval)now {
    [self.counts removeAllObjects];[self.lastAttempts removeAllObjects];
    self.candidateTopology=nil;
    self.graceUntil=MAX(self.graceUntil,now+3.0);
}
@end
