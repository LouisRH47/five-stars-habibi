# Browser builds and releases

Play at **https://fivestarshabibi.middleleap.com**. Press **Play in browser**, then
start or continue your shift. On a MacBook use the existing WASD/arrow controls.
On an iPad turn sideways; driving buttons appear when touch is available.
The first download is about 13 MB. Progress belongs to this browser/device;
clearing website data removes it. Saves do not sync between MacBook and iPad.

## Normal updates

1. Make changes on a branch and open a pull request.
2. **Browser build and release** imports the project, runs the gameplay and touch
   checks, exports the game, and saves a downloadable `browser-build` artifact.
   Pull requests cannot deploy and receive no Cloudflare credential.
3. Merge into `main`. A successful build deploys automatically to the address above.
   The workflow verifies `version.json` against the exact source commit and checks
   that the hosted engine decodes as valid WebAssembly.

The publishing credential must be configured before automatic deployments work:
repository **Settings → Secrets and variables → Actions → New repository secret**,
name `CLOUDFLARE_API_TOKEN`. It needs **Account / Cloudflare Pages / Edit**, limited
to Cloudflare account `33ea51185c20d9edd77e09be3690fc77`. Cloudflare currently scopes
this permission to the account, not an individual Pages project; it can affect
the other Pages sites in that account. Do not grant DNS, Workers, billing, or
other account permissions. Keep the token in GitHub's encrypted secret store,
never in source code. The account ID in the workflow is public configuration.

## Named releases

Push a tag such as `v0.1.0` on a reviewed commit containing this workflow:

```sh
git tag v0.1.0
git push origin v0.1.0
```

After tests and deployment pass, GitHub creates the named release with generated
notes, a browser ZIP, and its SHA-256 checksum. Tags are intended to stay fixed.
A rerun preserves an already published release's assets.

The ZIP is prepared for Cloudflare Pages, including `_headers`, `_routes.json`,
and the small `_worker.js` handler. Only `/index.wasm` uses the handler; other
files remain static. `index.wasm.gz` is stored without a Content-Encoding header.
The handler fetches its raw bytes and returns them as `application/wasm` with
`Content-Encoding: gzip` and the Workers `encodeBody: "manual"` option, so the
runtime does not compress the engine twice. After one HTTP gzip decode, the
response must begin with the WebAssembly bytes `00 61 73 6d`.
It is not a desktop executable or a file
to open directly in Finder. The uncompressed export is in `build/web` locally.

## Roll back or deploy a specific version

In **Actions → Browser build and release → Run workflow**, keep the workflow
branch on `main`, choose **production**, and set `source_ref` to a previous release tag or commit that
contains the browser build scripts. This rebuilds, checks, and deploys that
version. The next merge to `main` resumes normal updates. Cloudflare Pages also
keeps previous successful production deployments for an immediate dashboard rollback.

For a test deployment, choose **preview** and set `source_ref` to the branch or
commit to test. Its address is https://preview.five-stars-habibi.pages.dev;
this leaves Louis's production address unchanged.

## Local checks

Linux: `bash tools/install-godot.sh`, then `bash tools/build-web.sh`.

Mac: install Godot **4.7.2 stable** and matching export templates, then run:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot bash tools/build-web.sh
python3 -m http.server 8765 --directory build/web
```

Open http://localhost:8765. If Godot is elsewhere, change `GODOT_BIN`. Logs are
in `build/logs`. The build uses a temporary test save, leaving player progress
alone. In the Godot editor, open the project and press **F5** to verify the
desktop game still opens normally. The web-only renderer settings preserve
desktop Forward+.

## Hosting and device checks

- Cloudflare Pages project: `five-stars-habibi`; production branch: `main`.
- DNS: `fivestarshabibi.middleleap.com` points to `five-stars-habibi.pages.dev`.
- Single-threaded export; Compatibility renderer; Low graphics by default.
- No service worker in this first release, so refreshing checks for updates.
- Test Safari on a real MacBook and iPad, including a complete shift, save and
  reload, sound, multi-touch steering, and landscape layout. Browser emulation
  does not establish physical iPad performance.
- Schools may need to allow the domain and WebGL. Browser access still depends
  on the device and school network policies.

Godot downloads and Actions versions are pinned; the installer checks the official
engine/template SHA-256 digests. Update those pins deliberately when changing Godot.
