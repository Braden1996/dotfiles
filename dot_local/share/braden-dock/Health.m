#import "Health.h"

NSDictionary *DockAssessment(NSDictionary *snapshot) {
    NSUInteger docks = [snapshot[@"docks"] count];
    NSUInteger controllers = [snapshot[@"controllers"] count];
    NSUInteger devices = [snapshot[@"devices"] count];
    BOOL incomplete = [snapshot[@"errors"] count] != 0;
    NSString *state;
    NSString *meaning;
    if (incomplete) {
        state = @"incomplete";
        meaning = @"At least one registry query failed; missing entries are not reliable absence evidence.";
    } else if (!docks) {
        state = @"not_detected";
        meaning = @"No enumerated TS3 Plus Thunderbolt switch was found. This cannot distinguish an unplugged dock from a link that has not established.";
    } else if (!controllers) {
        state = @"transport_detected";
        meaning = @"TS3 Plus transport is enumerated, but no USB host controller was attributed to it in this snapshot.";
    } else if (!devices) {
        state = @"controllers_detected";
        meaning = @"USB host controllers are attributed to the dock, but no USB devices were found beneath them in this snapshot.";
    } else {
        state = @"usb_enumerated";
        meaning = @"USB devices enumerate beneath the dock's controllers. This does not verify input events, storage access or other device I/O.";
    }
    return @{
        @"state": state,
        @"meaning": meaning,
        @"dockCount": @(docks),
        @"controllerCount": @(controllers),
        @"usbDeviceCount": @(devices),
        @"deviceIOVerified": @NO,
        @"repairsAttempted": @NO
    };
}

NSString *DockSummary(NSDictionary *snapshot) {
    NSDictionary *assessment = DockAssessment(snapshot);
    NSDictionary *labels = @{@"not_detected": @"not detected",
        @"transport_detected": @"Thunderbolt transport detected",
        @"controllers_detected": @"USB controllers detected",
        @"usb_enumerated": @"USB devices enumerated", @"incomplete": @"incomplete snapshot"};
    NSMutableString *text = [NSMutableString stringWithFormat:
        @"CalDigit TS3 Plus: %@\nDock transports: %@; attributed USB controllers: %@; enumerated USB devices: %@\n%@\n",
        labels[assessment[@"state"]], assessment[@"dockCount"], assessment[@"controllerCount"],
        assessment[@"usbDeviceCount"], assessment[@"meaning"]];
    for (NSDictionary *device in snapshot[@"devices"]) {
        [text appendFormat:@"  %@: %@ (USB %04x:%04x)\n",
            device[@"dock"], device[@"name"] ?: @"Unnamed USB device",
            [device[@"vendorID"] unsignedIntValue], [device[@"productID"] unsignedIntValue]];
    }
    for (NSDictionary *error in snapshot[@"errors"])
        [text appendFormat:@"  Query error: %@ (%@)\n", error[@"class"], error[@"status"]];
    [text appendString:@"Read-only snapshot; no hardware changes. Use --json for controller and port details.\n"];
    return text;
}
