#import "Controller.h"
#import <IOKit/IOKitLib.h>
#include <dlfcn.h>
#include <pthread.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>

// On this OS, AppleATCDPINAdapterPort::forceHotPlugDetect inverts its HPD
// state. This must only be exposed as a paired operation. The current-kernel
// disassembly and paired live experiment are recorded in the task's work files.
typedef CFTypeRef AVRef;
typedef AVRef (*CreateFn)(CFAllocatorRef,io_service_t);
typedef IOReturn (*CopyFn)(AVRef,CFDataRef *);
typedef uint32_t (*LocationFn)(AVRef);
typedef IOReturn (*ToggleFn)(AVRef);
static pthread_mutex_t pulseLock=PTHREAD_MUTEX_INITIALIZER;
static pthread_once_t exitOnce=PTHREAD_ONCE_INIT;
static AVRef pendingController=NULL;
static ToggleFn pendingToggle=NULL;
static IOReturn restoreResult=kIOReturnSuccess;
static volatile sig_atomic_t interrupted=0;
static const int handledSignals[]={SIGINT,SIGTERM,SIGHUP};

static BOOL fail(NSError **error,NSString *message){
    if(error)*error=[NSError errorWithDomain:@"DisplayManager.Controller" code:1
                                  userInfo:@{NSLocalizedDescriptionKey:message}];
    return NO;
}
static double nowSeconds(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC_RAW,&t);return t.tv_sec+t.tv_nsec/1e9;}
static void onSignal(int signo){interrupted=signo;}
static void restorePending(void){
    // Atomically claim cleanup so a normal process exit cannot send a third
    // toggle after the ordinary finally path already restored the controller.
    AVRef controller=__sync_lock_test_and_set(&pendingController,NULL);
    if(controller){restoreResult=pendingToggle(controller);CFRelease(controller);}
}
static void installExitCleanup(void){atexit(restorePending);}
static NSString *endpoint(io_service_t service){
    io_service_t parent=0;if(IORegistryEntryGetParentEntry(service,kIOServicePlane,&parent)!=KERN_SUCCESS)return nil;
    io_name_t name={0};IOReturn r=IORegistryEntryGetName(parent,name);IOObjectRelease(parent);return r==KERN_SUCCESS?@(name):nil;
}
static BOOL external(io_service_t service){
    CFTypeRef p=IORegistryEntryCreateCFProperty(service,CFSTR("Location"),kCFAllocatorDefault,0);
    BOOL result=p&&CFGetTypeID(p)==CFStringGetTypeID()&&CFEqual(p,CFSTR("External"));if(p)CFRelease(p);return result;
}
static BOOL xdrIdentity(AVRef av,CopyFn copy){
    CFDataRef data=NULL;BOOL result=NO;
    if(av&&copy(av,&data)==KERN_SUCCESS&&data&&CFDataGetLength(data)>=128){
        const uint8_t*p=CFDataGetBytePtr(data);
        result=p[8]==0x06&&p[9]==0x10&&p[10]==0x42&&p[11]==0xae;
    }
    if(data)CFRelease(data);return result;
}
static BOOL targetStillPresent(uint64_t registryID,NSString *expectedEndpoint,CreateFn create,CopyFn copy){
    io_iterator_t it=0;io_service_t service;unsigned count=0;
    IOServiceGetMatchingServices(kIOMainPortDefault,IOServiceMatching("DCPAVServiceProxy"),&it);
    while((service=IOIteratorNext(it))){uint64_t rid=0;IORegistryEntryGetRegistryEntryID(service,&rid);
        if(rid==registryID&&external(service)&&[endpoint(service) isEqualToString:expectedEndpoint]){
            AVRef av=create(kCFAllocatorDefault,service);if(xdrIdentity(av,copy))count++;if(av)CFRelease(av);
        }IOObjectRelease(service);
    }IOObjectRelease(it);return count==1;
}

