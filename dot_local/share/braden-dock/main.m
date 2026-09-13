// Adapted from the author's public-registry provider probe in:
// https://github.com/Braden1996/caldigit-ts3-m5-diagnostics
// No user-client opens, private selectors, registry writes, probes or resets.
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import "Health.h"
#include <sys/sysctl.h>

static id property(io_registry_entry_t entry, NSString *key) {
    return CFBridgingRelease(IORegistryEntryCreateCFProperty(entry,
        (__bridge CFStringRef)key, kCFAllocatorDefault, 0));
}

static NSNumber *number(id value) {
    if ([value isKindOfClass:NSNumber.class]) return value;
    if ([value isKindOfClass:NSData.class] && [value length] > 0 && [value length] <= 8) {
        const uint8_t *bytes = [value bytes];
        uint64_t decoded = 0;
        for (NSUInteger i = 0; i < [value length]; i++) decoded |= (uint64_t)bytes[i] << (8 * i);
        return @(decoded);
    }
    return nil;
}

static NSString *string(id value) {
    return [value isKindOfClass:NSString.class] ? value : nil;
}

static NSString *registryClass(io_registry_entry_t entry) {
    io_name_t name = {0};
    return IOObjectGetClass(entry, name) == KERN_SUCCESS ? @(name) : @"unknown";
}

static NSString *registryName(io_registry_entry_t entry) {
    io_name_t name = {0};
    return IORegistryEntryGetName(entry, name) == KERN_SUCCESS ? @(name) : @"unknown";
}

static NSNumber *registryID(io_registry_entry_t entry) {
    uint64_t identifier = 0;
    return IORegistryEntryGetRegistryEntryID(entry, &identifier) == KERN_SUCCESS ? @(identifier) : nil;
}

static void eachService(NSString *className, NSMutableArray *errors,
                        void (^visit)(io_service_t)) {
    io_iterator_t iterator = IO_OBJECT_NULL;
    kern_return_t status = IOServiceGetMatchingServices(kIOMainPortDefault,
        IOServiceMatching(className.UTF8String), &iterator);
    if (status != KERN_SUCCESS) {
        [errors addObject:@{@"class": className,
            @"status": [NSString stringWithFormat:@"0x%08x", status]}];
        return;
    }
    io_service_t service;
    NSUInteger count = 0;
    while ((service = IOIteratorNext(iterator))) {
        if (++count > 4096) {
            [errors addObject:@{@"class": className, @"status": @"snapshot entry limit reached"}];
            IOObjectRelease(service);
            break;
        }
        visit(service);
        IOObjectRelease(service);
    }
    if (!IOIteratorIsValid(iterator)) {
        [errors addObject:@{@"class": className, @"status": @"registry changed during iteration; snapshot incomplete"}];
    }
    IOObjectRelease(iterator);
}

/// Include the starting service and stop after 64 ancestors. IDs stay internal.
static id nearestMappedAncestor(io_registry_entry_t entry, NSDictionary *mapping) {
    io_registry_entry_t current = entry;
    IOObjectRetain(current);
    for (NSUInteger depth = 0; depth < 64; depth++) {
        NSNumber *identifier = registryID(current);
        id match = identifier ? mapping[identifier] : nil;
        if (match) { IOObjectRelease(current); return match; }
        io_registry_entry_t parent = IO_OBJECT_NULL;
        kern_return_t status = IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent);
        IOObjectRelease(current);
        if (status != KERN_SUCCESS) return nil;
        current = parent;
    }
    IOObjectRelease(current);
    return nil;
}

static id nearestProperty(io_registry_entry_t entry, NSString *key) {
    io_registry_entry_t current = entry;
    IOObjectRetain(current);
    for (NSUInteger depth = 0; depth < 64; depth++) {
        id value = property(current, key);
        if (value) { IOObjectRelease(current); return value; }
        io_registry_entry_t parent = IO_OBJECT_NULL;
        kern_return_t status = IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent);
        IOObjectRelease(current);
        if (status != KERN_SUCCESS) return nil;
        current = parent;
    }
    IOObjectRelease(current);
    return nil;
}

