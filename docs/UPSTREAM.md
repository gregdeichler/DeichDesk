# Upstream RustDesk Strategy

## Source project

Upstream: `rustdesk/rustdesk`

DeichDesk is a maintained downstream of RustDesk rather than an independent implementation of the RustDesk protocol.

## Pinned v1 baseline

The initial DeichDesk v1 development baseline is RustDesk commit:

`82aa28f129b187e05191d557300eecf760bd12a1`

Upstream commit date: 2026-09-03.

This exact SHA is the reference point for the first DeichDesk implementation. DeichDesk does not consume upstream `master` automatically.

## Architectural rule

Avoid modifying RustDesk core/session behavior unless a DeichDesk requirement cannot reasonably be implemented at the Flutter/presentation/configuration layer.

Prefer:

1. Reuse existing RustDesk models, bindings, and backend functions.
2. Build DeichDesk presentation components around those APIs.
3. Store DeichDesk-only state separately and key peer-specific state by RustDesk device ID.
4. Keep downstream patches narrow enough that upstream changes can be reviewed and integrated deliberately.

## Initial source areas identified

Pinned upstream desktop UI includes distinct Flutter source areas for:

- `flutter/lib/desktop/pages/desktop_home_page.dart` — current home composition, local ID/password pane, and right-side connection page.
- `flutter/lib/desktop/pages/connection_page.dart` — Connect by ID, peer browser container, and service/server status.
- `flutter/lib/common/widgets/peer_tab_page.dart` — Recent/Favorites/Discovered/Address Book/Group peer navigation.
- `flutter/lib/common/widgets/address_book.dart` — Address Book/tag presentation.
- `flutter/lib/common/widgets/peers_view.dart` and peer-card widgets — peer list/grid/tile presentation and filtering/sorting.
- Remote page/tab source — remote-session presentation.
- File manager source — transfer presentation.
- Settings source — existing RustDesk configuration UI.
- Tray/menu-bar integration — resident app behavior and quick actions.

The existing Address Book remains the source of truth for peers and tags. Existing discovered/LAN peer models remain the source for Accessible Devices. DeichDesk should reuse those models while replacing the stock desktop composition.

## DeichDesk integration boundary

The intended dependency direction is:

```text
DeichDesk UI
  Launcher / This Device / Host / Quick Support / Settings / Session chrome
        |
DeichDesk integration + preferences layer
        |
Existing RustDesk Flutter models and bindings
        |
RustDesk Rust/session core
  connectivity / auth / codecs / input / clipboard / file transfer / audio
```

The integration layer should be thin. It may normalize RustDesk model data for DeichDesk widgets and own DeichDesk-only preferences, but it must not duplicate the Address Book, credentials, discovery, or session engine.

## Upstream areas to avoid changing in Phase 1

Unless compilation requires a narrowly documented adjustment, Phase 1 must not modify:

- Rust networking/session protocol code
- Video/audio codecs
- Input transport
- Authentication/credential implementation
- Relay/rendezvous behavior
- Clipboard transport
- File-transfer backend
- RustDesk Address Book storage/API behavior

Phase 1 is a launcher/presentation change.

## Baseline policy

Record every future upstream baseline as an exact commit SHA. Do not describe DeichDesk as tracking `master` without a pinned SHA.

Future upstream updates should be integrated intentionally on a dedicated branch or PR, tested, and then merged into `develop`.

## Branch model

- `main`: stable/releasable DeichDesk state
- `develop`: active integrated development
- `feature/*`: focused implementation work
- `upstream/*`: RustDesk baseline/update work

## Licensing

RustDesk is AGPL-3.0. Preserve upstream copyright/license notices and satisfy applicable source-distribution requirements for modified binaries.
