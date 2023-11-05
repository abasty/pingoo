# Sprites générators

* <https://sanderfrenken.github.io/Universal-LPC-Spritesheet-Character-Generator/>
* <https://retro-sprite-creator.nihey.org/character/new>
* <https://www.mmorpgmakerxb.com/p/characters-sprites-generator>
* <https://itch.io/c/1866035/pixel-art-generators>

# VSCode / Godot

* <https://github.com/godotengine/godot-vscode-plugin/issues/389>

* Dans VSCode installer le plugin Godot
* Dans Godot, ne pas cocher la case "Use External Editor" => On peut éditer
  conjointement dans VSCode et Godot, les fichiers sont synchronisés sur Ctrl+S.
* Dans Godot, activer _Debug > Deploy with remote debug_
* Voir le fichier `launch.json` dans ce projet

Si on lance par F5 dans Godot, on débogue dans Godot. Si on lance par F5 dans
VSCode, on débogue dans VSCode. Les _breakpoints_ sont synchronisés entre Godot
et VSCode.
