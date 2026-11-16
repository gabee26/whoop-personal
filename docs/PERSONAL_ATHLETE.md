# Personal iPhone athlete journal

This feature is specific to the user's personal iOS fork. It does not change the shared
physiological scores, Bluetooth commands, database migrations, Android behavior, or the
cross-platform `.noopbak` format. Android parity is intentionally not added for this
personal iPhone UI and its separate JSON journal.

## Included flows

- Home and More open the athlete page; the goals page also links to it.
- A daily check-in records energy, fatigue and subjective sleep quality (1–5), discomfort
  by body area (0–10), and optional notes. Saving the same day updates that record.
- Sessions support type, date/time, duration, planned/completed state, optional RPE (1–10),
  notes, editing and confirmed deletion. Only completed, rated sessions contribute to load.
- Perceived load is minutes multiplied by RPE, in arbitrary units. It is never added to
  cardiovascular strain or used to alter physiological recovery.
- Sleep planning subtracts the chosen sleep target and sleep-onset buffer from the next
  selected wake time. This is a schedule, not a personalized physiological sleep-need model,
  and does not change the strap alarm.
- Weekly reporting shows completed/rated sessions, registered load, check-in and sleep
  coverage, mean available sleep, and the sum of shortfalls against the current target.
  Missing nights are excluded and surplus is not banked. This sum is not physiological debt.
- Each completed session displays the available next-calendar-day sleep/recovery/check-in.
  These are descriptive associations, not causal effects or injury predictions.
- The morning view uses available same-calendar-day records. Its descriptive HRV/RHR
  reference requires at least seven positive finite daily readings in the previous 14 days.
  This does not replace the scoring engine's own baseline or confidence calculation.
- A high reported fatigue (4–5) or discomfort (6–10) highlights the user's own report.
  These display thresholds are interface choices, not validated diagnostic cutoffs.
- The report is shared only through a user action; it omits free-text notes and body zones.

## Persistence

`Application Support/PersonalAthlete/journal-v1.json` contains the versioned journal.
Candidate data is validated and atomically written before published state changes.
Read failures lock ordinary saves instead of replacing unreadable existing data with an
empty journal. A validated, explicitly confirmed restore can recover that condition.
Export is disabled until the current journal has been read successfully.

The JSON export contains all check-ins and sessions. It is separate from strap backups;
sleep goals and wake-time preferences remain in UserDefaults. Invalid files, duplicate
identifiers, invalid scales, unsupported versions and oversized imports are rejected.

## Calculation audit

- `Calories.estimateDayEnergy` combines revised Harris–Benedict resting energy with
  Keytel-based active energy over supported HR intervals. Its `totalKcal` is persisted
  under the historical name `DailyMetric.activeKcalEst`. Personal UI labels now say
  daily calories, not active calories. The stored field and formula are unchanged.
- `StrainScorer` already applies logarithmic compression. Multiplying its 0–100 output
  by 0.21 changes the display axis only; it does not reproduce WHOOP's proprietary model.
- Recovery remains the existing locally weighted baseline-normalized estimate. No new
  WHOOP/Amazfit coefficients are invented or imported.
- The comparison screen reads imported and computed stores separately. Matching an
  official score is not evidence of physiological accuracy. Future fitted experiments
  must use held-out dates and preserve the incumbent until evaluated.

## Validation and limitations

`PersonalAthleteRecordsTests` covers archive round trips/rejection, invalid values,
missing sleep, baseline sample requirements, load exclusion and bedtime arithmetic.
The personal GitHub workflow automatically starts on relevant pushes to main (or manual
dispatch), runs the StrandDesign and StrandAnalytics tests, then compiles the iOS target.
Local Python branding checks do not substitute for that build.

On an iPhone, verify save/relaunch/edit/delete, JSON export/restore/cancel, weekly date
navigation, next-day context, Dynamic Type, airplane-mode history, sync and the existing
strap alarm. Actual signal quality and recovery accuracy require paired user data.
