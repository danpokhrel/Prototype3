# Godot Architecture Guide (Compressed)

Compressed from the official Godot best practices guides:
- Project organization: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
- Scene organization: https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html

## Project organization

Godot is scene-based and uses the filesystem as-is, with no metadata or asset database. Many resources live inside the scene itself, so the filesystem has fewer files than other engines. Group assets as close to their scenes as possible — when a project grows, this stays maintainable.

### Naming

- **snake_case** for folder and file names. This sidesteps case-sensitivity issues when exporting from Windows (the PCK virtual filesystem is case-sensitive; Windows and macOS are case-insensitive by default).
- **PascalCase** for node names, matching built-in node casing.
- **C# scripts are the exception**: named after the class, in PascalCase.

### Third-party resources

Keep third-party resources in a top-level `addons/` folder, even if they aren't editor plugins — it makes third-party files easy to track. Exceptions: if third-party assets belong to a specific character or object, it makes more sense to keep them in that character's folder.

### Example layout

```
/project.godot
/docs/.gdignore          # See "Ignoring specific folders"
/docs/learning.html
/models/town/house/house.dae
/models/town/house/window.png
/characters/player/cubio.dae
/characters/player/cubio.png
/characters/enemies/goblin/goblin.dae
/characters/enemies/goblin/goblin.png
/levels/riverdale/riverdale.scn
```

### Ignoring specific folders

Create an empty file named `.gdignore` in a folder (the leading `.` is required; contents are ignored, no patterns) to prevent Godot from importing it. Ignored folders are hidden from the FileSystem dock and their resources can't be loaded with `load()`/`preload()`. Useful for docs and design assets that don't belong in the project.

## Scene organization

### Design scenes to have no dependencies

If at all possible, create scenes that keep everything they need within themselves. A scene that depends on its environment can inadvertently trigger bugs and unexpected behavior when reused in another context.

If a scene must interact with an external context, use **dependency injection**: expose the child's data and let the parent context initialize it. Parent-child relationships are the illustration; the same principles apply to all object relations. Siblings should only be aware of their own hierarchy — an ancestor mediates their communications and references. Whichever object owns the other objects manages the relationships between them.

1. **Connect to a signal.** Extremely safe, but only to "respond" to behavior, not start it. Signal names are past-tense verbs: `entered`, `skill_activated`, `item_collected`.

```gdscript
# Parent
$Child.signal_name.connect(method_on_the_object)
# Child
signal_name.emit()  # Triggers parent-specified behavior.
```

2. **Call a method.** Used to start behavior; the child must own the method.

```gdscript
# Parent
$Child.method_name = "do"
# Child
call(method_name)
```

3. **Initialize a Callable property.** Safer than a method — no ownership of the method required.

```gdscript
# Parent
$Child.func_property = object_with_method.method_on_the_object
# Child
func_property.call()  # Can come from anywhere.
```

4. **Initialize a Node or Object reference.**

```gdscript
# Parent
$Child.target = self
# Child
print(target)
```

5. **Initialize a NodePath.**

```gdscript
# Parent
$Child.target_path = ".."
# Child
get_node(target_path)
```

### Keeping data in-house

Favor keeping data internal to a scene: placing a dependency on an external context, even a loosely coupled one, means the node expects something in its environment to be true. Code that relies on external documentation to use it safely is error-prone by default.

When a dependency is unavoidable, make the scene self-document instead: convert the dependent node into a `@tool` script implementing `_get_configuration_warnings()`. Returning a non-empty `PackedStringArray` makes the Scene dock show a warning icon with the strings as a tooltip — the same mechanism `Area2D` uses when it has no `CollisionShape2D`. The editor self-documents the scene; no documentation duplication is needed.

### OOP principles apply to scripts and scenes

- **SOLID** — single responsibility; open for extension, closed for modification; Liskov substitution; interface segregation; dependency inversion.
- **DRY** — don't repeat yourself.
- **KISS** — keep it simple.
- **YAGNI** — you aren't gonna need it.

### Choosing a node tree structure

A game should always have an entry point — the "Main" node — where you can definitively track where things begin, and a bird's-eye view of all other data and logic.

```
- Node "Main" (main.gd)
  - Node2D/Node3D "World" (game_world.gd)
  - Control "GUI" (gui.gd)
```

`main.gd` is the primary controller of the game. When changing levels, swap out the children of "World" — changing scenes manually gives full control over transitions.

Create an **autoload singleton** when a system:

1. tracks all of its data internally,
2. should be globally accessible,
3. should exist in isolation.

For smaller games, a simpler alternative is a "Game" singleton that calls `SceneTree.change_scene_to_file()` to swap out the main scene's content. Any GUI must be a singleton, a transitory part of the "World", or a manually added direct child of the root — otherwise it deletes itself during scene transitions.

If you have systems that modify other systems' data, define those as their own scripts or scenes, rather than autoloads.

### Parent-child relationships

Each gameplay subsystem should have its own section within the SceneTree. Use parent-child relationships only where nodes are effectively elements of their parents: **does removing the parent reasonably mean the children should also be removed?** If not, the node belongs elsewhere in the hierarchy as a sibling or some other relation.

**When to separate nodes that must also position themselves relative to each other:** use `RemoteTransform` / `RemoteTransform2D` to let a target node conditionally inherit selected transform elements. Assign the `target` NodePath via a reliable third party (likely a parent) or a group.

**The player room problem:** when a "player" node lives inside a "room" and the room must be deleted, the player needs special handling. This is a special case that must be documented and maintained — a maintenance burden. In a larger game, keep the player somewhere else in the SceneTree entirely, for consistency, no special cases, and no opportunity for errors.

**Nodes that must not inherit a parent's transform:**

1. **Declarative:** place a plain `Node` in between — it has no transform to pass down.
2. **Imperative:** set `top_level = true` on the `CanvasItem`/`Node3D` to make it ignore its inherited transform.

### The key principle

Consider the SceneTree in **relational terms rather than spatial terms**. Are the nodes dependent on their parent's existence? If not, they can thrive by themselves somewhere else. If they are dependent, they should be children of that parent (and likely part of that parent's scene).

Node trees form an **aggregation relationship, not one of composition** — you still have the flexibility to move nodes around, but it's best when such moves are unnecessary by default.
