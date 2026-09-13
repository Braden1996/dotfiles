// Simulated IOKit trees only. No hardware query is performed by these tests.
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#include <assert.h>
#include <sys/sysctl.h>

static NSMutableDictionary *nodes, *iterators, *iteratorClasses, *paths;
static NSString *failedClass, *invalidatedClass;
static unsigned missingID;
static io_object_t nextIterator;

static CFMutableDictionaryRef fakeMatching(const char *name) {
    return (__bridge_retained CFMutableDictionaryRef)[@{@"class": @(name)} mutableCopy];
}
static kern_return_t fakeServices(mach_port_t port, CFDictionaryRef matching, io_iterator_t *iterator) {
    (void)port;
    NSString *wanted = ((__bridge NSDictionary *)matching)[@"class"];
    CFRelease(matching);
    if ([wanted isEqualToString:failedClass]) return kIOReturnError;
    NSMutableArray *matches = [NSMutableArray array];
    for (NSNumber *identifier in [[nodes allKeys] sortedArrayUsingSelector:@selector(compare:)])
        if ([nodes[identifier][@"matches"] containsObject:wanted]) [matches addObject:identifier];
    *iterator = nextIterator++;
    iterators[@(*iterator)] = matches;
    iteratorClasses[@(*iterator)] = wanted;
    return KERN_SUCCESS;
}
static io_object_t fakeNext(io_iterator_t iterator) {
    NSMutableArray *matches = iterators[@(iterator)];
    if (!matches.count) return IO_OBJECT_NULL;
    io_object_t next = [matches[0] unsignedIntValue];
    [matches removeObjectAtIndex:0];
    return next;
}
static kern_return_t fakeRetain(io_object_t object) { (void)object; return KERN_SUCCESS; }
static boolean_t fakeValid(io_iterator_t iterator) {
    return ![iteratorClasses[@(iterator)] isEqualToString:invalidatedClass];
}
static kern_return_t fakeRelease(io_object_t object) {
    [iterators removeObjectForKey:@(object)];
    [iteratorClasses removeObjectForKey:@(object)];
    return KERN_SUCCESS;
}
static boolean_t fakeConforms(io_object_t object, const io_name_t className) {
    return [nodes[@(object)][@"matches"] containsObject:@(className)];
}
static kern_return_t fakeClass(io_object_t object, io_name_t result) {
    strlcpy(result, [nodes[@(object)][@"class"] UTF8String], sizeof(io_name_t));
    return KERN_SUCCESS;
}
static kern_return_t fakeName(io_registry_entry_t object, io_name_t result) {
    strlcpy(result, [nodes[@(object)][@"name"] UTF8String], sizeof(io_name_t));
    return KERN_SUCCESS;
}
static kern_return_t fakeID(io_registry_entry_t object, uint64_t *identifier) {
    if (object == missingID) return kIOReturnNotFound;
    *identifier = object;
    return KERN_SUCCESS;
}
static CFTypeRef fakeProperty(io_registry_entry_t object, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options) {
    (void)allocator; (void)options;
    id value = nodes[@(object)][@"properties"][(__bridge NSString *)key];
    return value ? CFBridgingRetain(value) : NULL;
}
static kern_return_t fakeParent(io_registry_entry_t object, const io_name_t plane, io_registry_entry_t *parent) {
    (void)plane;
    *parent = [nodes[@(object)][@"parent"] unsignedIntValue];
    return *parent ? KERN_SUCCESS : kIOReturnNotFound;
}
static io_registry_entry_t fakeFromPath(mach_port_t port, const io_string_t path) {
    (void)port;
    return [paths[@(path)] unsignedIntValue];
}
static int fakeSysctl(const char *name, void *value, size_t *size, void *newValue, size_t newSize) {
    (void)name; (void)newValue; (void)newSize;
    const char *model = "FixtureMac";
    assert(*size > strlen(model));
    strcpy(value, model);
    *size = strlen(model) + 1;
    return 0;
}

#define IOServiceMatching fakeMatching
#define IOServiceGetMatchingServices fakeServices
#define IOIteratorNext fakeNext
#define IOIteratorIsValid fakeValid
#define IOObjectRetain fakeRetain
#define IOObjectRelease fakeRelease
#define IOObjectGetClass fakeClass
#define IOObjectConformsTo fakeConforms
#define IORegistryEntryGetName fakeName
#define IORegistryEntryGetRegistryEntryID fakeID
#define IORegistryEntryCreateCFProperty fakeProperty
#define IORegistryEntryGetParentEntry fakeParent
#define IORegistryEntryFromPath fakeFromPath
#define sysctlbyname fakeSysctl
#define main DockProgramMain
#include <main.m>
#undef main