static NSString *dockForController(io_service_t controller, NSDictionary *dockLabels) {
    // USB controllers live in the PCI tree, not below IOThunderboltSwitch.
    // Apple's bridge property joins that tree to the actual Thunderbolt port.
    NSString *path = string(nearestProperty(controller, @"Thunderbolt Path"));
    if (!path) return nil;
    io_registry_entry_t port = IORegistryEntryFromPath(kIOMainPortDefault, path.UTF8String);
    if (!port) return nil;
    // Ownership belongs to the nearest switch. Passing another dock on the way
    // to a TS3 would incorrectly claim that downstream dock's USB controllers.
    io_registry_entry_t current = port;
    for (NSUInteger depth = 0; depth < 64; depth++) {
        if (IOObjectConformsTo(current, "IOThunderboltSwitch")) {
            NSNumber *identifier = registryID(current);
            NSString *dock = identifier ? dockLabels[identifier] : nil;
            IOObjectRelease(current);
            return dock;
        }
        io_registry_entry_t parent = IO_OBJECT_NULL;
        kern_return_t status = IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent);
        IOObjectRelease(current);
        if (status != KERN_SUCCESS) return nil;
        current = parent;
    }
    IOObjectRelease(current);
    return nil;
}

static NSString *hostModel(void) {
    char value[128] = {0};
    size_t size = sizeof value;
    return sysctlbyname("hw.model", value, &size, NULL, 0) == 0 ? @(value) : @"unknown";
}

