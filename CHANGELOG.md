## 0.0.1

* Initial release.
* Fragment-shader–based halation effect with:
  * Progressive blur — strong at the edges, clear at the centre.
  * Dirty-lens overlay — a faint unblurred layer bleeds through for a real-lens feel.
  * Chromatic aberration — per-tap RGB split applied behind the blur so the fringe is thick and hazy.
  * Frost — fine two-octave noise with a cold tint and uniform darkening.
* `Halation` widget accepts any `ui.Image` as the background source, making it compatible with static images and per-frame video captures alike.
