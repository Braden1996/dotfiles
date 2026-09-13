// Automatic native display allocation for the personal MacBook Pro M5 (Mac17,2).
// No kernel extension, firmware write, root privilege, network or screen capture.
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <IOKit/IOKitLib.h>
#import "EDID.h"
#import "XDR.h"
#import "Controller.h"
#import "PolicyGuard.h"
#include <dlfcn.h>
#include <sys/sysctl.h>
#include <sys/file.h>
#include <signal.h>
#include <os/log.h>

typedef CFTypeRef AVRef;
typedef AVRef (*CreateFn)(CFAllocatorRef, io_service_t);
typedef IOReturn (*CopyFn)(AVRef, CFDataRef *);
typedef IOReturn (*SetFn)(AVRef, uint32_t, CFDataRef);
static CreateFn avCreate;
static CopyFn avCopy;
static SetFn avSet;
static BOOL watching=NO;
static NSUInteger generation=0;
static NSString *lastReport;
static IONotificationPortRef notificationPort;
static NSMutableDictionary<NSNumber *,NSNumber *> *avInterests;
static DisplayPolicyGuard *policyGuard;
static NSMutableDictionary<NSString *,NSString *> *refreshReports;

static void report(NSString *message) {
    if([message isEqualToString:lastReport])return;
    lastReport=message;
    static os_log_t logger;static dispatch_once_t once;
    dispatch_once(&once,^{logger=os_log_create("com.braden.displays","allocation");});
    os_log_with_type(logger,OS_LOG_TYPE_DEFAULT,"%{public}s",message.UTF8String);
    fprintf(stderr,"%s %s\n",[NSDate.date.description UTF8String],message.UTF8String);
    fflush(stderr);
}
static NSString *model(void) {
    char value[128]={0};size_t n=sizeof value;
    return sysctlbyname("hw.model",value,&n,NULL,0)==0 ? @(value) : @"unknown";
}
static BOOL loadAPI(void) {
    void *h=dlopen("/System/Library/Frameworks/IOKit.framework/IOKit",RTLD_NOW);
    if(!h)return NO;
    avCreate=(CreateFn)dlsym(h,"IOAVServiceCreateWithService");
    avCopy=(CopyFn)dlsym(h,"IOAVServiceCopyEDID");
    avSet=(SetFn)dlsym(h,"IOAVServiceSetVirtualEDIDMode");
    return avCreate&&avCopy&&avSet;
}

@interface Monitor:NSObject
@property(nonatomic,assign) AVRef service;
@property(nonatomic,strong) NSData *edid;
@property(nonatomic) uint64_t registryID;
@end
@implementation Monitor
- (void)dealloc {if(_service)CFRelease(_service);}
@end

static NSString *identity(unsigned vendor,unsigned product) {
    if(vendor==1715&&product==43575)return @"asus";
    if(vendor==1552&&product==44610)return @"xdr";
    return nil;
}
static NSDictionary<NSString *,Monitor *> *monitors(void) {
    NSMutableDictionary *found=[NSMutableDictionary dictionary];
    NSMutableSet *duplicates=[NSMutableSet set];
    io_iterator_t it=0;
    if(IOServiceGetMatchingServices(kIOMainPortDefault,IOServiceMatching("DCPAVServiceProxy"),&it))return found;
    io_service_t s;
    while((s=IOIteratorNext(it))) {
        CFTypeRef loc=IORegistryEntryCreateCFProperty(s,CFSTR("Location"),kCFAllocatorDefault,0);
        if(loc&&CFEqual(loc,CFSTR("External"))) {
            AVRef av=avCreate(kCFAllocatorDefault,s);CFDataRef data=NULL;
            if(av&&avCopy(av,&data)==0&&data&&CFDataGetLength(data)>=128) {
                const UInt8 *p=CFDataGetBytePtr(data);
                NSString *key=identity((p[8]<<8)|p[9],p[10]|(p[11]<<8));
                if(key) {
                    if(found[key])[duplicates addObject:key];
                    Monitor *m=[Monitor new];m.service=CFRetain(av);m.edid=[(__bridge NSData *)data copy];
                    uint64_t registry=0;IORegistryEntryGetRegistryEntryID(s,&registry);m.registryID=registry;
                    found[key]=m;
                }
            }
            if(data)CFRelease(data);if(av)CFRelease(av);
        }
        if(loc)CFRelease(loc);IOObjectRelease(s);
    }
    IOObjectRelease(it);
    for(NSString *key in duplicates)[found removeObjectForKey:key];
    return found;
}

