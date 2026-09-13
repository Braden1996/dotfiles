// Hardware-free tests. Every IOKit lookup/access used by Controller.m is mocked.
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#include <assert.h>
#include <dlfcn.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>

static unsigned toggles=0,nextIterator=100,cursors[512],iteratorKind[512];
static BOOL wrongIdentity=NO,wrongController=NO,failRestore=NO,disconnected=NO;
static double elapsed=0;static volatile sig_atomic_t deliveredSignal=0;
static CFMutableDictionaryRef testMatching(const char *name){return (__bridge_retained CFMutableDictionaryRef)[@{@"class":@(name)} mutableCopy];}
static kern_return_t testServices(mach_port_t p,CFDictionaryRef d,io_iterator_t *it){
    (void)p;NSString *name=((__bridge NSDictionary*)d)[@"class"];unsigned i=nextIterator++;assert(i<512);cursors[i]=0;iteratorKind[i]=[name isEqualToString:@"DCPAVServiceProxy"]?1:2;*it=i;CFRelease(d);return KERN_SUCCESS;
}
static io_object_t testNext(io_iterator_t it){return cursors[it]++?0:(iteratorKind[it]==1?10:20);}
static kern_return_t testRelease(io_object_t x){(void)x;return KERN_SUCCESS;}
static kern_return_t testParent(io_registry_entry_t x,const io_name_t p,io_registry_entry_t *out){(void)p;*out=x==10?11:21;return KERN_SUCCESS;}
static kern_return_t testName(io_registry_entry_t x,io_name_t out){strcpy(out,x==11?"dispext1:dcpav-service-epic:0":"dispext1:dcpav-controller-epic:0");return KERN_SUCCESS;}
static kern_return_t testRID(io_registry_entry_t x,uint64_t *out){*out=x==10?1234:4321;return KERN_SUCCESS;}
static CFTypeRef testProperty(io_registry_entry_t x,CFStringRef key,CFAllocatorRef a,IOOptionBits o){(void)x;(void)a;(void)o;return CFEqual(key,CFSTR("Location"))?CFRetain(CFSTR("External")):NULL;}
static CFTypeRef testCreate(CFAllocatorRef a,io_service_t s){(void)a;return CFRetain(s==10?kCFBooleanTrue:kCFBooleanFalse);}
static IOReturn testCopy(CFTypeRef av,CFDataRef *out){(void)av;uint8_t b[128]={0};b[8]=6;b[9]=wrongIdentity?0x11:0x10;b[10]=0x42;b[11]=0xae;*out=CFDataCreate(kCFAllocatorDefault,b,128);return KERN_SUCCESS;}
static uint32_t testLocation(CFTypeRef x){(void)x;return wrongController?1:0;}
static IOReturn testToggle(CFTypeRef x){(void)x;toggles++;disconnected=!disconnected;return failRestore&&toggles==2?kIOReturnError:KERN_SUCCESS;}
static void *testOpen(const char*p,int flags){(void)p;(void)flags;return(void*)1;}
static int testClose(void*p){(void)p;return 0;}
static void *testSymbol(void*h,const char*n){(void)h;
    if(!strcmp(n,"IOAVServiceCreateWithService")||!strcmp(n,"IOAVControllerCreateWithService"))return(void*)testCreate;
    if(!strcmp(n,"IOAVServiceCopyEDID"))return(void*)testCopy;
    if(!strcmp(n,"IOAVControllerGetLocation"))return(void*)testLocation;
    if(!strcmp(n,"IOAVControllerForceHotPlugDetect"))return(void*)testToggle;
    return NULL;
}
static int testClock(clockid_t c,struct timespec*t){(void)c;t->tv_sec=(time_t)elapsed;t->tv_nsec=(long)((elapsed-t->tv_sec)*1e9);return 0;}
static int testSleep(useconds_t t){elapsed+=t/1e6;return 0;}
#define IOServiceMatching testMatching
#define IOServiceGetMatchingServices testServices
#define IOIteratorNext testNext
#define IOObjectRelease testRelease
#define IORegistryEntryGetParentEntry testParent
#define IORegistryEntryGetName testName
#define IORegistryEntryGetRegistryEntryID testRID
#define IORegistryEntryCreateCFProperty testProperty
#define dlopen testOpen
#define dlsym testSymbol
#define dlclose testClose
#define clock_gettime testClock
#define usleep testSleep
// The engine include directory is supplied by the test runner. Include the
// implementation after defining mocks; never link a second live Controller.m.
#include <Controller.m>
static void reset(void){toggles=0;nextIterator=100;wrongIdentity=wrongController=failRestore=disconnected=NO;elapsed=0;deliveredSignal=0;}
static void priorHandler(int signo){deliveredSignal=signo;}
int main(void){@autoreleasepool{
    NSError *error=nil;
    reset();assert(PulseXDR(1234,^{assert(disconnected);return YES;},&error));assert(toggles==2&&!disconnected&&elapsed==.25);
    restorePending();assert(toggles==2);
    reset();assert(PulseXDR(1234,nil,&error));assert(toggles==2&&!disconnected&&elapsed<=2.001);
    reset();assert(!PulseXDR(1234,^{return NO;},&error));assert(toggles==2&&!disconnected&&elapsed<=2.001);
    reset();assert(!PulseXDR(1234,^BOOL{[NSException raise:@"CallbackFailure" format:@"test"];return NO;},&error));assert(toggles==2&&!disconnected);
    reset();assert(PulseXDR(1234,^{assert(!PulseXDR(1234,nil,NULL));return YES;},&error));assert(toggles==2&&!disconnected);
    reset();wrongIdentity=YES;assert(!PulseXDR(1234,nil,&error));assert(toggles==0);
    reset();wrongController=YES;assert(!PulseXDR(1234,nil,&error));assert(toggles==0);
    reset();assert(!PulseXDR(9999,nil,&error));assert(toggles==0);
    reset();assert(!PulseXDR(0,nil,&error));assert(toggles==0);
    reset();failRestore=YES;assert(!PulseXDR(1234,nil,&error));assert(toggles==2);restorePending();assert(toggles==2);
    reset();struct sigaction action={0},old={0};action.sa_handler=priorHandler;sigemptyset(&action.sa_mask);assert(sigaction(SIGTERM,&action,&old)==0);
    assert(!PulseXDR(1234,^{raise(SIGTERM);return NO;},&error));assert(toggles==2&&!disconnected&&deliveredSignal==SIGTERM);sigaction(SIGTERM,&old,NULL);
    reset();assert(!PulseXDR(9999,nil,&error));assert(toggles==0&&deliveredSignal==0);
    puts("Controller tests passed without hardware access: target refusal, exactly two toggles, callback timeout/exception, nested pulse rejection, signal cleanup, reconnect failure and cleanup idempotence.");
    return 0;
}}
