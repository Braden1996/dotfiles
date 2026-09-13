#import "XDR.h"
#include <math.h>
// Type I timing and range-descriptor parsing follows upstream v4l-utils
// utils/edid-decode/parse-displayid-block.cpp and parse-base-block.cpp.
static BOOL xfail(NSError **error,NSString *why) {
    if(error)*error=[NSError errorWithDomain:@"DisplayManager.XDR" code:1 userInfo:@{NSLocalizedDescriptionKey:why}];
    return NO;
}
static unsigned x16(const uint8_t *p){return p[0]|((unsigned)p[1]<<8);}
static double xrate(const uint8_t *p){
    double clock=((unsigned)p[0]+((unsigned)p[1]<<8)+((unsigned)p[2]<<16)+1)*10000.0;
    return clock/(((double)x16(p+4)+1+x16(p+6)+1)*((double)x16(p+12)+1+x16(p+14)+1));
}
static double dtdrate(const uint8_t *p){
    double c=x16(p)*10000.0;
    unsigned ht=p[2]+((p[4]&240)<<4)+p[3]+((p[4]&15)<<8);
    unsigned vt=p[5]+((p[7]&240)<<4)+p[6]+((p[7]&15)<<8);
    return ht&&vt?c/(ht*vt):0;
}
static void xsum(uint8_t *p){unsigned s=0;for(unsigned i=0;i<127;i++)s+=p[i];p[127]=(uint8_t)(0-s);}
static BOOL zeros(const uint8_t *p,unsigned start,unsigned end){for(unsigned i=start;i<end;i++)if(p[i])return NO;return YES;}
static BOOL diValid(const uint8_t *p){
    if(p[0]!=0x70||p[1]!=0x12||p[2]>121||p[4]!=0)return NO;
    unsigned end=5+p[2],s=0;for(unsigned i=1;i<=end;i++)s+=p[i];
    return s%256==0&&zeros(p,end+1,127);
}
BOOL XDRValidateEDID(NSData *data,NSError **error){
    if(data.length!=640&&data.length!=768)return xfail(error,@"Expected Studio Display XDR factory or capped block count");
    const uint8_t *p=data.bytes;
    static const uint8_t id[]={0,255,255,255,255,255,255,0,6,0x10,0x42,0xae};
    if(memcmp(p,id,sizeof id))return xfail(error,@"Not a Studio Display XDR EDID");
    if(p[18]!=1||p[19]!=4||p[126]+1!=data.length/128||memcmp(p+90,"\0\0\0\xfd",4))
        return xfail(error,@"Unexpected XDR base EDID layout");
    for(unsigned i=0;i<data.length;i+=128){unsigned s=0;for(unsigned j=0;j<128;j++)s+=p[i+j];if(s%256)return xfail(error,@"EDID block checksum mismatch");}
    for(unsigned i=54;i<90;i+=18)if(dtdrate(p+i)<1||dtdrate(p+i)>60.05)return xfail(error,@"Unexpected base timing");
    // This model's CTA block contains only colorimetry/HDR and <=60Hz DTDs.
    const uint8_t *cta=p+128;
    if(cta[0]!=2||cta[1]!=3||cta[2]!=15||cta[4]!=0xe3||cta[5]!=5||cta[8]!=0xe6||cta[9]!=6)
        return xfail(error,@"Unexpected XDR CTA HDR/colorimetry layout");
    for(unsigned i=15;i+18<=127;i+=18){if(zeros(cta,i,i+18))break;if(dtdrate(cta+i)<1||dtdrate(cta+i)>60.05)return xfail(error,@"Unexpected CTA timing");}
    const uint8_t *ident=p+256;
    if(!diValid(ident)||ident[3]!=2)return xfail(error,@"Invalid DisplayID identity block");
    // Keep all identity/vendor/topology bytes, but reject new blocks with unknown timings.
    const unsigned tags[]={0x29,1,0x7f,0x7e,0x12,0x7f,0x7f};
    const unsigned sizes[]={19,15,10,8,25,9,10};unsigned pos=5;
    for(unsigned i=0;i<7;i++){
        if(pos+sizes[i]>5+ident[2]||ident[pos]!=tags[i]||ident[pos+2]+3!=sizes[i])return xfail(error,@"Unrecognized XDR identity/topology structure");
        pos+=sizes[i];
    }
    if(!zeros(ident,pos,5+ident[2]))return xfail(error,@"Additional XDR identity capabilities unsupported");
    BOOL native60=NO,tile60=NO;
    for(unsigned b=3;b<data.length/128;b++){
        const uint8_t *di=p+128*b;
        if(!diValid(di)||di[3]!=0||di[5]!=3||di[6]!=1||!di[7]||di[7]%20||di[7]>100||8+di[7]>5+di[2]||!zeros(di,8+di[7],5+di[2]))
            return xfail(error,@"Unrecognized XDR detailed timing structure");
        for(unsigned i=8;i<8+di[7];i+=20){
            unsigned w=x16(di+i+4)+1,h=x16(di+i+12)+1;double hz=xrate(di+i);
            if(!((w==5120&&h==2880)||(w==2560&&h==2880)||(w==3840&&h==2160)||(w==2560&&h==1440))||!isfinite(hz)||hz<47||hz>121)
                return xfail(error,@"Unrecognized XDR timing geometry or refresh rate");
            if(w==5120&&h==2880&&fabs(hz-60)<.01)native60=YES;
            if(w==2560&&h==2880&&fabs(hz-60)<.01)tile60=YES;
        }
    }
    if(!native60||!tile60)return xfail(error,@"Missing native5K60 or matching tile timing");
    return YES;
}
BOOL XDRHasHighRefreshTiming(NSData *data){
    if(!XDRValidateEDID(data,NULL))return NO;const uint8_t *p=data.bytes;
    for(unsigned b=3;b<data.length/128;b++){const uint8_t *di=p+128*b;for(unsigned i=8;i<8+di[7];i+=20)if(xrate(di+i)>60.05)return YES;}
    return NO;
}
NSData *XDRCreateSinglePipeEDID(NSData *original,NSError **error){
    if(!XDRValidateEDID(original,error))return nil;
    const uint8_t *p=original.bytes;NSMutableData *out=[NSMutableData dataWithBytes:p length:384];
    for(unsigned b=3;b<original.length/128;b++){
        const uint8_t *di=p+128*b;uint8_t n[128]={0};memcpy(n,di,8);unsigned cursor=8;
        for(unsigned i=8;i<8+di[7];i+=20)if(xrate(di+i)<=60.05){memcpy(n+cursor,di+i,20);cursor+=20;}
        if(cursor==8)continue;
        n[7]=cursor-8;n[2]=cursor-5;unsigned s=0;for(unsigned i=1;i<cursor;i++)s+=n[i];n[cursor]=(uint8_t)(0-s);xsum(n);[out appendBytes:n length:128];
    }
    uint8_t *base=out.mutableBytes;base[94]=0;base[95]=47;base[96]=60;base[97]=66;base[98]=178;base[99]=93;base[126]=out.length/128-1;xsum(base);
    if(!XDRValidateEDID(out,error))return nil;return out;
}
