# loomory

### Immich submodule
#### After a new loomory clone
git submodule update --init --recursive

#### Update Immich submodule
cd packages/immich
git pull origin main
cd ../..
git add packages/immich
git commit -m "Update Immich submodule to latest"