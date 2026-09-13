#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// Paired HPD toggle for one currently registered Studio Display XDR AV service.
/// The callback runs every 250 ms, for up to 2 seconds, while XDR is disconnected.
/// YES from the callback ends the interval early. nil performs a bounded pulse.
/// Every successful first toggle is paired with a second before normal return.
/// Does not change EDID itself. Rejects missing, ambiguous or changed targets.
BOOL PulseXDR(uint64_t registryID, BOOL (^ _Nullable middle)(void),
              NSError * _Nullable * _Nullable error);
NS_ASSUME_NONNULL_END