static void add(unsigned identifier, NSString *className, unsigned parent, NSDictionary *properties) {
    nodes[@(identifier)] = [@{@"class": className, @"matches": @[className],
        @"name": className, @"parent": @(parent), @"properties": [properties mutableCopy]} mutableCopy];
}
static void reset(void) {
    nodes = [NSMutableDictionary dictionary];
    iterators = [NSMutableDictionary dictionary];
    iteratorClasses = [NSMutableDictionary dictionary];
    paths = [NSMutableDictionary dictionary];
    nextIterator = 9000;
    failedClass = nil;
    invalidatedClass = nil;
    missingID = 0;
}
static void connectedTree(void) {
    reset();
    // The dock is behind another Thunderbolt device, not directly under a host.
    add(100, @"IOThunderboltSwitch", 0, @{@"Device Vendor ID": @1552, @"Device Model ID": @999});
    add(200, @"IOThunderboltSwitch", 100, @{@"Device Vendor ID": @61, @"Device Model ID": @17,
        @"Vendor ID": @32902, @"Device UID": @"fixture-private-identifier"});
    add(210, @"IOThunderboltPort", 200, @{});
    add(110, @"IOThunderboltPort", 100, @{});
    paths[@"IOService:/fixture/dock-port"] = @210;
    paths[@"IOService:/fixture/other-port"] = @110;
    const uint8_t vendorBytes[] = {0x73, 0x1b, 0, 0};
    add(301, @"IOPCIDevice", 0, @{@"Thunderbolt Path": @"IOService:/fixture/dock-port",
        @"vendor-id": [NSData dataWithBytes:vendorBytes length:sizeof vendorBytes], @"device-id": @0x1100});
    add(300, @"AppleUSBHostController", 301, @{});
    add(351, @"IOPCIDevice", 0, @{@"Thunderbolt Path": @"IOService:/fixture/other-port"});
    add(350, @"AppleUSBHostController", 351, @{});
    add(410, @"AppleUSB20XHCIPort", 300, @{@"port-status": @0,
        @"port-statistics": @{@"kPortStatConnectCount": @0, @"kPortStatEnumerationFailureCount": @0,
                             @"UnapprovedField": @"fixture-private-identifier"}});
    add(400, @"IOUSBHostDevice", 410, @{@"idVendor": @0x2188, @"idProduct": @0x20,
        @"USB Product Name": @"Built-in audio", @"USB Serial Number": @"fixture-private-identifier"});
    add(450, @"IOUSBHostDevice", 350, @{@"USB Product Name": @"Unrelated display USB"});
    // Matching must include devices behind hubs, not just the first USB roots.
    add(520, @"IOUSBHostDevice", 410, @{@"USB Product Name": @"Fixture hub", @"idVendor": @1, @"idProduct": @2});
    add(510, @"AppleUSB20XHCIPort", 520, @{});
    add(500, @"IOUSBHostDevice", 510, @{@"USB Product Name": @"Fixture receiver", @"idVendor": @3, @"idProduct": @4});
}

int main(void) {
    @autoreleasepool {
        connectedTree();
        NSDictionary *report = snapshot();
        assert([report[@"docks"] count] == 1);
        assert([report[@"controllers"] count] == 1);
        assert([report[@"devices"] count] == 3);
        assert([report[@"ports"] count] == 2);
        assert([report[@"controllers"][0][@"pciVendorID"] unsignedIntValue] == 0x1b73);
        assert([report[@"assessment"][@"state"] isEqual:@"usb_enumerated"]);
        assert(![report[@"assessment"][@"deviceIOVerified"] boolValue]);
        NSData *json = [NSJSONSerialization dataWithJSONObject:report options:0 error:NULL];
        NSString *text = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        assert(![text containsString:@"fixture-private-identifier"]);
        assert(![text containsString:@"Unrelated display USB"]);
        assert(![text containsString:@"IOService:/fixture"]);
        assert(iterators.count == 0);

        // The opposite chain: another dock below the TS3 owns its own USB tree.
        add(250, @"IOThunderboltSwitch", 200, @{@"Device Vendor ID": @99, @"Device Model ID": @88});
        add(260, @"IOThunderboltPort", 250, @{});
        paths[@"IOService:/fixture/dock-port"] = @260;
        report = snapshot();
        assert([report[@"docks"] count] == 1);
        assert([report[@"controllers"] count] == 0 && [report[@"devices"] count] == 0);
        assert([report[@"assessment"][@"state"] isEqual:@"transport_detected"]);

        connectedTree();

        // A descriptive name or the generic Intel vendor field is insufficient.
        nodes[@200][@"properties"][@"Device Vendor ID"] = @32902;
        nodes[@200][@"properties"][@"Vendor ID"] = @61;
        report = snapshot();
        assert([report[@"docks"] count] == 0 && [report[@"devices"] count] == 0);
        assert([report[@"assessment"][@"state"] isEqual:@"not_detected"]);

        connectedTree();
        failedClass = @"AppleUSBHostController";
        report = snapshot();
        assert([report[@"errors"] count] == 1);
        assert([report[@"assessment"][@"state"] isEqual:@"incomplete"]);

        connectedTree();
        invalidatedClass = @"IOUSBHostDevice";
        report = snapshot();
        assert([report[@"errors"] count] == 1);
        assert([report[@"assessment"][@"state"] isEqual:@"incomplete"]);

        connectedTree();
        missingID = 300;
        report = snapshot();
        assert([report[@"errors"] count] == 1);
        assert([report[@"assessment"][@"state"] isEqual:@"incomplete"]);

        connectedTree();
        [paths removeObjectForKey:@"IOService:/fixture/dock-port"];
        report = snapshot();
        assert([report[@"controllers"] count] == 0 && [report[@"devices"] count] == 0);
        assert([report[@"assessment"][@"state"] isEqual:@"transport_detected"]);
        puts("Dock registry tests passed without hardware: both dock-chain orders, nested USB, redaction, query failure, invalidated iterators and disappearing controllers.");
    }
    return 0;
}
