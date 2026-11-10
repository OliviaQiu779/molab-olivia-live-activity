# Culet interaction and prompt-library update

Validated November 9, 2026, using Xcode 27 and an iPhone 17 Pro simulator on iOS 26.5.

## Content and progress checks

The standalone Foundation checks pass across all fifteen decks:

- Fourteen built-in scenes × 24 distinct prompts = 336 scene-specific prompts; no full prompt text is duplicated between built-in scenes.
- One additional 24-prompt general deck serves custom scene names.
- Eight prompts each for Open, Explore, and Wrap up; every prompt has a brief topic cue.
- No repeats within a direction until its eight prompts are exhausted. Changing directions preserves earlier history; only an exhausted direction resets.
- JSON round trips, legacy progress decoding without history, invalid-index repair, and stable app/widget resolution pass.
- Serialized progress remains below 1 KB. Full decks are compiled locally, not included in the ActivityKit payload.

## Simulator UI checks

The test suite covers:

1. Conversation journey: scene preparation, refresh using the expanded catalog, direction changes, saving/removing, relaunch restoration, search, and custom scenes. End session opens the custom sheet; Keep going preserves the session, and confirmation clears it.
2. Hint Mode: the Profile toggle and explanation without an example card, preparation preview, full in-app question, hint-only system activity, refresh from the system, and synchronized full question on returning to the app. The test turns the preference off afterward.
3. Standard Live Activity: full-question system presentation, scene-specific refresh through its actual system button, and end-session confirmation.

The content/progress update passed the full suite: **3 tests, 0 failures**. The latest outline/toggle UI revision passed the two relevant journey and Hint Mode tests: **2 tests, 0 failures**. The final run includes the refined sheet background and three-line compact activity text. Actual simulator captures are included under Previews/.

Requested product copy has been checked: no unlock instruction, Discreet Lock Screen title, account/device disclaimer, or conversation philosophy footer remains in the relevant views. The rejected experimental empty Session layout is removed; this update retains the last delivered empty state.

## Limits

System activity captures come from Notification Center on an unlocked simulator. Physical-device authentication, Always-On, accessibility sizes, StandBy, and every Dynamic Island size still require device testing. The app does not alter iOS authentication rules.

For an existing phone installation, keep its bundle ID and team. End any running activity before installing this update because its activity data schema now uses scene IDs and progress instead of embedded decks. Preferences and saved prompt objects are retained, including legacy preference-key migration.

The latest UI refinement gives Keep going a full-width white capsule outline, matching the primary action height. Profile Hint Mode now contains only the toggle and short explanation; its example card and extra note are removed.
