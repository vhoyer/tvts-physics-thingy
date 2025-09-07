# godot-devkit

## Installation

Make sure to run this command on the root folder of your Godot project.

```bash
git remote add devkit git@github.com:veshworks/godot-devkit.git
git fetch devkit
git subtree add --prefix addons/godot-devkit devkit main --squash
```

## Updating addon

```bash
git subtree pull --prefix addons/godot-devkit devkit main --squash
```


## Contributing back to upstream

Make sure all changes to this add-on are committed separated (like `git add
addons/godot-devkit`, otherwise the subtree push will not really work
properly).

```bash
git subtree push --prefix addons/godot-devkit devkit main
```
