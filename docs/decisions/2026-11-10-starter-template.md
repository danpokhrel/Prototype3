# Starter template — decisions

| Decision | Choice | Why | Revisit when |
|---|---|---|---|
| Scope | Foundation for future mechanics prototypes | "Starter/template" = base; matches semi-permanent prototypes rule | a prototype needs changes the base can't support |
| Multiplayer | Single-player only | Sidescroller mechanics prototyping needs no networking | a networked prototype is started |
| Resolution | 640×360 viewport, integer scaling, stretch mode `viewport` | Retro look, clean integer scaling to 1080p/1440p and browser sizes; flexible for prototyping (change in project.godot) | a prototype needs a different aspect ratio |
| Player mechanics | Built-in game feel: acceleration, variable jump height, coyote time, jump buffering — all `@export`-tunable | A template that feels dead is worse than none; tunable per prototype | a prototype wants raw movement |
| Player visuals | Colored rectangle (16×24 white PNG tinted via `modulate`), swap-ready | Retro prototyping placeholder; real art drops in without touching the scene | real art arrives |
| Level content | Flat floor + three platforms (no UI, no collectibles) | Minimal tuning-focused sandbox | a prototype needs more |
| UI | None | User decides; no UI rule applies | a prototype needs UI |
| Web export | Web preset in `export_presets.cfg`, export to `build/index.html` | Runs on web; CI exports on every push to main | a prototype needs a different export target |
| Export templates | Not installed locally; installed automatically in CI (`export-web.yml`) | Local export needs templates via Godot Editor → Manage Export Templates; CI downloads them each run | local exporting is wanted |

## Open / deferred
- Export templates: install via Godot Editor → Manage Export Templates, then `godot --headless --export-release "Web" build/index.html`.
- Godot version: 4.7.2 (project.godot `config/features`).
