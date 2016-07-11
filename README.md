# Starbound Color Transform
Color Transform is tech mod that allows you to set up one or multiple color transformations for specified sets of colors.

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
 - [Setting up transformations](#setting-up-transformations)
 - [Activating transformations](#activating-transformations)
- [Using a different tech](#using-a-different-tech)
- [Planned](#planned)
- [Potential Issues](#potential-issues)
- [Contributing](#contributing)

## Installation
* [Download](https://github.com/Silverfeelin/Starbound-ColorTransform/releases) the release for the current version of Starbound.
* Place the `ColorTransform` folder in your mods folder (eg. `D:\Steam\steamapps\common\Starbound\mods\`).
 * Remove the existing folder beforehand if it already exists. It is recommended to save a copy of the `colorTransform.json` file before you do so.
* Activate the `dash` tech on your character.
 * In singleplayer, use `/enabletech dash` and `/spawnitem techconsole` with your cursor pointed near your character. Place the tech console down and activate the tech from the tech console.

#### Setting up transformations
To set up specific color transformations, you must first know what colors you want to transform. You can do so by using the color picker of whatever image editor you prefer ([Paint.NET](http://www.getpaint.net/index.html), [GIMP](https://www.gimp.org/), other).  
 * For character colors, you can print screen your character in your inventory.
 * For held items, it is recommended to create a screenshot while `/fullbright` is enabled.

Color transformations are defined in the `transformations` array found inside the `colorTransform.json` file. This file is located in the mod folder.

The expected parameters, for each transformation, are described below.
* `name` : Transformation name, as displayed in `/debug`.
* `duration` : Duration of the transformation, in game updates (60 updates per second by default).
* `colors` : Table containing transformation colors. The key of each table entry represents the original color, and the value represents the color it should transform into. Both values should be 6-digit hexadecimal color codes.
```json
  {
    "name" : "Blue",
    "duration" : 60,
    "colors" : {
      "CD1C38" : "199AFF",
      "982441" : "1377C4",
      "69243F" : "0E5891"
    }
  }
```

Don't forget that each table entry should be separated with a comma! You can confirm the syntax of the configuration by using a [JSON Linter](http://helmet.kafuka.org/sbmods/json/).

#### Activating transformations
By default, two keys are used by this tech mod: `G` and `H`.  
If you'd like to set up more specific activation keys, you can define them in the `colorTransform.json` file. Any [Keybinds-compatible syntax options](https://github.com/Silverfeelin/Starbound-Keybinds#syntax-options) are supported.

* `G` : Activate the currently selected transformation.
* `H` : Select the next transformation. This does not activate it.

Activating the same transformation twice will undo the transformation, over the same duration.  
You can see the selected transformation in `/debug`.

## Using a different tech
* Remove `/tech/dash/dash.lua` from the mod folder.
* Copy a different tech script from unpacked assets for the current version of the game.
 * The repository also has all the tech files. If these are up to date, you can simply download one, place it in the right location and ignore all other steps.
* Place the copied tech script in the mod folder. Make sure the file name and directories match up with those of the game assets (eg. `\assets\tech\jump\multijump.lua` to `\ColorTransform\tech\jump\multijump.lua`).
* Open the new tech script in a text editor of your choice.
* Start a new line following the line `function init()`, and place the code below on this new line.
```lua
require "/scripts/colorTransform.lua"
```
* Save the file.
* (Optional) Enable the new tech using `/enabletech <techname>` in singleplayer. Activate the tech through a tech console, obtainable by using the command `/spawnitem techconsole`.

## Planned
* Hueshift: Set up transformations that, when activated, shift the hue of defined colors over time.  
This would be much like the `?hueshift` directive, except you can choose which colors are affected.
* Transparency: Support for transparency in both the original and transformation colors.

## Potential Issues
* Activating transformation A, B, then A again means the first transformation will activate again, rather than deactivating. This means the transformation has to activated again to undo it.
* Transparency is not supported. Only the first 6 digits of color codes are used.
* The tech uses `tech.setParentDirectives(directives)` to apply the transformations. This happens every tick while a transformation is active. Any other tech scripts that call this function may overwrite the changes this tech attempts to make, or those changes may get overwritten by this tech.

## Contributing
If you have any suggestions or feedback that might help improve this mod, please do post them [on the discussion page]!
You can also create pull requests and contribute directly to the mod!
