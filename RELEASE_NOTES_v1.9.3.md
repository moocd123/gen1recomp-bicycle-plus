# AUTOBIKE+ v1.9.3 — Mobile imports and combined handlebars

**Use MODS → Check for updates → Update All, then fully close/reopen the app.** Versions v1.4.2 onward retain the same update source and internal ID. No deletion or manual reimport is needed. The installable asset remains `bicycle_plus-1.9.3.zip`.

## Import Song repair

- Accept both current per-request mobile deliveries and older required-import staging files, including final files whose completion marker is absent.
- Clear pending status after successful import or a detected failure instead of waiting indefinitely for only one kind of callback.
- Recover an already-returned file from a pending earlier-version request when available.
- Let the same **IMPORT SONG** action retry after a picker returns no callback; retain a timeout as a backstop.
- Use the engine's bounded reader, validate stable/completed data before decoding, and preserve unrelated import files and markers.

The single-action file picker, local playback and the working other-game soundtrack path are retained. Original files selected from your device are never removed. This addresses a reproduced delivery-compatibility defect matching the reported symptom; physical phone testing is still needed.

## One HANDLEBARS control

Appearance now has **WHEEL, STRIPE, CENTRE, EDGE and HANDLEBARS**, followed by RESET COLOURS. HANDLEBARS paints its existing pixels plus the former DETAILS group. No new hand or clothing pixels have been added to the paint mask.

A saved custom handlebar colour takes priority. When handlebars were Original but Details had a custom colour, that Details colour becomes the combined colour. Otherwise Original stays Original. Other colours and their saved custom values are unchanged. Reset affects paint only; the obsolete Details key is cleared along with the five visible parts.

## What stays unchanged

AUTO BIKE defaults and saved ON/OFF, AREA/BICYCLE/BOTH, volumes, filters, songs, resume behaviour, native Audio, movement and other-game playback are retained. The mod ID/repository are unchanged.

## Checks and testing limits

New native-sandbox import completion/retry tests, menu/migration tests and software-rendered pixel checks run before packaging. CI also runs real LOVE decoding/streaming tests using generated WAV, MP3, Ogg and FLAC tones; native mobile callbacks are simulated and audio output is null. These are not physical-device or full-gameplay tests. Check Actions/VERIFICATION.md for exact scope.

**Back up/export your progress and save before trying imports.** A crash can still lose unsaved progress. There is no new progress-save writer or ROM patch. For manual installation use the attached mod ZIP, not GitHub's Source code ZIP.
