# dubai-life-shorts

Public media hosting for the [@dubai_life_uae](https://youtube.com/@dubai_life_uae) YouTube Shorts (Dubai trip series).
Files are served through GitHub Pages so scheduling tools can fetch them by direct URL:

```
https://sadamdirvi-tech.github.io/dubai-life-shorts/dayN/clipM.mp4
```

## Layout
- `day1/clip1.mp4`, `day1/clip2.mp4`, `day1/clip3.mp4`: one folder per day, 3 Shorts per day (1080x1920, H.264/AAC)
- `scripts/add_day.sh N` (or `scripts/add_day.sh <folder> <src_dir>`): copies clips into the folder, pushes, waits for Pages, verifies URLs
- `day1v/`: voiceover + music versions of Day 1 (replacements use a new folder so the CDN never serves stale copies)

## Credits
Stock footage is from [Pixabay](https://pixabay.com) (Pixabay Content License). Per-clip author credits are in each video's YouTube description.
