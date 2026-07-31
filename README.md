# Zelia-Android

A minimal Android chat client for [ZELIA](https://github.com/Zexolver/Zelia),
the local voice+text assistant. Talks to ZELIA's `remote_bridge.py` HTTP
server over [Tailscale](https://tailscale.com) (or any private network the
phone and ZELIA's machine both share), so you can text her from anywhere,
not just standing at the machine.

Not on the Play Store &mdash; install via [Obtainium](https://github.com/ImranR98/Obtainium)
pointed at this repo's [Releases](../../releases), or download an APK
directly and sideload it.

## Setup

1. On the ZELIA machine, enable the bridge in `config.yaml`:
   ```yaml
   remote_bridge:
     enabled: true
     port: 8899
     token: "<generate with: python3 -c 'import secrets; print(secrets.token_urlsafe(32))'>"
   ```
   Restart ZELIA (`systemctl --user restart zelia`) after.
2. Install [Tailscale](https://tailscale.com) on both the ZELIA machine and
   your phone, log in to the same account on both.
3. Open the app, go to Settings, enter `http://<tailscale-ip-of-zelia-machine>:8899`
   and the token from step 1. "Test connection" to confirm, then Save.
4. Chat.

## Building

```
flutter pub get
flutter build apk --release
```

Or push a `vX.Y.Z` tag &mdash; the GitHub Actions workflow in
`.github/workflows/release.yml` builds and attaches an APK to a new Release
automatically, which is what Obtainium tracks.

## Status

Text chat only for now. Voice, and registering as an Android
[Assistant app](https://developer.android.com/develop/ui/views/appwidgets/interactive-widgets/voice-interaction)
(so ZELIA can be set as the default assistant), are both planned but not
built yet.
