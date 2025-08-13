# Loomory Flutter Project instructions

## Description
Loomory is a Photo sharing and curated memory app. It is build on top of the Immich project, which is a self-hosted photo and video backup solution.

## Project Structure & Naming
Loomory uses the full Immich mobile app as a package which is located in packages/immich/mobile.
Loomory itself is the app we are building.


## Key Principles
- packages/immich/mobile is a git submodule. Look there for details on how the Immich app works but
never change any code in the submodule.
- When building new features, preferrably use the packages we already have in Immich.
