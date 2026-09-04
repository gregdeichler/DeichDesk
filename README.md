# DeichDesk

DeichDesk is a family/home-focused remote desktop client built from RustDesk, with a compact device-centric desktop experience for Windows and macOS.

## Project goals

- Preserve RustDesk's remote-desktop engine, address book, discovery, authentication, file transfer, tunneling, and advanced capabilities.
- Replace the stock desktop experience with a compact, polished launcher and cleaner session UI.
- Make household administration fast without turning the client into an RMM product.
- Support Full, Host, and Quick Support experiences from the same project.
- Ship preconfigured for a self-hosted RustDesk infrastructure while keeping advanced server configuration editable.

## Upstream

DeichDesk is based on the open-source RustDesk project and will track a pinned upstream baseline. Upstream changes are reviewed and merged into DeichDesk deliberately rather than consumed automatically.

RustDesk: https://github.com/rustdesk/rustdesk

## Status

Early development. See `docs/PRODUCT_SPEC.md` for the v1 product decisions and `docs/UPSTREAM.md` for the upstream integration strategy.

## License

RustDesk is licensed under AGPL-3.0. DeichDesk modifications and distributions must preserve the applicable AGPL-3.0 obligations, notices, and corresponding source availability.
