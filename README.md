# Stray the Squire
## a Godot 3.5 Slay The Spire clone
==========

**Extremely early proof-of-concept, NOT playable beyond a combat mockup**

Aiming for a Nintendo Switch homebrew release primarily, with Windows, Linux and Web also available as options.

No binaries until I have something worth showing, but you can view the current state of things via the web demo: https://hokaze.github.io/Stray-The-Squire/index.html

Powered by BraindeadBZH's CardEngine: https://github.com/BraindeadBZH/godot_card_engine

Nintendo Switch homebrew support initially thanks to Stary's 3.5.1 port of Godot, with later builds using the 3.5.3 continued from the Homebrodot team:
https://github.com/Stary2001/godot
https://github.com/Homebrodot/godot/

*(currently using some card stats from Slay the Spire for proof-of-concept demonstration + testing, will replace with original card stats later)*


## Implemented
*(this list is likely incomplete)*

- basic combat demo with 2 enemies, working deck/discard/exhaust piles, drag & drop, targeting, attacks and skills, some basic mechanics (hp, block, damage, vulnerable, weak, exhaust)
- replaced placeholder text display of player/enemy stats with placeholder icons, proper health bars, enemy intent icons, buff/debuff icons
- player and enemies both have basic wind-up -> attack animations and display for inflicting damage (or subtracting block) that is timed to display on the "impact" of the animation
- modified CardEngine Deck Builder to be able to save/load from a system store, as well as user store - means I can create decks the game itself uses with the same tool used to make a player's custom decks and they save differently (former in project space, latter in userdata space)
- scrollable viewer for deck, discard and exhaust piles
- player/enemy debuffs tick down and modify damage appropriately (WIP: some slight bugs with this and a few cases where the display doesn't reflect the modified damage from weak/vulnerable)


## Work In Progress
*(this list is likely incomplete)*

- controller/keyboard support - have fiddled with this so cards are now focusable by keyboard (much earlier pre-vcs versions used hidden buttons as a workaround for "focusing" cards), but cannot play them properly yet as there's no way of targeting the player / a specific enemy with keyboard/controller yet
- statuses/conditions: Vulnerable and Weak are implemented, but nothing else yet, and no buffs (so enemy intent buff icon goes unused), need to add something like Strength and Dexterity at a minimum
- clean-up code: better than it was, stuff's slowly being moved into proper classes and split into several functions, but there's still a lot of copied code (instead of inheritance) and the combat demo scene's gdscript file still hosts far too much of the logic for player-enemy-card interactions
- enemy intents: currently placeholder enemies have 2 intents each and cycle between them in order, but it's very simplistic at the moment


## TODO
*(this list is likely incomplete)*

- map: no traversable map, random generation, or non-combat state yet
- events: need a scene for special invents with text + options to take
- shop: likely needs a custom scene
- variable numbers of enemies: currently combat scene can only have a static number, ideally need a way to not only allow arbitrary number + placement, but a way to properly add/remove enemies, like several of the minion summoners do
- proper images: still using very crude placeholders (the card art is slightly better, but still needs replacing)
- enemy data: current placeholder enemies have hard-coded stats, need to setup a data store for enemy types, names, intents, images, etc
- enemies don't display their names (or indeed, have names yet)
- hover text explaining things like enemy intents and what a given status condition does (also needs to be viewable by keyboard/controller navigation)
- replace Slay the Spire cards from Ironclad with original cards


## Known Bugs

- trying to save a deck to Sys will likely not work (as that's for dev usage from having the actual project downloaded, and shouldn't be ran from the executable or the Web release)
- weakened enemies seem to be doing less damage than their intent indicates (possibly getting that 0.75x multiplier applied twice?)
- sometimes cards don't drag and drop properly the first time (i.e. you can drag them but, none of the drop areas register as a valid placement), seems to be more frequent if you drag by the bottom half of the card and/or do so before the start of turn draw-from-deck process has finished
- cards viewed in the card_list (as seen on deck/discard/exhaust view, or the deck builder) get clipped slightly if hovered over, as they grow slightly bigger on hover and go outside the bounds of their container (might just disable hover animation for the card_list container, as this problem is present in the CardEngine template project too)