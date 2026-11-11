# Agents.md

Rules for AI agents working in this repository.

**Godot version: 4.7.2-stable** (`project.godot` features `"4.7"`, renderer `GL Compatibility`; CI pins the same version in `.github/workflows/export-web.yml`).

## Godot version accuracy

This project runs Godot 4.7. Your training data may contain Godot 3.x or early-4.x APIs that have since been renamed, removed, or changed — hallucinating them breaks the project. To minimize that:

- Treat the skills in `.agents/skills/` (written for Godot 4.3+) and the compressed guides at the project root (`GDSCRIPT_STYLE_GUIDE.md`, `GODOT_ARCHITECTURE.md`) as the primary API reference — not your memory.
- When you are not certain an API exists with that exact name and signature in Godot 4.7, verify before using it: search this project for existing usage, consult the skill references, or ask the user to confirm against the editor's built-in docs. Do not guess.
- Prefer patterns already used in this project's scripts and scenes over new ones.

This project is a Godot 2D game mechanics prototyping playground. Prototypes are treated as semi-permanent experiments: keep them working and functional once built, but don't over-engineer them.

## Godot MCP

Use the Godot MCP server instead of command line tools whenever possible. If the Godot MCP is not available, stop and tell the user to install it before proceeding.

## Scenes

Define scenes in the `.tscn` file. Avoid procedurally generating scenes in code whenever possible. Design scenes to be easy for humans to work with and modify in the godot editor.

## Modularity

Break scenes into reusable prefab scenes (`.tscn`) and instantiate them wherever node groups repeat. Never hand-copy the same node group into multiple places in one scene.

Extract subtrees where it makes sense for better architecture — not every subtree possible. A subtree is a good candidate when it is reused or repeated, or when it represents a distinct concept that benefits from its own scene (e.g. a player, an enemy, a UI panel). A subtree that is a single-use, structurally simple part of its parent scene (e.g. a background layer) is fine where it is. When in doubt whether to extract, ask the user.

## UI

Do not create the node tree for UI yourself. Godot UI is difficult for LLMs to work with, so have the user create the UI base, then build on top of it.

## Scripts

GDScript only. All scripts must follow the official GDScript style guide — a compressed version lives in `GDSCRIPT_STYLE_GUIDE.md` at the project root. Follow it on top of the project rules below:

- **Typing:** follow the official static typing guide (https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html) and avoid dynamic typing whenever possible. Prefer `:=` when the type is written on the same line as the assignment; otherwise write the type explicitly.
- **Doc comments:** every class and function needs a `##` doc comment.
- **Naming:** Godot default conventions — PascalCase for classes and nodes, snake_case for files, functions, variables, and signals.

## Architecture

Follow the official Godot architecture guides — a compressed version lives in `GODOT_ARCHITECTURE.md` at the project root (covers project organization and scene organization). Use it instead of the web docs:
- Project organization: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
- Scene organization: https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html

## Skills

This project has Godot skills installed in `.agents/skills/` (the cross-agent shared folder — OpenCode, Codex, Cursor, Gemini CLI, and Copilot all discover them). Load the relevant one with the `skill` tool when working on a matching task:

- **Process:** `godot-grill`, `godot-brainstorming`, `godot-code-review`, `godot-debugging`
- **Gameplay:** `player-controller`, `input-handling`, `camera-system`, `state-machine`
- **Motion & 2D:** `tween-animation`, `2d-essentials`, `physics-system`, `math-essentials`
- **Structure:** `scene-organization`, `component-system`, `resource-pattern`

Skills only add domain knowledge — this file's rules (Godot MCP, `.tscn` scenes, UI, user decisions) always take precedence.

## Git

Never push to the remote without the user's review and explicit permission. Committing locally is fine; pushing is not. Every push — including force-pushes and pushes of fixes to your own commits — needs the user to review what will be pushed and say yes first.

## Verification

After making changes, run the project and check for errors (use the Godot MCP's `run_project` and `get_debug_output`).

## User decisions

Do not make any decisions on your own. Grill the user on absolutely every single detail regarding what they want and how those wants should be implemented before acting.