static NSArray<NSDictionary *> *connections(void) {
    io_service_t s=IOServiceGetMatchingService(kIOMainPortDefault,IOServiceMatching("AppleDisplayConnectionManager"));
    if(!s)return nil;
    CFTypeRef p=IORegistryEntryCreateCFProperty(s,CFSTR("ConnectionMapping"),kCFAllocatorDefault,0);
    IOObjectRelease(s);
    id result=CFBridgingRelease(p);
    return [result isKindOfClass:NSArray.class]?result:nil;
}
static NSString *connectionIdentity(NSDictionary *d) {
    // ConnectionMapping's product bytes are reversed relative to the EDID/CG API.
    unsigned p=[d[@"ProductID"] unsignedIntValue];
    if(p==14250&&[d[@"ProductName"] isEqualToString:@"PG27UCWM"])return @"asus";
    if(p==17070&&[d[@"MaxW"] intValue]==5120&&[d[@"MaxH"] intValue]==2880)return @"xdr";
    return @"other";
}
static NSArray<NSDictionary *> *onlineDisplays(void) {
    CGDirectDisplayID ids[32];uint32_t count=0;
    if(CGGetOnlineDisplayList(32,ids,&count)!=kCGErrorSuccess)return @[];
    NSMutableArray *out=[NSMutableArray array];
    for(unsigned i=0;i<count;i++) {
        CGDirectDisplayID display=ids[i];
        CGDisplayModeRef mode=CGDisplayCopyDisplayMode(display);
        NSMutableDictionary *item=[@{@"id":@(display),@"active":@(CGDisplayIsActive(display)!=0),
            @"builtIn":@(CGDisplayIsBuiltin(display)!=0),
            @"kind":identity(CGDisplayVendorNumber(display),CGDisplayModelNumber(display))?:@"other"} mutableCopy];
        if(mode) {
            item[@"logicalWidth"]=@(CGDisplayModeGetWidth(mode));item[@"logicalHeight"]=@(CGDisplayModeGetHeight(mode));
            item[@"pixelWidth"]=@(CGDisplayModeGetPixelWidth(mode));item[@"pixelHeight"]=@(CGDisplayModeGetPixelHeight(mode));
            item[@"refreshHz"]=@(CGDisplayModeGetRefreshRate(mode));
            CFRelease(mode);
        }
        [out addObject:item];
    }
    return out;
}
static BOOL sameGeometry(CGDisplayModeRef a,CGDisplayModeRef b) {
    return CGDisplayModeGetWidth(a)==CGDisplayModeGetWidth(b)&&CGDisplayModeGetHeight(a)==CGDisplayModeGetHeight(b)&&
        CGDisplayModeGetPixelWidth(a)==CGDisplayModeGetPixelWidth(b)&&CGDisplayModeGetPixelHeight(a)==CGDisplayModeGetPixelHeight(b);
}
// The optional selected mode is retained for the caller. This function only reads.
static NSDictionary *refreshInfo(CGDirectDisplayID display,double target,CGDisplayModeRef *selected) {
    if(selected)*selected=NULL;
    CGDisplayModeRef current=CGDisplayCopyDisplayMode(display);
    if(!current)return @{@"desiredRefreshHz":@(target),@"targetModeAvailable":@NO,@"error":@"Current display mode unavailable"};
    NSMutableSet<NSNumber *> *rates=[NSMutableSet set];BOOL available=NO;
    CFArrayRef modes=CGDisplayCopyAllDisplayModes(display,(__bridge CFDictionaryRef)@{(__bridge NSString *)kCGDisplayShowDuplicateLowResolutionModes:@YES});
    if(modes)for(CFIndex i=0;i<CFArrayGetCount(modes);i++) {
        CGDisplayModeRef m=(CGDisplayModeRef)CFArrayGetValueAtIndex(modes,i);
        if(!sameGeometry(m,current))continue;
        double hz=CGDisplayModeGetRefreshRate(m);
        [rates addObject:@(round(hz*1000)/1000)];
        if(fabs(hz-target)<0.1) {
            available=YES;
            if(selected&&!*selected)*selected=CGDisplayModeRetain(m);
        }
    }
    NSArray *sorted=[rates.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSDictionary *info=@{@"desiredRefreshHz":@(target),@"targetModeAvailable":@(available),
        @"availableRefreshHzAtCurrentGeometry":sorted,@"maxAvailableRefreshHzAtCurrentGeometry":sorted.lastObject?:NSNull.null,
        @"currentRefreshHz":@(CGDisplayModeGetRefreshRate(current)),
        @"currentLogicalWidth":@(CGDisplayModeGetWidth(current)),@"currentLogicalHeight":@(CGDisplayModeGetHeight(current)),
        @"currentPixelWidth":@(CGDisplayModeGetPixelWidth(current)),@"currentPixelHeight":@(CGDisplayModeGetPixelHeight(current))};
    if(modes)CFRelease(modes);CFRelease(current);return info;
}
static NSDictionary *status(void) {
    NSMutableArray *physical=[NSMutableArray array];
    for(NSDictionary *d in connections()) {
        [physical addObject:@{@"kind":connectionIdentity(d),@"pipes":d[@"PipeIDs"]?:@[],
            @"maxPipes":d[@"MaxPipes"]?:@0,@"address":d[@"Address"]?:@""}];
    }
    NSMutableDictionary *edids=[NSMutableDictionary dictionary];
    [monitors() enumerateKeysAndObjectsUsingBlock:^(NSString *key,Monitor *m,BOOL *stop){
        BOOL asus=[key isEqualToString:@"asus"];
        BOOL valid=asus?ASUSValidateEDID(m.edid,NULL):XDRValidateEDID(m.edid,NULL);
        edids[key]=@{@"bytes":@(m.edid.length),@"valid":@(valid),
            @"highRefresh":@(valid&&(asus?ASUSHasHighRefreshTiming(m.edid):XDRHasHighRefreshTiming(m.edid)))};
    }];
    NSSet *present=[NSSet setWithArray:[physical valueForKey:@"kind"]];
    NSArray *online=onlineDisplays();NSMutableArray *refresh=[NSMutableArray array];
    for(NSDictionary *display in online) {
        NSString *kind=display[@"kind"];double target=0;
        if([kind isEqualToString:@"asus"])target=[present containsObject:@"xdr"]?144:240;
        if([kind isEqualToString:@"xdr"])target=[present containsObject:@"asus"]?60:120;
        if(!target)continue;
        NSMutableDictionary *info=[refreshInfo([display[@"id"] unsignedIntValue],target,NULL) mutableCopy];
        info[@"id"]=display[@"id"];info[@"kind"]=kind;
        info[@"policyBlockedByOtherMonitor"]=@([present containsObject:@"other"]);
        [refresh addObject:info];
    }
    return @{@"model":model(),@"supported":@([model() isEqualToString:@"Mac17,2"]),
        @"physical":physical,@"online":online,@"edid":edids,@"refreshPolicy":refresh};
}
static void schedule(void);
static BOOL allowAttempt(NSString *key) {
    return [policyGuard allowAction:key at:NSProcessInfo.processInfo.systemUptime];
}
static BOOL changeEDID(NSString *key,Monitor *m,NSData *replacement) {
    NSString *operation=[NSString stringWithFormat:@"%@-%@",key,replacement?@"cap":@"reset"];
    if(!allowAttempt(operation))return NO;
    IOReturn r=avSet(m.service,replacement?1:0,replacement?(__bridge CFDataRef)replacement:NULL);
    [policyGuard didAttemptMutationAt:NSProcessInfo.processInfo.systemUptime];
    report([NSString stringWithFormat:@"%@ %@ EDID: 0x%x",key,replacement?@"limit":@"restore factory",r]);
    if(!r) {
        // Accepted but ineffective private APIs consume the finite action budget too.
        if(watching)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),dispatch_get_main_queue(),^{schedule();});
    }
    return r==0;
}
typedef NS_ENUM(NSInteger,DisplayRefreshResult) {
    DisplayRefreshInactive,
    DisplayRefreshAlreadyDesired,
    DisplayRefreshTargetUnavailable,
    DisplayRefreshDeferred,
    DisplayRefreshRequestAccepted,
    DisplayRefreshRequestFailed
};
static DisplayRefreshResult setRefresh(NSDictionary *display,double target) {
    CGDirectDisplayID id=[display[@"id"] unsignedIntValue];
    NSString *kind=display[@"kind"];
    if(CGDisplayIsBuiltin(id)||!CGDisplayIsActive(id))return DisplayRefreshInactive;
    CGDisplayModeRef best=NULL;
    NSDictionary *info=refreshInfo(id,target,&best);
    if(!info[@"error"]&&fabs([info[@"currentRefreshHz"] doubleValue]-target)<0.1) {
        [refreshReports removeObjectForKey:kind];if(best)CFRelease(best);return DisplayRefreshAlreadyDesired;
    }
    if(!best) {
        NSString *message=[NSString stringWithFormat:@"%@ target %.0f Hz unavailable at the current geometry; available rates: %@%@",
            kind,target,info[@"availableRefreshHzAtCurrentGeometry"]?:@[],info[@"error"]?[@"; " stringByAppendingString:info[@"error"]]:@""];
        if(![refreshReports[kind] isEqualToString:message]) {
            refreshReports[kind]=message;report(message);
        }
        return DisplayRefreshTargetUnavailable;
    }
    [refreshReports removeObjectForKey:kind];
    NSString *key=[NSString stringWithFormat:@"mode-%@-%.0f",kind,target];
    if(!allowAttempt(key)) {CFRelease(best);return DisplayRefreshDeferred;}
    CGDisplayConfigRef config=NULL;CGError r=CGBeginDisplayConfiguration(&config);
    if(!r) {
        r=CGConfigureDisplayWithDisplayMode(config,id,best,NULL);
        if(!r)r=CGCompleteDisplayConfiguration(config,kCGConfigureForSession);
        else CGCancelDisplayConfiguration(config);
    }
    [policyGuard didAttemptMutationAt:NSProcessInfo.processInfo.systemUptime];
    report([NSString stringWithFormat:@"%@ %.0f Hz request: %d",kind,target,r]);
    CFRelease(best);return r==0?DisplayRefreshRequestAccepted:DisplayRefreshRequestFailed;
}

