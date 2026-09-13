#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// Validates checksums, exact ASUS model, and the supported factory/capped layout.
BOOL ASUSValidateEDID(NSData *data, NSError * _Nullable * _Nullable error);
/// YES only when an explicitly advertised timing exceeds 144 Hz. Does not mutate.
BOOL ASUSHasHighRefreshTiming(NSData *data);
/// Retains factory timings <=144Hz and all identity, HDR, audio and link capabilities.
/// Idempotent. Returns nil for another model, corrupt data or unrecognized layout.
NSData * _Nullable ASUSCreateSinglePipeEDID(NSData *original,
                                          NSError * _Nullable * _Nullable error);
NS_ASSUME_NONNULL_END
