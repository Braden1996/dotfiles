#import "PolicyGuard.h"
#include <assert.h>
int main(void) {@autoreleasepool {
    DisplayPolicyGuard *g=[DisplayPolicyGuard new];
    assert(![g observeTopology:@"asus+xdr" at:0]);
    assert(![g observeTopology:@"asus+xdr" at:1]);
    assert([g observeTopology:@"asus+xdr" at:2]);
    assert([g allowAction:@"asus-cap" at:2]);
    [g didAttemptMutationAt:2];
    assert(![g observeTopology:@"asus" at:3]); // transient loss during EDID negotiation
    assert(![g allowAction:@"asus-reset" at:3]);
    assert(![g observeTopology:@"asus+xdr" at:5]);
    assert(![g observeTopology:@"asus+xdr" at:6]);
    assert([g observeTopology:@"asus+xdr" at:7]);
    assert(![g allowAction:@"asus-cap" at:7]); // cooldown
    assert([g allowAction:@"asus-cap" at:32]);
    assert(![g allowAction:@"asus-cap" at:62]); // finite budget even much later
    assert([g observeTopology:@"asus+xdr" at:1000]);
    assert(![g allowAction:@"asus-cap" at:1000]);
    assert(![g observeTopology:@"asus" at:1001]);
    assert(![g observeTopology:@"asus+xdr" at:1002]); // unsettled false change cannot replenish
    assert([g observeTopology:@"asus+xdr" at:1004]);
    assert(![g allowAction:@"asus-cap" at:1004]);
    assert(![g observeTopology:@"asus" at:1005]);
    assert([g observeTopology:@"asus" at:1007]);
    assert([g allowAction:@"asus-reset" at:1007]);
    assert([g allowAction:@"asus-cap" at:1007]); // actual stable topology change replenishes
    for(unsigned wake=0;wake<4;wake++) {
        double t=2000+wake*100;
        [g didWakeAt:t];
        assert(![g observeTopology:@"asus" at:t+1]); // wake grace
        assert(![g observeTopology:@"asus" at:t+3]); // then fresh topology settlement
        assert(![g observeTopology:@"asus" at:t+4]);
        assert([g observeTopology:@"asus" at:t+5]);
        assert([g allowAction:@"asus-cap" at:t+5]);
        assert(![g allowAction:@"asus-cap" at:t+6]);
        assert([g allowAction:@"asus-cap" at:t+35]);
        assert([g observeTopology:@"asus" at:t+65]); // ordinary same-topology events
        assert(![g allowAction:@"asus-cap" at:t+65]); // still bounded within this wake
        assert([g observeTopology:@"asus" at:t+75]);
        assert(![g allowAction:@"asus-cap" at:t+75]);
    }
    puts("Policy guard tests passed: stable topology, mutation/wake grace, cooldown, bounded attempts, repeated real wakes, and no budget replenishment from ordinary events.");
    return 0;
}}