static NSDictionary *snapshot(void) {
    NSMutableArray *errors = [NSMutableArray array];
    NSMutableArray *docks = [NSMutableArray array];
    NSMutableDictionary *dockLabels = [NSMutableDictionary dictionary];
    eachService(@"IOThunderboltSwitch", errors, ^(io_service_t service) {
        NSNumber *vendor = number(property(service, @"Device Vendor ID"));
        NSNumber *model = number(property(service, @"Device Model ID"));
        if (vendor.unsignedIntValue != 0x003d || model.unsignedIntValue != 0x0011) return;
        NSNumber *identifier = registryID(service);
        if (!identifier) {
            [errors addObject:@{@"class": @"IOThunderboltSwitch", @"status": @"dock disappeared during snapshot"}];
            return;
        }
        NSString *label = [NSString stringWithFormat:@"dock%lu", (unsigned long)docks.count + 1];
        dockLabels[identifier] = label;
        [docks addObject:@{@"id": label, @"name": @"TS3 Plus", @"vendor": @"CalDigit, Inc.",
            @"vendorID": vendor, @"modelID": model, @"class": registryClass(service)}];
    });

    NSMutableArray *controllers = [NSMutableArray array];
    NSMutableDictionary *controllerLabels = [NSMutableDictionary dictionary];
    eachService(@"AppleUSBHostController", errors, ^(io_service_t service) {
        NSString *dock = dockForController(service, dockLabels);
        if (!dock) return;
        NSNumber *identifier = registryID(service);
        if (!identifier) {
            [errors addObject:@{@"class": @"AppleUSBHostController", @"status": @"controller disappeared during snapshot"}];
            return;
        }
        NSString *label = [NSString stringWithFormat:@"controller%lu", (unsigned long)controllers.count + 1];
        NSDictionary *reference = @{@"id": label, @"dock": dock};
        controllerLabels[identifier] = reference;
        NSMutableDictionary *entry = [reference mutableCopy];
        entry[@"class"] = registryClass(service);
        NSNumber *vendor = number(nearestProperty(service, @"vendor-id"));
        NSNumber *device = number(nearestProperty(service, @"device-id"));
        if (vendor) entry[@"pciVendorID"] = vendor;
        if (device) entry[@"pciDeviceID"] = device;
        [controllers addObject:entry];
    });

    NSMutableArray *devices = [NSMutableArray array];
    eachService(@"IOUSBHostDevice", errors, ^(io_service_t service) {
        NSDictionary *controller = nearestMappedAncestor(service, controllerLabels);
        if (!controller) return;
        NSMutableDictionary *entry = [@{@"dock": controller[@"dock"],
            @"controller": controller[@"id"], @"class": registryClass(service)} mutableCopy];
        entry[@"name"] = string(property(service, @"USB Product Name")) ?: registryName(service);
        NSDictionary *keys = @{@"idVendor": @"vendorID", @"idProduct": @"productID",
            @"bDeviceClass": @"deviceClass", @"Device Speed": @"speedCode"};
        for (NSString *key in keys) {
            NSNumber *value = number(property(service, key));
            if (value) entry[keys[key]] = value;
        }
        [devices addObject:entry];
    });

    NSMutableArray *ports = [NSMutableArray array];
    for (NSString *className in @[@"AppleUSB20XHCIPort", @"AppleUSB30XHCIPort"]) {
        eachService(className, errors, ^(io_service_t service) {
            NSDictionary *controller = nearestMappedAncestor(service, controllerLabels);
            if (!controller) return;
            NSMutableDictionary *entry = [@{@"dock": controller[@"dock"],
                @"controller": controller[@"id"], @"class": registryClass(service),
                @"registryPort": registryName(service)} mutableCopy];
            NSNumber *status = number(property(service, @"port-status"));
            if (status) entry[@"statusRaw"] = status;
            NSNumber *linkErrors = number(property(service, @"link-error-count"));
            if (linkErrors) entry[@"linkErrors"] = linkErrors;
            id statistics = property(service, @"port-statistics");
            if ([statistics isKindOfClass:NSDictionary.class]) {
                NSDictionary *keys = @{@"kPortStatConnectCount": @"connectCount",
                    @"kPortStatAddressFailureCount": @"addressFailures",
                    @"kPortStatEnumerationFailureCount": @"enumerationFailures",
                    @"kPortStatOverCurrentCount": @"overCurrentEvents"};
                for (NSString *key in keys) {
                    NSNumber *value = number(statistics[key]);
                    if (value) entry[keys[key]] = value;
                }
            }
            [ports addObject:entry];
        });
    }

    NSMutableArray *transports = [NSMutableArray array];
    eachService(@"IOPortTransportStateCIO", errors, ^(io_service_t service) {
        id metadata = property(service, @"Metadata");
        if (![metadata isKindOfClass:NSDictionary.class]) return;
        if ([number(metadata[@"Device Vendor ID"]) unsignedIntValue] != 0x003d ||
            [number(metadata[@"Device Model ID"]) unsignedIntValue] != 0x0011) return;
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        for (NSString *key in @[@"Active", @"PortNumber", @"CableSpeed", @"CableGeneration"])
            if (number(property(service, key))) entry[key] = number(property(service, key));
        for (NSString *key in @[@"DriverStatusDescription", @"AuthorizationStatusDescription",
                               @"TransportDescription"])
            if (string(property(service, key))) entry[key] = string(property(service, key));
        [transports addObject:entry];
    });

    NSMutableDictionary *result = [@{
        @"schemaVersion": @1,
        @"generatedAt": [[NSISO8601DateFormatter new] stringFromDate:NSDate.date],
        @"host": @{@"model": hostModel(), @"os": NSProcessInfo.processInfo.operatingSystemVersionString},
        @"mode": @"read_only_registry_snapshot",
        @"docks": docks, @"controllers": controllers, @"devices": devices, @"ports": ports,
        @"directDockTransports": transports, @"errors": errors,
        @"notes": @[@"Port counters are cumulative; empty or suspended ports are not diagnosed as failed.",
                     @"Registry port names are not mapped to front/rear physical sockets.",
                     @"A dock's built-in USB devices can enumerate even when a keyboard or mouse does not work."]
    } mutableCopy];
    result[@"assessment"] = DockAssessment(result);
    return result;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        BOOL json = argc == 2 && strcmp(argv[1], "--json") == 0;
        if (argc > 1 && !json) {
            BOOL help = argc == 2 && (!strcmp(argv[1], "--help") || !strcmp(argv[1], "-h"));
            fprintf(help ? stdout : stderr, "Usage: dock-status [--json]\nRead-only TS3 Plus and USB enumeration snapshot.\n");
            return help ? 0 : 2;
        }
        NSDictionary *report = snapshot();
        if (json) {
            NSError *error = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:report
                options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:&error];
            if (!data) { fprintf(stderr, "Cannot encode dock status: %s\n", error.localizedDescription.UTF8String); return 1; }
            fwrite(data.bytes, 1, data.length, stdout);
            fputc('\n', stdout);
        } else {
            fputs(DockSummary(report).UTF8String, stdout);
        }
        return [report[@"errors"] count] ? 1 : 0;
    }
}
