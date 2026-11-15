# WHOOP personal iPhone build

This personal app displays the name WHOOP and is a non-commercial derivative of NOOP.
It is not the official WHOOP application. Upstream copyright,
LICENSE, NOTICE and ATTRIBUTION.md remain applicable and unchanged.

## Baseline

The user supplied a main-branch source ZIP identifying itself as version 12.1.0,
build 439. Its exact upstream commit and its equivalence to the installed iPhone
binary have not been established. No hardware or Xcode build has been run here.

## First milestone

`python Tools/prepare_personal_whoop.py` creates an ignored XcodeGen specification and
provenance manifest. It preserves upstream protocol, BLE, collection, persistence,
and analytics sources. The iOS presentation is customized as described below. The iOS display name becomes WHOOP. The app identifier
is `com.gabriel.whooppersonal.noop`; widgets and App Group use the same isolated prefix.
The URL scheme becomes `personal-whoop-personal`; existing `noop://` links still belong to
the original app. Oura OAuth redirect configuration is outside this milestone.
The product/module names remain unchanged for build compatibility.

The original NOOP and WHOOP have separate containers. Data is not automatically
copied. Export a NOOP backup before testing and import a copy only through the
existing backup UI. Keep the original backup. Do not run two simultaneous strap
sync sessions: separate app identities do not guarantee simultaneous BLE access.

## Build from Windows using GitHub Actions

1. Put this source tree at the root of a personal repository, including dotfiles.
   Do not upload the sibling Flutter project, health exports, backups or secrets.
2. Enable Actions and run **WHOOP - personal iPhone IPA** manually on the selected
   branch. This workflow uses a macOS runner with Xcode; runner availability,
   billing and account quotas must be checked before running it.
3. Download the `WHOOP-iPhone-<run number>` artifact after a successful run.
4. Extract `WHOOP-ios.ipa` and install through SideStore. SideStore supplies the
   personal signing identity; the build does not request Apple credentials.
5. Verify the installed app name, separate data, pairing, history synchronization,
   background behavior and overnight coverage on the actual iPhone/WHOOP 5.0.

The workflow is manual, read-only with respect to repository contents, and uploads
build artifacts only. It does not publish a release or change the NOOP update feed.
Use this workflow, not upstream's release/staging workflows, for personal IPAs.
The inherited in-app update links still point upstream; do not use those to update
WHOOP. A dedicated update channel and visual redesign are later milestones.

## Screenshot-based iPhone presentation

The personal iOS shell now uses `PersonalWhoopHome`, `PersonalWhoopHealth`,
`PersonalWhoopMore` and the floating `PersonalWhoopDock`. Shared visual tokens,
cards and score rings live in StrandDesign/PersonalWhoopStyle.swift. This is an
iOS-only presentation change; Android and the analytics/protocol layers are unchanged.

The home reads repository daily rows and the existing sleep-performance series,
never fixed sample scores. It supports date navigation, real optional score rings,
metric rows, and a trailing-calendar-week effort/recovery chart. Device and live
HR indicators observe LiveState separately. Missing values stay missing. The
health screen opens the existing detailed monitor; device controls open the
existing manager rather than issuing new BLE commands.

This is a first visual implementation, not pixel-verified parity. Sleep, recovery
and effort now open PersonalMetricDetail, carrying the home-selected date, reading
existing repository scores and presenting calendar-week charts. Sleep composition
shows recorded stage durations, not a fabricated hypnogram. Advanced analysis is
still available through an explicitly labelled link to the upstream screens;
those screens retain their own date selection. Stress and activities have personal overview screens; their advanced editors retain
upstream controls. The iPhone alarm layout and shared scaffold/palette now use
the personal theme, including inherited settings and Coach screens. No detail-screen reference screenshots
have yet been supplied, so the new detail layout is inferred from the home style.
The screenshot's proprietary wordmark, strap photograph and custom icon artwork
have not been imported; text and system symbols are used. Subscription messaging
is omitted. Humans explicitly explains that no social backend is connected.
The home alarm card routes to the existing scheduler instead of displaying the
screenshot's fixed times. Dashboard visibility preferences for HRV, resting HR, steps and active calories
are persisted locally. Remaining advanced metric tiles are available in the metric explorer. No visual render or Xcode
build has been possible on the Windows host.

## Current validation limits

The generator can be checked on Windows. Xcode project generation, Swift
compilation, signing templates and device operation require the macOS build and
real iPhone tests. Source-level preparation is not evidence of a working IPA.
HealthKit, widgets and background execution remain subject to the signing identity
and iOS behavior. No claim of WHOOP-equivalent metrics is made.

## Navigation review

