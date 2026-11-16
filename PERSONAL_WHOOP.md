# WHOOP personal iPhone build

## Compact metrics presentation (2026-11-16)

The personal iPhone theme now uses smaller headings, cards, spacing and home rings.
Home and Health link to a fitness screen that reads the existing `fitness_age` and
`vo2max_est` series, shows the calculation date and persisted VO2 estimator, and
allows the existing weekly calculation to be refreshed. The profile exposes waist
circumference, already consumed by that engine. These are local estimates, not
WHOOP Age or a laboratory VO2 measurement. The new adult-model screen does not
show these estimates for profiles under 18; no underlying analytics formula changed.

The curved 0–3 stress gauge displays a daily summary, explicitly not a live reading.
Both personal date-selected surfaces use `PersonalStressSummary`, which rejects
other-day carry and future inputs. Intraday analysis remains a separate, clearly
labelled today view. The calorie history now uses `energy_kcal`, consistent with
the local daily-total catalog entry and the home card.

This is an iPhone presentation change; Android calculations and stored values are
unchanged. No third-party implementation was copied. Reference screenshot text
was retrieved, but image materialization failed, so exact visual matching has not
been verified. Seven existing Python branding/icon tests and the personal project
generator pass on Windows. Four regression tests were added in
`StrandTests/PersonalStressSummaryTests.swift`; they require the macOS app test
target and have not run here. SwiftUI compilation, simulator screenshots and
strap operation remain unverified. GitHub connectivity failed during this change;
no remote build or updated IPA has been produced.

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

## First device feedback: missing sleep ring

The personal home/detail queried imported-only `series(sleep_performance)`.
This omitted the computed metric series for a locally measured night. Both now use
`exploreSeries`, which merges imported and computed series with the repository's
existing priority and daily fallback. The sleep detail reads its score by day key
even if no matching daily row is available. Its history uses the same day-keyed
series and supports 7/30/90 days. No source writes or scoring changes.

Sleep/recovery/effort no longer link to the upstream SleepView/TodayView/TrendsView.
PersonalHealthHistory replaces HealthView and MetricExplorerView in the personal
primary routes with new 7/30/90-day charts and daily readouts. Advanced operational
screens (pairing, settings editors, import/export, workout editors, alarm and Coach)
are still inherited and must be redesigned separately; this pass does not claim
complete replacement of all NOOP UI. Device confirmation of the sleep fix and a
new Xcode build are pending.


## Complete presentation pass after device feedback (2026-11-16)

The iPhone shell and quick-action routes now open the personal live, pairing,
workout, import, health and settings views. TabRoute uses personal metric details
and preserves explicit metric source identity; the macOS routes remain separate.
The metric catalogue has its own searchable list and 7/30/90/365-day detail pages.
The home and sleep detail continue to read the same merged sleep-performance
series, including locally computed nights, and clear stale values during reloads.

New iOS layouts are implemented in the shared journal, insights, intelligence,
stress, trends, strength, interval timer, breathing, Apple Health, advanced settings,
power saving, diagnostics, capability, raw timeline, alarm, backup and Coach views.
Their existing data loaders, engine state, confirmations and preference keys are
retained. The operational screens use PersonalPage/PersonalSection and the shared
card, button, typography and gauge renderers now select the personal design on iOS.
This also covers secondary cards reached from editors and diagnostic sheets.
System pickers, permission dialogs, native Siri tips and existing specialist editor
controls remain native/shared components; this is not a claim that every upstream
view implementation has been removed or that every screen matches an unseen WHOOP
reference pixel for pixel. License notices and technical file names are retained.

New pairing/live screens call the existing AppModel methods, with no new Bluetooth
commands. The live screen owns one realtime-HR reference and releases only that
reference on exit. Workout sport names come from the canonical catalogue; display
labels do not rewrite persisted sport names. Workout edit/save/delete use existing
repository operations; deletion requires confirmation and removes the saved route
through the same helper used upstream. Import uses the existing as-copy document
picker and original ZIP importers. The advanced settings entry retains access to
units, zones, calibration, notifications and experimental controls.

Stress reads the merged metric series rather than imported-only rows, and its
intraday panel can appear even without a daily stress summary. No analytics weights,
BLE protocol, storage schema, source identifiers or persisted scale were changed.
Android does not need formula parity changes for this presentation-only pass.

Validation on the Windows host: UTF-8, delimiter/directive balance, route and symbol
inspection, `git diff --check`, and documentation-comment lint. These checks do not
replace Swift type-checking. The new iOS branches still need the macOS-hosted manual
IPA workflow and a device review, including real night data, pairing/reconnect,
workout save, backup restoration and Coach configuration. No newly built IPA or
measured accuracy improvement is claimed by this source revision.


## Premium presentation and operational pass (2026-11-16)

User feedback confirmed that revision 9437d9d built and installed. This pass has
not yet been built on Xcode. It replaces the iOS first-run and update views with
personal presentations, retaining existing onboarding completion and terms
acceptance records. The update sheet uses its own revision key, marks swipe
 dismissal as seen, and no longer proposes upstream NOOP release updates. The
native launch background uses a named dark colour asset.

PersonalGlassSurface provides a single material layer, restrained border and
shadow. Reduce Transparency or Increase Contrast substitutes a solid card.
Cards and the dock use this shared surface. Existing legal attribution, license
notices, source identifiers, app group and bundle identifiers remain unchanged.
The personal build generator creates an iOS-only localization catalogue with
WHOOP display branding; it preserves format specifiers, source lookup keys,
technical filenames, links and upstream legal attribution. The original shared
catalogue remains unchanged. Branding tests run before resource generation in CI.

Operational corrections and additions:
- Pull-to-refresh now requests a history sync through BLEManager.syncNow when
  historyReady permits it; the old personal home only reloaded database rows.
- A sync card shows real connection, backfill blocks, last completion and errors.
  It does not invent a completion percentage or treat a UI reload as a strap sync.
- Trends opens TrendsView rather than the effort score. Dashboard metric cards
  open their exact catalogue key/source; local calorie estimates use energy_kcal.
- The former disconnected social placeholder becomes a local Plan tab. Sleep,
  steps and weekly activity goals are user-editable and persisted locally. Missing
  values are shown as unavailable, not successful goals or fabricated zeroes.
- Live workouts expose the existing pause/resume action, active-time clock,
  mean HR and effort, with an explicit connection-loss state and saved-history link.
  The timer uses the existing tested ActiveWorkoutIndicatorModel/ActiveWorkoutClock.

Scope limits: no official community/accounts, cloud coaching access, proprietary
WHOOP scoring, or clinically validated sensor estimates are introduced. Goals are
personal targets, not physiological prescriptions. Existing HealthKit, notifications,
alarm and background-sync capabilities remain subject to iOS signing, permissions,
firmware and actual hardware. App-store/private server functionality cannot be
established by repainting its UI. Device-level functionality is not certified by
these source checks.

Validation: Python branding tests (ordinary text, placeholders, plural forms,
protected technical/legal strings), personal project generation, generated resource
and identity checks, documentation-comment lint, UTF-8/directive/delimiter review
and git diff whitespace checks. Existing analytics/design Swift suites and iOS
Release compilation remain in the manual GitHub workflow. Hardware verification
requires the new IPA; no local Windows SwiftUI build or Bluetooth test is claimed.