static BOOL recoverXDR(Monitor *xdr,BOOL prepareASUS) {
    if(!allowAttempt(prepareASUS?@"reconnect-xdr-pair":@"reconnect-xdr-solo"))return NO;
    NSError *error=nil;
    BOOL (^middle)(void)=nil;
    if(prepareASUS)middle=^BOOL{
        Monitor *asus=monitors()[@"asus"];
        if(!asus)return NO;
        NSError *edidError=nil;
        NSData *cap=ASUSCreateSinglePipeEDID(asus.edid,&edidError);
        if(!cap)return NO;
        if([cap isEqualToData:asus.edid])return YES;
        // This write is part of one bounded paired transaction. The reconnect
        // always runs, even if the newly available ASUS fails validation/setup.
        IOReturn r=avSet(asus.service,1,(__bridge CFDataRef)cap);
        report([NSString stringWithFormat:@"ASUS capability limit during reconnect: 0x%x",r]);
        return r==0;
    };
    BOOL ok=PulseXDR(xdr.registryID,middle,&error);
    [policyGuard didAttemptMutationAt:NSProcessInfo.processInfo.systemUptime];
    report(ok?@"Completed paired XDR reconnect; verifying display allocation":
        [@"XDR reconnect: " stringByAppendingString:error.localizedDescription?:@"failed"]);
    if(watching)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC),dispatch_get_main_queue(),^{schedule();});
    return YES;
}