The floating dock has four destinations (0, 1, 2, 4). Horizontal navigation
skips the reserved Coach tag; Coach routes and its dock button open a sheet,
respecting the existing master switch. Turning Coach off dismisses that sheet.
Non-finite chart values are omitted. Sleep score is cleared while the selected
day loads, preventing the previous day score from appearing under a new date.
The shared iOS scaffold intentionally replaces optional sky backgrounds; macOS
retains its original scaffold and neutral palette.

Dashboard preferences are personal presentation settings, not additions to the
upstream cross-platform backup whitelist. Some advanced controls remain in English.

## Score audit and axis correction

The initial personal UI incorrectly interpreted `DailyMetric.strain` as 0...21.
`StrainScorer.maxStrain` and the import pipeline establish the stored axis as
0...100. PersonalMetricScale now converts this to 0...21 for home, effort details
and activity summaries. The combined weekly chart retains the stored 0...100
normalized axis instead of multiplying it by 100/21 a second time. This fixes a
presentation error; it does not improve the physiological model's accuracy.

`AnalyticsEngine.Rest` documents the local sleep composite: duration 0.50,
efficiency 0.20, restorative share 0.20, consistency 0.10. The detail screen now
explains this and shows recorded efficiency separately. Imported scores may have
different semantics; advanced source inspection remains available.

RecoveryScorer uses a personal-baseline composite and logistic mapping. No weights,
baselines, sleep staging, sensor decoding or stored scores were changed in this
pass. Accuracy against the official application is unmeasured. Paired day-level
exports would be needed to quantify error; rescaling alone is not validation.

PersonalMetricScaleTests covers anchors, the import round trip across 211 values,
missing/non-finite/out-of-range scores and genuine zero scores. The personal IPA
workflow now runs analytics and design package suites before building. These Swift
tests are prepared but have not been executed on the Windows host (no Swift/Xcode).

## Read-only comparison screen

More > Compare indicators opens PersonalComparisonScreen. It reads imported and
computed source IDs separately through the same active-first/canonical fallback
as CsvExport, never the dashboard's merged daily rows. It compares total sleep
minutes, HRV, resting HR, recovery and effort on equal day keys. Effort is converted
to 0...21 on both sides. Each metric reports matched days, source-only counts,
mean absolute difference and signed mean local-minus-imported difference, plus
individual daily pairs and a user-initiated CSV text share sheet.

The screen calls the reference "imported", not "official": NOOP re-exports can
contain computed values, and source identity alone cannot authenticate the file.
Use original WHOOP exports and confirm the same cycle/night boundaries before
interpreting differences. This does not establish clinical accuracy or calibrate
scores automatically. It also does not equate the different sleep-score models;
the sleep comparison is total sleep duration. Raw measured timing comparisons
and a paired-data accuracy report still require actual data.

PersonalComparisonSummaryTests covers signed cancellation versus absolute error,
missing days, real zeroes, non-finite values, and no-overlap behavior. It is a
presentation utility, with no scoring or persistence mutations and no Android
formula change. Tests are included in the existing pre-IPA StrandDesign test gate.

## Final local navigation pass

PersonalSettingsScreen groups profile, device, alarm, original data importer,
backups, Apple Health, shortcut export, comparison, Coach, battery preferences,
automations, Siri and diagnostic/capability screens. PersonalTrainingTools exposes
strength logs, intervals, breathing, trends, period comparison, lab records and
metric exploration. They reuse upstream editors and bindings through native
navigation links, with the shared personal palette/scaffold. The device overview
now scrolls on smaller displays. Comparison's import action opens DataSourcesView,
not BackupSyncView. These remain visual/navigation changes, with no BLE commands
or scoring changes.

The existing app catalog already provides pt-PT translations for Settings, Data
Sources, Workouts, Sleep and primary buttons. Advanced screens retain upstream
content and may still have untranslated dynamic text. The settings hub does not
claim to reimplement those editors or the WHOOP cloud services.

Local verification: destination declarations, route wiring, source separation,
UTF-8 and structural balance checked; doc_comment_lint passed. These are static
checks, not a Swift type-check or UI render. The personal specification generator
runs on Windows. Swift/Xcode are absent, so package suites and iPhone compilation
remain unexecuted. No IPA is claimed. Next execution boundary is the existing
manual personal-whoop-ios workflow on macOS, then SideStore and device validation.

## Personal repository automation

Upstream workflows are preserved under `.github/upstream-workflows` and are
inactive in this personal repository. Only the manually dispatched personal iPhone
workflow remains under `.github/workflows`, avoiding unrelated upstream scheduled,
push, release and maintenance jobs.
