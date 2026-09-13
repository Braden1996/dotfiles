#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// Validates the supported Studio Display XDR EDID layout and all checksums.
BOOL XDRValidateEDID(NSData *data, NSError * _Nullable * _Nullable error);
/// YES when this exact model explicitly advertises a timing above60Hz.
BOOL XDRHasHighRefreshTiming(NSData *data);
/// Temporary single-pipe cap preserving native5K60, HDR and all identity/tile bytes.
/// Retains source timings only; rejects unknown layouts and is idempotent.
NSData * _Nullable XDRCreateSinglePipeEDID(NSData *original,
                                          NSError * _Nullable * _Nullable error);
NS_ASSUME_NONNULL_END
