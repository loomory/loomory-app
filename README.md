# loomory

### Update Immich 
#### Update Immich submodule
./scripts/update_immich.sh

#### Update Immich server
In the server folder run:
docker compose pull && docker compose up -d

#### After a new loomory clone or pull other devs MUST do
git submodule update --init --recursive


## Gotchas
- await ref.read(backgroundSyncProvider).syncLocal(full: true) just crashes with a platform signal error.
  This is called by an isolate and Permitted background task scheduler identifiers were not set.

- Unable to establish connection on channel: "dev.flutter.pigeon.immich_mobile.ThumbnailApi.requestImage"., null, null) or similar.
  Probably a new native implementation has been added, in iOS we symlink to Sync and Images. If more native things are added, things will blow up until we fix a new symlink (or worse). For Android, we have nothing like this yet so expect issues.
  Example: When standing in the ios/Runner folder symlink to Images in Immich: ln -s ln -s ../../packages/immich/mobile/ios/Runner/Images Images
  Then in iOS choose Add new files, select the symlinked directory and choose to reference the files (do not copy them).

- Photo permission always return permanentlyDenied.
  Missing permissions config in Podfile

- Share extension config issue.
  ShareExtension requires additions for Podfile (and plist)
  TODO: ShareExtension App groups are NOT configured yet in Loomory.

- Immich includes a bunch of header files in AppDelegate.swift. If an obj-c value is not found, make sure Immich
  has not added more included in AppDelegate.h. I think normally this is done in the briding header but let's copy
  what they do.