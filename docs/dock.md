# CalDigit TS3 Plus diagnostics

The command is provisioned only on these detected macOS model/profile pairs:

| Profile | Model from `sysctl hw.model` | Machine |
| --- | --- | --- |
| `personal` | `Mac17,2` | Personal base M5 MacBook Pro |
| `work` | `Mac17,8` | Work M5 Pro MacBook Pro |

On those machines:

```sh
braden-dots dock status
braden-dots dock status --json
```

The command uses public IOKit registry APIs to distinguish the dock's
Thunderbolt transport, its USB controllers and enumerated USB devices. It does
not reset devices, change accessory authorization, invoke private trace APIs,
install drivers or flash firmware. Device enumeration alone does not establish
that a keyboard, mouse, storage device or other peripheral actually works.

The current USB issue was the physical KVM selecting the other computer.
Selecting the correct computer restored the external USB devices; no USB driver
repair was needed. If only the dock's audio device and card reader appear while
expected external peripherals are missing, check the KVM selection first. The
diagnostic command does not switch the KVM.

The native reader builds on its first use and after source or macOS changes,
using Apple's command-line tools. Its executable is cached under
`${XDG_CACHE_HOME:-~/.cache}/braden-dots/dock/`. There is no login agent, daemon,
polling service or network dependency. New or mismatched machines and non-macOS
profiles do not install the reader or its source. Before building or executing,
the wrapper reads the real hardware model and current shared `DOTS_PROFILE`, so
an old wrapper cannot retain the previous profile's access after a profile change.

For a useful comparison, run the command while the USB problem is happening,
then run it again when the same dock and peripherals work. JSON uses a property
allowlist; serial fields, UUID fields and raw metadata are omitted. USB product
names still identify your peripherals. Inspect a report before sharing it
outside the machine.

The reader identifies the TS3 Plus by its Thunderbolt vendor/model IDs and
follows each USB controller's PCI-to-Thunderbolt path back to that dock. It also
handles a dock connected through another Thunderbolt device. USB devices on an
unrelated display or dock are excluded. A failed registry query is reported as
an incomplete snapshot, rather than evidence that the device is absent.

Port counters in JSON are cumulative diagnostic observations. Empty or suspended
ports are not labeled broken, and registry port names are not mapped to the
dock's front/rear sockets. A dock's internal audio device and card reader can
enumerate while an attached keyboard or mouse still fails.

The source adapts the authored public provider probe from the private
[TS3/M5 investigation archive](https://github.com/Braden1996/caldigit-ts3-m5-diagnostics).
That investigation observed a failed Thunderbolt link followed by a working
40 Gb/s connection using Apple's existing drivers. The cause of recovery was
not established. Its unsuccessful rescan probes are not a demonstrated fix and
are not packaged here. This command diagnoses the current evidence; installing
it does not fix intermittent USB connectivity.