static void reconcile(void) { @autoreleasepool {
    NSArray *mapping=connections();if(!mapping)return;
    // Pipe count, registry IDs, and CG IDs change during reallocation. Only physical
    // monitor identity and connection address determine a new attachment topology.
    NSMutableArray *tokens=[NSMutableArray array];
    for(NSDictionary *d in mapping)
        [tokens addObject:[NSString stringWithFormat:@"%@:%@",connectionIdentity(d),d[@"Address"]?:@""]];
    [tokens sortUsingSelector:@selector(compare:)];
    NSString *fingerprint=[tokens componentsJoinedByString:@"|"];
    if(![policyGuard observeTopology:fingerprint at:NSProcessInfo.processInfo.systemUptime]) {schedule();return;}
    NSMutableSet *present=[NSMutableSet set];
    for(NSDictionary *d in mapping)[present addObject:connectionIdentity(d)];
    if([present containsObject:@"other"]) {report(@"An additional monitor is attached; leaving configuration to macOS");return;}
    BOOL asus=[present containsObject:@"asus"],xdr=[present containsObject:@"xdr"];
    NSDictionary *av=monitors();Monitor *a=av[@"asus"],*x=av[@"xdr"];
    NSError *error=nil;
    if(asus&&xdr) {
        if(a) {
            NSData *cap=ASUSCreateSinglePipeEDID(a.edid,&error);
            if(!cap) {report([@"ASUS EDID not recognized: " stringByAppendingString:error.localizedDescription]);return;}
            if(![cap isEqualToData:a.edid]) {changeEDID(@"asus",a,cap);return;}
        } else if(x&&XDRValidateEDID(x.edid,NULL)) {
            // The XDR may own both pipes if it was attached first. A paired
            // software unplug/replug lets ASUS negotiate its single-pipe cap.
            recoverXDR(x,YES);return;
        }
    } else {
        if(asus&&a&&ASUSValidateEDID(a.edid,NULL)&&!ASUSHasHighRefreshTiming(a.edid)) {changeEDID(@"asus",a,nil);return;}
        if(xdr&&x&&XDRValidateEDID(x.edid,NULL)&&!XDRHasHighRefreshTiming(x.edid)) {changeEDID(@"xdr",x,nil);return;}
    }
    for(NSDictionary *d in onlineDisplays()) {
        NSString *kind=d[@"kind"];
        if([kind isEqualToString:@"asus"]&&asus) {
            DisplayRefreshResult r=setRefresh(d,xdr?144:240);
            if(r==DisplayRefreshTargetUnavailable&&!xdr&&a&&ASUSValidateEDID(a.edid,NULL)) {
                // A factory EDID reset also renegotiates an allocation retained
                // from a previously connected second screen.
                changeEDID(@"asus",a,nil);return;
            }
        }
        if([kind isEqualToString:@"xdr"]&&xdr) {
            DisplayRefreshResult r=setRefresh(d,asus?60:120);
            if(r==DisplayRefreshTargetUnavailable&&!asus&&x&&XDRValidateEDID(x.edid,NULL)) {
                for(NSDictionary *connection in mapping) {
                    if([connectionIdentity(connection) isEqualToString:@"xdr"]&&
                       [connection[@"PipeIDs"] count]<2&&[connection[@"MaxPipes"] intValue]==2) {
                        recoverXDR(x,NO);return;
                    }
                }
            }
        }
    }
}}
static void schedule(void) {
    if(!watching)return;
    NSUInteger token=++generation;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{if(token==generation)reconcile();});
}
static void displayEvent(CGDirectDisplayID id,CGDisplayChangeSummaryFlags flags,void *context) {
    if(!(flags&kCGDisplayBeginConfigurationFlag))dispatch_async(dispatch_get_main_queue(),^{schedule();});
}
static void interest(void *context,io_service_t service,natural_t type,void *argument) {schedule();}
static void matched(void *context,io_iterator_t iterator) {
    io_object_t s;
    while((s=IOIteratorNext(iterator))) {
        if(context) {
            uint64_t registry=0;IORegistryEntryGetRegistryEntryID(s,&registry);
            NSNumber *key=@(registry),*old=avInterests[key];
            if(old){IOObjectRelease(old.unsignedIntValue);[avInterests removeObjectForKey:key];}
            if((uintptr_t)context==1) {
                io_object_t note=0;
                if(!IOServiceAddInterestNotification(notificationPort,s,kIOGeneralInterest,interest,NULL,&note))avInterests[key]=@(note);
            }
        }
        IOObjectRelease(s);
    }
    schedule();
}

