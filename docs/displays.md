# External displays on the personal M5

The native display manager is installed only for the `personal` profile on a
MacBook Pro with model identifier `Mac17,2`. Other Macs, work profiles and Linux
do not receive its source or login agent. The agent also checks the hardware
before launch, and the executable checks it again before managing displays.

Chezmoi builds the Objective-C source with Apple's command-line tools when the
source changes. The user LaunchAgent starts in the graphical login session;
there is no root daemon or additional package dependency.

The manager targets these native display configurations:

| Connected monitors | ASUS PG27UCWM | Apple Studio Display XDR |
| --- | --- | --- |
| Both | 3840 × 2160 at 144 Hz | 5120 × 2880 at 60 Hz |
| ASUS only | 3840 × 2160 at 240 Hz | — |
| Studio Display XDR only | — | 5120 × 2880 at 120 Hz |

The combined configuration has been verified with both screens visibly working
normally. The user confirmed the XDR image is good and corrected the ASUS
scaling to a 2560 × 1440 HiDPI workspace at 144 Hz. The manager preserves the
current scaling when changing refresh rates. A paired software reconnect of the XDR has also restored both screens.
Physical unplug/replug transitions, automatic restoration of each monitor's
single-display refresh rate, and the opposite connection order remain
**unverified on hardware**. The single-display rows describe the implemented
policy, not completed physical verification.

The manager uses temporary EDID capability limits to fit both displays within
the base M5's available display resources. It requests factory capabilities
again when a single monitor remains. It uses private macOS runtime APIs, so
compatibility may change after a macOS update. Recovering display allocation can
briefly blank the XDR while it disconnects and reconnects in software. No
monitor firmware is flashed.

Inspect the current state:

```sh
~/.local/libexec/braden-displays status
launchctl print gui/$(id -u)/com.braden.displays
```

Read recent manager messages from the macOS unified log:

```sh
log show --last 15m --style compact \
  --predicate 'subsystem == "com.braden.displays"'
```

Stop management and restore the original display capabilities:

```sh
launchctl bootout gui/$(id -u)/com.braden.displays
~/.local/libexec/braden-displays restore
```

Start it again:

```sh
launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/com.braden.displays.plist
```

The stop command lasts for the current login session. To keep the agent off
across logins, use `launchctl disable gui/$(id -u)/com.braden.displays`; use
`launchctl enable` with the same service name before starting it again.

The integration check verifies the installation gates and LaunchAgent
configuration without changing live display settings. These automated checks
do not substitute for the remaining physical verification above.

`mise run check:displays` also checks sanitized fixture identities and runs pure
EDID transformation tests on macOS. The tests cover expected capped bytes,
preservation of unaffected capabilities, repeated application and rejection of
invalid monitor identities, checksums and layouts. They never start the daemon.
Policy tests also cover stable attachment detection, a pause after each display
change, action cooldowns and finite retries that reset only after a stable
physical topology change or a real system wake.
The reconnect-controller tests replace all IOKit calls with fakes and check
paired cleanup through timeouts, exceptions and signals. The test runner refuses
to execute that test binary if it imports an unmocked IOKit or dynamic loader
function.
