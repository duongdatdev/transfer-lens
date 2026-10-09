# Cloudflare Pages mobile demo

**Production URL:** https://transfer-lens.pages.dev/

The site is a responsive HTML/CSS/JavaScript preview with fictional transactions,
category suggestions, an animated distribution chart, the real native demo video
and direct links to the signed Android APK. It is not a Flutter web build: ML Kit
image recognition and SQLite persistence run in the native Android app. Preview
records are held only in tab memory and reset on reload. No user data is sent to a
backend by the preview.

## Preview locally

From the repository root, stage the static files and selected native screenshots:

```powershell
python scripts/prepare_site.py
python -m http.server 8765 --bind 127.0.0.1 --directory output/site
```

Open `http://127.0.0.1:8765/`. If `output/demo/transfer-lens-demo.mp4` exists, the
preparation script also stages it as `output/site/demo.mp4`. On a fresh checkout,
download the published video after running the preparation script:

```powershell
curl.exe --fail --location --retry 3 --output output/site/demo.mp4 https://github.com/duongdatdev/transfer-lens/releases/download/v1.1.0/transfer-lens-demo.mp4
```

The large APK stays on GitHub Releases; the website links to that signed artifact.

## Deploy with Wrangler

Wrangler is installed globally on the development machine and authenticated to the
existing Cloudflare account. No Cloudflare credentials are stored in this project.
`wrangler.jsonc` defines the Pages project and staged asset directory.

```powershell
wrangler pages deploy output/site --project-name transfer-lens --branch main
wrangler pages deployment list --project-name transfer-lens
```

The `transfer-lens` project uses Direct Upload and the production branch `main`.
Deployments are published explicitly with Wrangler; pushing GitHub alone does not
redeploy the website. Validate the staging files before deploying and use the
stable production URL in the submission form.

## Install on mobile

1. Open the production URL in an Android browser.
2. Tap **Tải APK cho Android**, then open the downloaded `app-release.apk`.
3. If requested by Android, allow installation from that browser, then install.

iPhone/iPad can open the preview and play the video but cannot install an APK.
If an in-app browser blocks downloads, open the page in the phone's main browser.

## References

- [Cloudflare Pages Direct Upload and Wrangler deployment](https://developers.cloudflare.com/pages/get-started/direct-upload/)
