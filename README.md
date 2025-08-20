# loomory

### Immich submodule
#### Update Immich submodule
./scripts/update_immich.sh

#### After a new loomory clone or pull other devs MUST do
git submodule update --init --recursive


## Gotchas
- await ref.read(backgroundSyncProvider).syncLocal(full: true) just crashes with a platform signal error.
  This is called by an isolate and Permitted background task scheduler identifiers were not set.
  TODO: Don't forget to rename these once bundle identifier changes.

- Photo permission always return permanentlyDenied.
  Missing permissions config in Podfile

- Share extension config issue.
  ShareExtension requires additions for Podfile (and plist)
  TODO: ShareExtension App groups are NOT configured yet in Loomory.