BOOL PulseXDR(uint64_t registryID,BOOL(^middle)(void),NSError **error){
    if(!registryID)return fail(error,@"Missing XDR registry identity");
    if(pthread_mutex_trylock(&pulseLock)!=0)return fail(error,@"An XDR pulse is already running");
    interrupted=0;restoreResult=kIOReturnSuccess;
    BOOL result=NO;AVRef controller=NULL;struct sigaction oldActions[3];unsigned installed=0;BOOL ready=middle==nil;
    void *library=dlopen("/System/Library/Frameworks/IOKit.framework/IOKit",RTLD_NOW);
    CreateFn createService=library?dlsym(library,"IOAVServiceCreateWithService"):NULL;
    CreateFn createController=library?dlsym(library,"IOAVControllerCreateWithService"):NULL;
    CopyFn copy=library?dlsym(library,"IOAVServiceCopyEDID"):NULL;
    LocationFn location=library?dlsym(library,"IOAVControllerGetLocation"):NULL;
    ToggleFn toggle=library?dlsym(library,"IOAVControllerForceHotPlugDetect"):NULL;
    @try{
        NSString *sourceEndpoint=nil,*marker=@":dcpav-service-epic:",*wanted=nil;
        if(!createService||!createController||!copy||!location||!toggle){fail(error,@"Required controller API unavailable");goto finish;}
        io_iterator_t it=0;io_service_t service;unsigned targets=0;
        IOServiceGetMatchingServices(kIOMainPortDefault,IOServiceMatching("DCPAVServiceProxy"),&it);
        while((service=IOIteratorNext(it))){uint64_t rid=0;IORegistryEntryGetRegistryEntryID(service,&rid);
            if(rid==registryID&&external(service)){
                AVRef av=createService(kCFAllocatorDefault,service);
                if(xdrIdentity(av,copy)){targets++;sourceEndpoint=endpoint(service);}if(av)CFRelease(av);
            }IOObjectRelease(service);
        }IOObjectRelease(it);
        if(targets!=1||![sourceEndpoint containsString:marker]){fail(error,@"Exact external XDR target unavailable");goto finish;}
        wanted=[sourceEndpoint stringByReplacingOccurrencesOfString:marker withString:@":dcpav-controller-epic:"];
        unsigned matches=0;IOServiceGetMatchingServices(kIOMainPortDefault,IOServiceMatching("DCPAVControllerProxy"),&it);
        while((service=IOIteratorNext(it))){
            if(external(service)&&[endpoint(service) isEqualToString:wanted]){matches++;if(!controller)controller=createController(kCFAllocatorDefault,service);}
            IOObjectRelease(service);
        }IOObjectRelease(it);
        if(matches!=1||!controller||location(controller)!=0){fail(error,@"Unique external controller for XDR DCP/unit unavailable");goto finish;}
        if(!targetStillPresent(registryID,sourceEndpoint,createService,copy)){fail(error,@"XDR topology changed before the pulse");goto finish;}
        interrupted=0;restoreResult=kIOReturnSuccess;pendingToggle=toggle;pthread_once(&exitOnce,installExitCleanup);
        struct sigaction action={0};action.sa_handler=onSignal;sigemptyset(&action.sa_mask);
        for(unsigned i=0;i<3;i++){
            if(sigaction(handledSignals[i],&action,&oldActions[i])!=0){fail(error,@"Unable to install pulse cleanup signal handler");goto finish;}
            installed++;
        }
        IOReturn first=toggle(controller);
        if(first!=KERN_SUCCESS){fail(error,[NSString stringWithFormat:@"First XDR toggle failed (0x%x)",first]);goto finish;}
        pendingController=CFRetain(controller);
        double deadline=nowSeconds()+2.0;
        // Let the asynchronous disconnect advance before asking whether the
        // other display is ready. No callback or delay runs beyond this deadline.
        do{
            double remaining=deadline-nowSeconds();if(remaining<=0||interrupted)break;
            usleep((useconds_t)(fmin(remaining,.25)*1000000));
            if(interrupted||nowSeconds()>=deadline)break;
            if(middle&&middle()){ready=YES;break;}
        }while(nowSeconds()<deadline);
        result=YES;
finish:;
    }@catch(NSException *exception){
        fail(error,[NSString stringWithFormat:@"XDR pulse callback failed: %@",exception.name]);result=NO;
    }@finally{
        // Retained controller remains callable while its AV service disappears.
        // Always pair a successful first toggle, including callback exceptions.
        restorePending();
        for(unsigned i=0;i<installed;i++)sigaction(handledSignals[i],&oldActions[i],NULL);
        if(controller)CFRelease(controller);
        if(library)dlclose(library);
        pthread_mutex_unlock(&pulseLock);
    }
    int caught=interrupted;
    if(restoreResult!=KERN_SUCCESS)return fail(error,[NSString stringWithFormat:@"XDR reconnect toggle failed (0x%x)",restoreResult]);
    if(caught){fail(error,@"XDR pulse interrupted after reconnect cleanup");raise(caught);return NO;}
    if(result&&!ready)return fail(error,@"XDR restored, but the other display was not ready within two seconds");
    return result;
}
