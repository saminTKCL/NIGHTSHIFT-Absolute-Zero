# NIGHTSHIFT: Absolute Zero

> A 2.5D cinematic puzzle-platformer in a brutalist sub-zero atmospheric processing facility.

## Web Export & Vercel Deployment via GitHub

Yes, since `vercel.json` and the `.gitignore` are properly set up, this repository works perfectly for GitHub → Vercel deployment!

### How to deploy:

1. **Push to GitHub**:
   Commit everything and push to a new GitHub repository.

2. **Wait for Godot Export locally (or via CI)**:
   Note: Vercel's standard environment doesn't include the Godot editor, so you can't *build* the game on Vercel's servers by default. You have two options:
   
   - **Option A (Easy):** Export the game locally from Godot into `export/web/`, then **remove** the `/export` line from `.gitignore` and commit the `export/web` folder to GitHub. Vercel will simply serve those static files.
   - **Option B (Advanced):** Set up a GitHub Action to run the Godot headless export (using a Docker image like `barichello/godot-ci`), which pushes the built files to a `gh-pages` or deployment branch that Vercel listens to.

3. **Link Vercel to GitHub**:
   - Go to Vercel
   - Import your GitHub repository
   - Since `vercel.json` is at the root, Vercel will automatically configure the correct `SharedArrayBuffer` Cross-Origin headers and use the pre-built `export/web` directory.

## Controls

| Action | Key |
|--------|-----|
| Move | A/D or ←/→ |
| Jump | Space or W or ↑ |
| Interact | E |
| Pause | Escape |
