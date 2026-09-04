# Upstream RustDesk Strategy

## Source project

Upstream: `rustdesk/rustdesk`

DeichDesk is a maintained downstream of RustDesk rather than an independent implementation of the RustDesk protocol.

## Architectural rule

Avoid modifying RustDesk core/session behavior unless a DeichDesk requirement cannot reasonably be implemented at the Flutter/presentation/configuration layer.

Prefer:

1. Reuse existing RustDesk models, bindings, and backend functions.
2. Build DeichDesk presentation components around those APIs.
3. Store DeichDesk-only state separately and key peer-specific state by RustDesk device ID.
4. Keep downstream patches narrow enough that upstream changes can be reviewed and integrated deliberately.

## Initial source areas identified

Current upstream desktop UI includes distinct Flutter source areas for:

- Desktop home / connection page
- Peer/address-book presentation
- Remote page and remote tabs
- File manager
- Settings
- Tray/menu-bar integration

The existing Address Book already supplies peer/tag state and filtering. Existing peer views support list presentation and online querying. DeichDesk should reuse those models while replacing the stock desktop composition.

## Baseline policy

Before importing the upstream source tree, record an exact upstream commit SHA in this document and in the repository history. Do not describe DeichDesk as tracking `master` without a pinned SHA.

Future upstream updates should be integrated intentionally on a dedicated branch or PR, tested, and then merged into `develop`.

## Branch model

- `main`: stable/releasable DeichDesk state
- `develop`: active integrated development
- feature branches: focused implementation work
- upstream integration branches: RustDesk baseline/update work

## Licensing

RustDesk is AGPL-3.0. Preserve upstream copyright/license notices and satisfy applicable source-distribution requirements for modified binaries.
