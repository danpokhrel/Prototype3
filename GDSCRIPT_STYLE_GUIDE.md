# GDScript Style Guide (Compressed)

Compressed from the official Godot documentation: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html

This project's rules are stricter than the official guide in places (doc comments on every class and function). The official guide is the base; those project rules apply on top.

## Complete example

```gdscript
class_name StateMachine
extends Node
## Hierarchical State machine for the player.
##
## Initializes states and delegates engine callbacks ([method Node._physics_process],
## [method Node._unhandled_input]) to the state.

signal state_changed(previous, new)

@export var initial_state: Node
var is_active = true:
	set = set_is_active

@onready var _state = initial_state:
	set = set_state
@onready var _state_name = _state.name


func _init():
	add_to_group("state_machine")


func _ready():
	state_changed.connect(_on_state_changed)
	_state.enter()


func _unhandled_input(event):
	_state.unhandled_input(event)


func _physics_process(delta):
	_state.physics_process(delta)


func transition_to(target_state_path, msg={}):
	if not has_node(target_state_path):
		return

	var target_state = get_node(target_state_path)
	assert(target_state.is_composite == false)

	_state.exit()
	self._state = target_state
	_state.enter(msg)
	Events.player_state_changed.emit(_state.name)


func set_is_active(value):
	is_active = value
	set_physics_process(value)
	set_process_unhandled_input(value)
	set_block_signals(not value)


func set_state(value):
	_state = value
	_state_name = _state.name


func _on_state_changed(previous, new):
	print("state changed")
	state_changed.emit()


class State:
	var foo = 0

	func _init():
		print("Hello!")
```

## Formatting

- **Line endings:** LF, one line feed at end of file. UTF-8, no byte order mark.
- **Indentation:** tabs, not spaces. Each indent level one greater than the containing block.
- **Continuation lines:** use 2 indent levels for wrapped expressions/conditions. Exception: arrays, dictionaries, and enums use a single indent level.
- **Trailing commas:** use on the last line of multi-line arrays, dictionaries, and enums. Not in single-line lists.
- **Blank lines:** two blank lines around functions and class definitions. One blank line inside functions to separate logical sections.
- **Line length:** under 100 characters; aim for under 80.
- **One statement per line.** No `if flag: print("flagged")`. The only exception is the ternary operator.
- **Multiline wrapping:** prefer parentheses over backslashes. Place `and`/`or` at the beginning of continuation lines:

```gdscript
var angle_degrees = 135
var quadrant = (
	"northeast" if angle_degrees <= 90
	else "southeast" if angle_degrees <= 180
	else "southwest" if angle_degrees <= 270
	else "northwest"
)
```

- **Avoid unnecessary parentheses** unless needed for order of operations or wrapping.
- **Boolean operators:** `and` instead of `&&`, `or` instead of `||`, `not` instead of `!`.
- **Comment spacing:** `#` and `##` comments start with a space; disabled code must not (`#print("This is disabled code")`). Prefer comments on their own line; inline comments only for short notes.
- **Whitespace:** one space around operators and after commas; no spaces in `dict["key"]` or `print("foo")`. Single-line dictionary declarations use `{ key = "value" }`. Don't align values vertically with spaces.
- **Quotes:** double quotes unless single quotes avoid escaping more characters in a given string.
- **Numbers:** don't omit leading/trailing zeros (`0.234`, `13.0`). Lowercase hex (`0xfb8c0b`). Use underscores for large numbers (`1_234_567_890`); skip them below ~1,000,000.

## Naming conventions

| Type | Convention | Example |
| --- | --- | --- |
| File names | snake_case | `yaml_parser.gd` |
| Class names | PascalCase | `class_name YAMLParser` |
| Node names | PascalCase | `Camera3D`, `Player` |
| Functions | snake_case | `func load_level():` |
| Variables | snake_case | `var particle_effect` |
| Signals | snake_case, past tense | `signal door_opened` |
| Constants | CONSTANT_CASE | `const MAX_SPEED = 200` |
| Enum names | PascalCase, singular | `enum Element` |
| Enum members | CONSTANT_CASE | `{EARTH, WATER, AIR, FIRE}` |

- File names for named classes convert the PascalCase class name to snake_case: `class_name Weapon` → `weapon.gd`.
- Prepend a single underscore to private functions and variables, and to virtual methods the user must override (`_recalculate_path()`).
- Enums: one item per line, with a trailing comma on the last item.

## Code order

Organize GDScript code this way:

```
01. @tool, @icon, @static_unload
02. class_name
03. extends
04. ## doc comment

05. signals
06. enums
07. constants
08. static variables
09. @export variables
10. remaining regular variables
11. @onready variables

12. _static_init()
13. remaining static methods
14. overridden built-in virtual methods:
    1. _init()
    2. _enter_tree()
    3. _ready()
    4. _process()
    5. _physics_process()
    6. remaining virtual methods
15. overridden custom methods
16. remaining methods
17. inner classes
```

Rules of thumb:
1. Properties and signals come first, followed by methods.
2. Public comes before private.
3. Virtual callbacks come before the class's interface.
4. `_init` and `_ready` come before functions that modify the object at runtime.

- Don't declare member variables that are only used locally in a method.
- Declare local variables as close as possible to their first use.
- `@onready` variables are evaluated right before `_ready` — use them to cache node dependencies.

## Static typing

**Project rule: follow the official static typing guide and avoid dynamic typing whenever possible.**

Official guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html

- Declare a variable's type as `var health: int`; declare return types as `func heal(amount: float) -> void:`. Type virtual methods too: `func _process(delta: float) -> void:`.
- Prefer `:=` when the type is written on the same line as the assignment and clearly inferred; otherwise write the type explicitly. Include the hint when the type is ambiguous, omit it when redundant:

```gdscript
var health: int = 0  # explicit; ambiguous otherwise
var direction := Vector3(1, 2, 3)  # inferred
var value := complex_function()  # bad — type not obvious to a reader
```

- Explicitly state the type when the compiler can't infer it (e.g. `get_node()`):

```gdscript
@onready var health_bar: ProgressBar = get_node("UI/LifeBar")
```

- Cast with `as` for full typing and autocompletion: `var player := body as PlayerController`. The `as` keyword silently casts to `null` on a type mismatch at runtime — when that behavior isn't intended, use an `is` check instead:

```gdscript
if body is not PlayerController:
	push_error("Bug: body is not PlayerController")
var player: PlayerController = body
```

- Type arrays and dictionaries: `var scores: Array[int] = [10, 20]`, `var vehicles: Dictionary[String, Node] = {...}`. Nested typed collections (`Array[Array[int]]`) are not supported.
- Prefer typed global scope methods over their dynamic counterparts: `absf`/`absi` over `abs`, `floorf`/`floori` over `floor`, `lerpf` over `lerp`, `roundf` over `round`, etc.
- Avoid `UNSAFE_PROPERTY_ACCESS`/`UNSAFE_METHOD_ACCESS` situations: check the type with `is`, then use a statically typed variable.

```gdscript
if node_2d is MyScript:
	var my_script: MyScript = node_2d
	my_script.some_function()
```

- Godot can't always infer types — the compiler falls back to `Node` for `get_node()` unless the scene is loaded. State the type explicitly in those cases.
