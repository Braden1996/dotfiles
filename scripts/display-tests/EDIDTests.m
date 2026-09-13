#import "EDID.h"
#include <assert.h>

static void fixSum(NSMutableData *d,unsigned block) {
    uint8_t *p=(uint8_t*)d.mutableBytes+block*128;unsigned sum=0;
    for(unsigned i=0;i<127;i++)sum+=p[i];p[127]=(uint8_t)(0-sum);
}
int main(int argc,char **argv) {@autoreleasepool {
    assert(argc==3);
    NSData *source=[NSData dataWithContentsOfFile:@(argv[1])];
    NSData *expected=[NSData dataWithContentsOfFile:@(argv[2])];
    assert(source&&expected);
    NSError *error=nil;
    assert(ASUSValidateEDID(source,&error));assert(ASUSHasHighRefreshTiming(source));
    NSData *cap=ASUSCreateSinglePipeEDID(source,&error);
    assert(cap&&[cap isEqualToData:expected]);assert(!ASUSHasHighRefreshTiming(cap));
    assert([ASUSCreateSinglePipeEDID(cap,&error) isEqualToData:cap]);
    const uint8_t *a=source.bytes,*b=cap.bytes;
    // Full source identity and base capabilities preserved except range/checksum.
    for(unsigned i=0;i<128;i++)if(i!=78&&i!=127)assert(a[i]==b[i]);
    // CTA substantive changes exactly the two refresh ceilings, plus checksum.
    unsigned changes=0;for(unsigned i=128;i<255;i++)if(a[i]!=b[i]){changes++;assert(a[i]==240&&b[i]==144);}
    assert(changes==2);
    NSMutableData *bad=[source mutableCopy];((uint8_t*)bad.mutableBytes)[8]^=1;fixSum(bad,0);
    assert(!ASUSValidateEDID(bad,&error));assert(!ASUSCreateSinglePipeEDID(bad,&error));
    bad=[source mutableCopy];((uint8_t*)bad.mutableBytes)[80]^=1;
    assert(!ASUSValidateEDID(bad,&error));
    bad=[source mutableCopy];((uint8_t*)bad.mutableBytes)[256+6]=2;fixSum(bad,2);
    assert(!ASUSValidateEDID(bad,&error));
    bad=[source mutableCopy];((uint8_t*)bad.mutableBytes)[128+7]=0x5f;fixSum(bad,1);
    assert(!ASUSValidateEDID(bad,&error));
    assert(!ASUSValidateEDID([NSData data],&error));
    puts("EDID tests passed: source/144 cap, independent fixture parity, identity/HDR/audio preservation, idempotence, invalid identity/checksum/layout rejection.");
    return 0;
}}
