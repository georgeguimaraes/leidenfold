# Changelog

## [0.4.1](https://github.com/georgeguimaraes/leidenfold/compare/v0.4.0...v0.4.1) (2026-09-15)


### Continuous Integration

* Find the NIF where rustler 0.38 puts it and allow rebuilding a tag's assets ([#25](https://github.com/georgeguimaraes/leidenfold/issues/25)) ([91c3124](https://github.com/georgeguimaraes/leidenfold/commit/91c312459884e908df2bde89fd10ac4d250f67d0))
* Upload only files from the artifacts directory ([#29](https://github.com/georgeguimaraes/leidenfold/issues/29)) ([9458492](https://github.com/georgeguimaraes/leidenfold/commit/945849251b3041bad822811b0de17b0fc291b61c))
* Upload release assets with gh instead of softprops ([#28](https://github.com/georgeguimaraes/leidenfold/issues/28)) ([91f68fe](https://github.com/georgeguimaraes/leidenfold/commit/91f68fe65255372eda940f1cdba8d9fad11b649e))
* Upload release assets with RELEASE_PAT ([#27](https://github.com/georgeguimaraes/leidenfold/issues/27)) ([6a3b11d](https://github.com/georgeguimaraes/leidenfold/commit/6a3b11dd14da2330d515312ca63f181a43e6c7fd))

## [0.4.0](https://github.com/georgeguimaraes/leidenfold/compare/v0.3.2...v0.4.0) (2026-09-15)


### ⚠ BREAKING CHANGES

* **deps:** Require Elixir 1.18, bump rustler to 0.38 and test on Elixir 1.20 / OTP 29 ([#21](https://github.com/georgeguimaraes/leidenfold/issues/21))

### Bug Fixes

* mark release PR as tagged after creating tag ([e909da7](https://github.com/georgeguimaraes/leidenfold/commit/e909da79ca6c755382cadaaac8c6e4a5cf92cad4))


### Miscellaneous

* add dependabot config ([285cc8f](https://github.com/georgeguimaraes/leidenfold/commit/285cc8fcc5af13dfe04ff88ce275ffe5bc643425))
* Add the release-please manifest ([#22](https://github.com/georgeguimaraes/leidenfold/issues/22)) ([6618f1c](https://github.com/georgeguimaraes/leidenfold/commit/6618f1c002670b02e5c5ad39e8b79f0efa387194))
* **deps-dev:** bump ex_doc from 0.39.3 to 0.40.0 ([#8](https://github.com/georgeguimaraes/leidenfold/issues/8)) ([b791b11](https://github.com/georgeguimaraes/leidenfold/commit/b791b11be9e1e076483d1293f9e6eeb7232be605))
* **deps-dev:** bump ex_doc from 0.40.0 to 0.40.1 ([#9](https://github.com/georgeguimaraes/leidenfold/issues/9)) ([6a75452](https://github.com/georgeguimaraes/leidenfold/commit/6a754521cd582618df4f659800f94c84b973d3f1))
* **deps:** bump actions/cache from 4 to 5 ([#6](https://github.com/georgeguimaraes/leidenfold/issues/6)) ([f2eab02](https://github.com/georgeguimaraes/leidenfold/commit/f2eab024d1a3092798440028f6f00fe1faf5c6c3))
* **deps:** bump actions/checkout from 4 to 6 ([#3](https://github.com/georgeguimaraes/leidenfold/issues/3)) ([b8e094c](https://github.com/georgeguimaraes/leidenfold/commit/b8e094cc8d04da0cedb872b594780b4b7396bbfb))
* **deps:** bump actions/download-artifact from 4 to 7 ([#4](https://github.com/georgeguimaraes/leidenfold/issues/4)) ([91bcd34](https://github.com/georgeguimaraes/leidenfold/commit/91bcd342387bfeb5a50eb832b46c9d7fe8c8b8eb))
* **deps:** bump actions/download-artifact from 7 to 8 ([#11](https://github.com/georgeguimaraes/leidenfold/issues/11)) ([5d73165](https://github.com/georgeguimaraes/leidenfold/commit/5d731658315c2ca1e5f0611a7d05598350452dab))
* **deps:** bump actions/upload-artifact from 4 to 6 ([#5](https://github.com/georgeguimaraes/leidenfold/issues/5)) ([4640984](https://github.com/georgeguimaraes/leidenfold/commit/4640984e42d9531bb00fc66821811d727b224429))
* **deps:** bump actions/upload-artifact from 6 to 7 ([#12](https://github.com/georgeguimaraes/leidenfold/issues/12)) ([2b05c5d](https://github.com/georgeguimaraes/leidenfold/commit/2b05c5d79456a3aca5f0de1ac79efdde6a9c7a69))
* **deps:** bump rustler from 0.36.2 to 0.37.1 ([#7](https://github.com/georgeguimaraes/leidenfold/issues/7)) ([b0b07ad](https://github.com/georgeguimaraes/leidenfold/commit/b0b07ad63ff9e5b3ae213032545b7ffba25f953e))
* **deps:** bump rustler from 0.37.1 to 0.37.3 ([#10](https://github.com/georgeguimaraes/leidenfold/issues/10)) ([fd377a8](https://github.com/georgeguimaraes/leidenfold/commit/fd377a8cdcd8f5068f5c86f8d34e24a779ffe536))
* **deps:** bump rustler_precompiled from 0.8.4 to 0.9.0 ([#13](https://github.com/georgeguimaraes/leidenfold/issues/13)) ([6426170](https://github.com/georgeguimaraes/leidenfold/commit/64261707c5474e672447040cd1ddc9a9fae42f1b))
* **deps:** bump softprops/action-gh-release from 1 to 2 ([#2](https://github.com/georgeguimaraes/leidenfold/issues/2)) ([9be82dd](https://github.com/georgeguimaraes/leidenfold/commit/9be82dd821b2edb1628d309a57c802bdaac97b01))
* **deps:** bump softprops/action-gh-release from 2 to 3 ([#14](https://github.com/georgeguimaraes/leidenfold/issues/14)) ([1337776](https://github.com/georgeguimaraes/leidenfold/commit/1337776e7e8593e99d4b54769e9ac765148c6d06))
* **deps:** Require Elixir 1.18, bump rustler to 0.38 and test on Elixir 1.20 / OTP 29 ([#21](https://github.com/georgeguimaraes/leidenfold/issues/21)) ([c83c1a4](https://github.com/georgeguimaraes/leidenfold/commit/c83c1a44a166ef857bfc38dbe18ae7215168e581))
* trigger release-please ([87e1154](https://github.com/georgeguimaraes/leidenfold/commit/87e1154d7de4c5c6d5f93d6a89586cb8d4089d6d))
* Update checksums for v0.3.2 ([7e109cd](https://github.com/georgeguimaraes/leidenfold/commit/7e109cdf7f9a6034a20211912c1fddfd7cb3f2c8))
* Update checksums for v0.3.2 ([26351a0](https://github.com/georgeguimaraes/leidenfold/commit/26351a076aa6a6d324886a2f90d2fe14a00032e5))


### Code Refactoring

* **ci:** use release-please for GitHub releases ([800d995](https://github.com/georgeguimaraes/leidenfold/commit/800d9958c8ddf1e44bff83b7ba98b78aa64046db))


### Continuous Integration

* Build and publish releases on OTP 27 / Elixir 1.18 ([#24](https://github.com/georgeguimaraes/leidenfold/issues/24)) ([c400f97](https://github.com/georgeguimaraes/leidenfold/commit/c400f976aae8361e152219ea9c1fa21fea4fd7f0))
* use shared workflows from georgeguimaraes/workflows ([ae81201](https://github.com/georgeguimaraes/leidenfold/commit/ae812010a97cf4b666bcdcf6630057f0c8b63b23))

## [0.2.0](https://github.com/georgeguimaraes/leidenfold/compare/v0.1.5...v0.2.0) (2026-01-05)


### Features

* Add Linux ARM64 and Windows targets ([20cddeb](https://github.com/georgeguimaraes/leidenfold/commit/20cddeb9d4a751012dd224d9cb840d8c101329d7))


### Bug Fixes

* Add contents:write permission to CI workflow ([3ecbfd3](https://github.com/georgeguimaraes/leidenfold/commit/3ecbfd35a1e547d8574aee85d5bfff3998663652))
* Hardcode versions in workflow_call (env not available in with:) ([055086e](https://github.com/georgeguimaraes/leidenfold/commit/055086e86bc8851f831b2d1bf10261182226daa9))
* Pin Windows runner to windows-2022 ([9769440](https://github.com/georgeguimaraes/leidenfold/commit/9769440d75acbc34d1dddde0f4d89048a60ec225))
