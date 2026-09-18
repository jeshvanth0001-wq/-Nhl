# TG ECET 2027 ECE App — Phone-only APK build

This version is prepared for GitHub Actions. The workflow automatically generates the missing Android platform files before building the APK.

## Phone steps
1. Create a GitHub repository.
2. Upload the project files to the repository root. Make sure `.github/workflows/build-apk.yml` is present.
3. Open **Actions**.
4. Select **Build Android APK**.
5. Tap **Run workflow** and choose `main`.
6. When the run succeeds, open the run and download the artifact `tg-ecet-2027-ece-apk`.

Do not upload the ZIP as a single file. Upload the files/folders inside the project so `pubspec.yaml`, `lib/`, `data/`, and `.github/workflows/build-apk.yml` are at the repository root.
