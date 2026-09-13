#import "EDID.h"
#include <math.h>

// Layout references: upstream v4l-utils/utils/edid-decode/parse-cta-block.cpp
// and parse-displayid-block.cpp (HDMI Forum EEODB, HFVSDB, AMD VSDB, Type I DTD).
// This intentionally recognizes one monitor model and refuses other layouts.
static BOOL fail(NSError **error, NSString *why) {
    if(error) *error=[NSError errorWithDomain:@"DisplayManager.EDID" code:1
                                   userInfo:@{NSLocalizedDescriptionKey:why}];
    return NO;
}
static uint16_t le16(const uint8_t *p) {return p[0]|((uint16_t)p[1]<<8);}
static double rate(const uint8_t *p) {
    double clock=((uint32_t)p[0]+((uint32_t)p[1]<<8)+((uint32_t)p[2]<<16)+1)*10000.0;
    double ht=(double)le16(p+4)+1+le16(p+6)+1;
    double vt=(double)le16(p+12)+1+le16(p+14)+1;
    return clock/(ht*vt);
}
static void sum128(uint8_t *p) {
    unsigned sum=0;for(unsigned j=0;j<127;j++)sum+=p[j];p[127]=(uint8_t)(0-sum);
}

BOOL ASUSValidateEDID(NSData *data, NSError **error) {
    if(data.length!=384) return fail(error,@"Expected this monitor's three EDID blocks");
    const uint8_t *p=data.bytes;
    static const uint8_t id[]={0,255,255,255,255,255,255,0,0x06,0xb3,0x37,0xaa};
    if(memcmp(p,id,sizeof id)) return fail(error,@"Not an ASUS PG27UCWM EDID");
    for(unsigned i=0;i<384;i+=128) {
        unsigned sum=0;for(unsigned j=0;j<128;j++)sum+=p[i+j];
        if(sum%256)return fail(error,@"EDID block checksum mismatch");
    }
    if(p[18]!=1||p[19]!=3||p[126]!=1||memcmp(p+72,"\0\0\0\xfd\0",5))
        return fail(error,@"Unexpected base EDID version or range descriptor");
    const uint8_t *cta=p+128;
    if(cta[0]!=2||cta[1]!=3||cta[2]<7||cta[2]>109||cta[4]!=0xe2||cta[5]!=0x78||cta[6]!=2)
        return fail(error,@"Unexpected CTA/HDMI extension count structure");
    unsigned hf=0,amd=0,vdb=0;
    for(unsigned i=4;i<cta[2];) {
        unsigned len=(cta[i]&31)+1,tag=cta[i]>>5;
        if(i+len>cta[2])return fail(error,@"Truncated CTA data block");
        if(tag==2) {
            vdb++;
            // Reject unknown VICs that might advertise >144Hz outside Type I DTDs.
            static const uint8_t known[]={96,97,117,118,93,94,95,1,2,3,17,18,19,4,32,33,34,31,16,63,64};
            for(unsigned j=1;j<len;j++) {
                BOOL found=NO;for(unsigned k=0;k<sizeof known;k++)if(cta[i+j]==known[k])found=YES;
                if(!found)return fail(error,@"Unrecognized CTA video timing");
            }
        }
        if(tag==3&&len>=4&&memcmp(cta+i+1,"\xd8\x5d\xc4",3)==0) {
            if(len!=14||cta[i+4]!=1)return fail(error,@"Unexpected HDMI Forum capability layout");
            hf++;
        }
        if(tag==3&&len>=4&&memcmp(cta+i+1,"\x1a\0\0",3)==0) {
            if(len!=21||cta[i+4]!=3)return fail(error,@"Unexpected AMD capability layout");
            amd++;
        }
        i+=len;
    }
    if(hf!=1||amd!=1||vdb!=1)return fail(error,@"Expected unique HDMI Forum, AMD and video data blocks");
    const uint8_t *di=p+256;
    if(di[0]!=0x70||di[1]!=0x12||di[2]>121||di[2]<23||di[3]!=3||di[4]!=0||
       di[5]!=3||di[6]!=1||di[7]==0||di[7]%20||di[7]>100||3+di[7]>di[2])
        return fail(error,@"Unexpected DisplayID type I timing structure");
    unsigned checksumEnd=5+di[2],sum=0;
    for(unsigned i=1;i<=checksumEnd;i++)sum+=di[i];
    if(sum%256)return fail(error,@"DisplayID internal checksum mismatch");
    for(unsigned i=8+di[7];i<checksumEnd;i++)
        if(di[i])return fail(error,@"Unrecognized additional DisplayID capabilities");
    for(unsigned i=checksumEnd+1;i<127;i++)
        if(di[i])return fail(error,@"Unexpected data after DisplayID checksum");
    for(unsigned i=8;i<8+di[7];i+=20) {
        const uint8_t *t=di+i;
        unsigned w=le16(t+4)+1,h=le16(t+12)+1;
        double hz=rate(t);
        if(!((w==2560&&h==1440)||(w==3840&&h==2160))||!isfinite(hz)||hz<23||hz>241)
            return fail(error,@"Unrecognized display timing geometry or refresh rate");
    }
    return YES;
}

BOOL ASUSHasHighRefreshTiming(NSData *data) {
    if(!ASUSValidateEDID(data,NULL))return NO;
    const uint8_t *di=(const uint8_t *)data.bytes+256;
    for(unsigned i=8;i<8+di[7];i+=20)if(rate(di+i)>144.05)return YES;
    return NO;
}

NSData *ASUSCreateSinglePipeEDID(NSData *original, NSError **error) {
    if(!ASUSValidateEDID(original,error))return nil;
    NSMutableData *result=[original mutableCopy];uint8_t *p=result.mutableBytes;
    // Range descriptors and vendor VRR ranges must agree with the retained modes.
    p[78]=MIN(p[78],144);
    uint8_t *cta=p+128;
    for(unsigned i=4;i<cta[2];) {
        unsigned len=(cta[i]&31)+1,tag=cta[i]>>5;
        if(tag==3&&len>=4&&memcmp(cta+i+1,"\xd8\x5d\xc4",3)==0) {
            unsigned max=((cta[i+9]&0xc0)<<2)|cta[i+10];max=MIN(max,144);
            cta[i+9]=(cta[i+9]&0x3f)|((max>>8)<<6);cta[i+10]=max&255;
        }
        if(tag==3&&len>=4&&memcmp(cta+i+1,"\x1a\0\0",3)==0)
            cta[i+7]=MIN(cta[i+7],144);
        i+=len;
    }
    const uint8_t *source=(const uint8_t *)original.bytes+256;
    uint8_t dis[128]={0};unsigned cursor=8;
    memcpy(dis,source,8);
    for(unsigned i=8;i<8+source[7];i+=20) {
        if(rate(source+i)<=144.05) {memcpy(dis+cursor,source+i,20);cursor+=20;}
    }
    if(cursor==8) {fail(error,@"Capping would remove all DisplayID timings");return nil;}
    dis[7]=cursor-8;dis[2]=cursor-5;
    unsigned sum=0;for(unsigned i=1;i<cursor;i++)sum+=dis[i];dis[cursor]=(uint8_t)(0-sum);
    sum128(dis);memcpy(p+256,dis,128);sum128(p);sum128(cta);
    if(!ASUSValidateEDID(result,error))return nil;
    return result;
}
