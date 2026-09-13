#import "Health.h"
#include <assert.h>

static NSMutableDictionary *emptySnapshot(void) {
    return [@{@"docks": @[], @"controllers": @[], @"devices": @[], @"ports": @[], @"errors": @[]} mutableCopy];
}

int main(void) {
    @autoreleasepool {
        NSMutableDictionary *snapshot = emptySnapshot();
        assert([DockAssessment(snapshot)[@"state"] isEqual:@"not_detected"]);
        snapshot[@"docks"] = @[@{@"id": @"dock1"}];
        assert([DockAssessment(snapshot)[@"state"] isEqual:@"transport_detected"]);
        snapshot[@"controllers"] = @[@{@"id": @"controller1", @"dock": @"dock1"}];
        assert([DockAssessment(snapshot)[@"state"] isEqual:@"controllers_detected"]);
        snapshot[@"devices"] = @[@{@"dock": @"dock1", @"name": @"Built-in audio", @"vendorID": @1, @"productID": @2}];
        assert([DockAssessment(snapshot)[@"state"] isEqual:@"usb_enumerated"]);
        assert(![DockAssessment(snapshot)[@"deviceIOVerified"] boolValue]);
        assert(![DockAssessment(snapshot)[@"repairsAttempted"] boolValue]);
        assert([DockSummary(snapshot) containsString:@"does not verify input events"]);
        // Empty ports and old error counters are observations, not current failures.
        snapshot[@"ports"] = @[@{@"statusRaw": @0, @"enumerationFailures": @4}];
        assert([DockAssessment(snapshot)[@"state"] isEqual:@"usb_enumerated"]);
        snapshot[@"errors"] = @[@{@"class": @"AppleUSBHostController", @"status": @"fixture error"}];
        assert([DockAssessment(snapshot)[@"state"] isEqual:@"incomplete"]);
        assert([DockSummary(snapshot) containsString:@"Query error"]);
        puts("Dock health tests passed: layered enumeration, query failure, empty ports and unverified device I/O.");
    }
    return 0;
}
