#import "XDR.h"
#include <assert.h>
static void fix(NSMutableData *d,unsigned b){uint8_t*p=(uint8_t*)d.mutableBytes+b*128;unsigned s=0;for(unsigned i=0;i<127;i++)s+=p[i];p[127]=(uint8_t)(0-s);}
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==3);NSData *src=[NSData dataWithContentsOfFile:@(argv[1])],*expected=[NSData dataWithContentsOfFile:@(argv[2])];NSError *err=nil;
    assert(XDRValidateEDID(src,&err));assert(XDRHasHighRefreshTiming(src));
    NSData *cap=XDRCreateSinglePipeEDID(src,&err);assert(cap&&[cap isEqualToData:expected]);assert(XDRValidateEDID(cap,&err));assert(!XDRHasHighRefreshTiming(cap));
    assert([XDRCreateSinglePipeEDID(cap,&err) isEqualToData:cap]);
    assert(memcmp((const uint8_t*)src.bytes+128,(const uint8_t*)cap.bytes+128,256)==0);
    const uint8_t *a=src.bytes,*b=cap.bytes;for(unsigned i=0;i<128;i++)if(!(i>=94&&i<=99)&&i!=126&&i!=127)assert(a[i]==b[i]);
    NSMutableData *bad=[src mutableCopy];((uint8_t*)bad.mutableBytes)[8]^=1;fix(bad,0);assert(!XDRValidateEDID(bad,&err));
    bad=[src mutableCopy];((uint8_t*)bad.mutableBytes)[80]^=1;assert(!XDRValidateEDID(bad,&err));
    bad=[src mutableCopy];((uint8_t*)bad.mutableBytes)[384+6]=2;fix(bad,3);assert(!XDRValidateEDID(bad,&err));
    bad=[src mutableCopy];((uint8_t*)bad.mutableBytes)[128+9]=5;fix(bad,1);assert(!XDRValidateEDID(bad,&err));
    assert(!XDRValidateEDID([NSData data],&err));assert(!XDRCreateSinglePipeEDID(bad,&err));
    puts("XDR tests passed: independent fixture parity, native5K60/tile retention, unchanged HDR/identity/topology, idempotence, identity/checksum/layout rejection.");
    return 0;
}}