int main(int argc,const char **argv) { @autoreleasepool {
    NSString *command=argc==2?@(argv[1]):@"";
    if(![@[@"run",@"status",@"reconcile",@"restore"] containsObject:command]) {
        fprintf(stderr,"Usage: braden-displays run|status|reconcile|restore\n");return 2;
    }
    if(![model() isEqualToString:@"Mac17,2"]) {printf("Unsupported model %s; no display changes\n",model().UTF8String);return 0;}
    if(!loadAPI()) {report(@"Required macOS display APIs unavailable; no changes");return [command isEqualToString:@"run"]?0:1;}
    policyGuard=[DisplayPolicyGuard new];
    refreshReports=[NSMutableDictionary dictionary];
    if([command isEqualToString:@"status"]) {
        NSData *json=[NSJSONSerialization dataWithJSONObject:status() options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:NULL];
        fwrite(json.bytes,1,json.length,stdout);puts("");return 0;
    }
    // All mutation entry points share this lock; a manual command must not fight
    // the live watcher or have its requested restore immediately re-capped.
    NSString *lockPath=[NSTemporaryDirectory() stringByAppendingPathComponent:@"com.braden.displays.lock"];
    int lock=open(lockPath.fileSystemRepresentation,O_CREAT|O_RDWR|O_NOFOLLOW,0600);
    if(lock<0||flock(lock,LOCK_EX|LOCK_NB)) {
        report(@"A display manager is already running or the lock is unavailable");
        return [command isEqualToString:@"run"]?0:1;
    }
    if([command isEqualToString:@"restore"]) {
        // Restore is an explicit one-shot request after the watcher is stopped.
        [policyGuard observeTopology:@"explicit-restore" at:0];
        [policyGuard observeTopology:@"explicit-restore" at:2];
        NSDictionary *av=monitors();Monitor *a=av[@"asus"],*x=av[@"xdr"];BOOL succeeded=YES;
        if(a&&!ASUSValidateEDID(a.edid,NULL)) {report(@"ASUS restore refused: unrecognized EDID");succeeded=NO;}
        if(x&&!XDRValidateEDID(x.edid,NULL)) {report(@"XDR restore refused: unrecognized EDID");succeeded=NO;}
        if(a&&ASUSValidateEDID(a.edid,NULL)&&!ASUSHasHighRefreshTiming(a.edid)) {
            if(!changeEDID(@"asus",a,nil))succeeded=NO;
            if(x&&XDRValidateEDID(x.edid,NULL)&&!XDRHasHighRefreshTiming(x.edid)) {
                usleep(3100000);x=monitors()[@"xdr"];
                if(!x||!XDRValidateEDID(x.edid,NULL)) {
                    report(@"XDR restore could not be verified after ASUS renegotiation");succeeded=NO;
                }
            }
        }
        if(x&&XDRValidateEDID(x.edid,NULL)&&!XDRHasHighRefreshTiming(x.edid))
            if(!changeEDID(@"xdr",x,nil))succeeded=NO;
        return succeeded?0:1;
    }
    if([command isEqualToString:@"reconcile"]) {
        reconcile();usleep(2100000);reconcile();return 0;
    }
    watching=YES;
    avInterests=[NSMutableDictionary dictionary];
    CGDisplayRegisterReconfigurationCallback(displayEvent,NULL);
    IONotificationPortRef port=IONotificationPortCreate(kIOMainPortDefault);
    notificationPort=port;
    if(port) {
        IONotificationPortSetDispatchQueue(port,dispatch_get_main_queue());
        for(NSString *cls in @[@"DCPAVServiceProxy",@"IOUSBHostDevice"]) {
            for(NSString *type in @[@kIOFirstMatchNotification,@kIOTerminatedNotification]) {
                io_iterator_t it=0;
                void *context=[cls isEqualToString:@"DCPAVServiceProxy"]?(void *)(uintptr_t)([type isEqualToString:@kIOFirstMatchNotification]?1:2):NULL;
                if(!IOServiceAddMatchingNotification(port,type.UTF8String,IOServiceMatching(cls.UTF8String),matched,context,&it))matched(context,it);
            }
        }
        io_service_t manager=IOServiceGetMatchingService(kIOMainPortDefault,IOServiceMatching("AppleDisplayConnectionManager"));
        if(manager) {io_object_t notification=0;IOServiceAddInterestNotification(port,manager,kIOGeneralInterest,interest,NULL,&notification);IOObjectRelease(manager);}
    }
    [NSWorkspace.sharedWorkspace.notificationCenter addObserverForName:NSWorkspaceDidWakeNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *n){
        [policyGuard didWakeAt:NSProcessInfo.processInfo.systemUptime];
        schedule();
    }];
    // A small in-process topology read catches suppressed HDMI attachments that produce no CG event.
    dispatch_source_t timer=dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_get_main_queue());
    dispatch_source_set_timer(timer,dispatch_time(DISPATCH_TIME_NOW,10*NSEC_PER_SEC),10*NSEC_PER_SEC,NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer,^{reconcile();});dispatch_resume(timer);
    report(@"Watching native displays on Mac17,2");schedule();
    [NSRunLoop.mainRunLoop run];
    return 0;
}}
