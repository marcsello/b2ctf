# Build2CTF

A Garry's mod gamemode.

[![Build Status](https://drone.k8s.marcsello.com/api/badges/marcsello/b2ctf/status.svg)](https://drone.k8s.marcsello.com/marcsello/b2ctf)

Build2CTF (or b2ctf for short) is an attempt to mix CTF with Sandbox. The game is divided into to phases, in the "building" phase you can build whatever you want to prepare for the "war" phase, where you have to defend your team's flag and capture the flag(s) of the other team(s) by relying only on what you built.

## Game basics

Each map has predefined teams, and spots for those teams' bases. When you enter the game, you join a team in the classic Valve style of game.

The game is divided into two main phases (and two shorter ones).

During the "Building" phase, you are allowed to do everything you would be able to do in the simple Sandbox mode, but you are forced to stay within the boundaries of your team's spot. If you leave, you will take damage (or be killed instantly if you go too far), and any props or entities you move outside will be removed after a while. Unlike classic Sandbox, all spawn limits are team-based, so you must coordinate what you build with your team.

After building, there is a short period of time where you are no longer allowed to build, but can not leave the base just yet. You can use this time to prepare your team, take a break before the war, etc.

Then comes the "War" phase, in this phase you are not allowed to access the sandbox tools/menus, so essentially you cannot build any new construct, you can only use what you have already built. (If you left something frozen, you can unfreeze it, but that's it). During this phase, you can hurt your enemies and leave your base freely. This is the phase where the CTF game takes place, you have to take the enemy team's flag and bring it to your flag. You can only capture a flag if your flag isn't taken. You must also defend your own team's flag. (To avoid prop-blocking the flag, it is not allowed to move anything near the flag, things will just be pushed away from the flag)

After the war is over, there is a short "Intermezzo" where you no longer can hurt enemies or take flags/score points, but you are still free to leave your base. The winner of the round is also announced. During this phase, you should focus on bringing back everything to your team's base that you want to save for the next round, because after this phase, everything that's left outside of your team's base (even in other teams' bases) will be removed.

## Map support

Build2CTF has it's own system for defining teams, their base areas, spawn points, and flag positions for each map.

By default, a few maps are supported out of the box, as a default configuration for these maps are included in the gamemode files. Support for new maps, or overriding the built-in configurations is possible by dropping certain Lua files in a specific folder. [TODO: add docs link here.]

Currently, the following maps have configuration shipped with the gamemode:

- `gm_balkans_snow_avto`: Relatively large map for 4 teams, this is the map that originally inspired Build2CTF.
- `gm_flatgrass`: 3 tiny team areas next to each-other (this is more like a debugging setup for  easier development)

## Installing Quickstart

Currently, the recommended way of installing the gamemode on a server is via `git`, this saves everyone from the headache of dealing with Workshop. The gamemode is designed to not have any resource included, so players don't have to download anything upon joining.

All you have to do is clone this repository to your game server's `garrysmod/gamemodes` folder.

```
cd garrysmod/gamemodes
git clone https://github.com/marcsello/b2ctf.git
```

Basic configuration of the gamemode can be done using convvars. [TODO include docs link here.]

When starting your server, add the `+gamemode b2ctf` argument to the commandline to load b2ctf.

```
./srcds_run -console -game garrysmod +maxplayers 14 +map gm_flatgrass +gamemode b2ctf
```

And that's basically it.

## Development

Build2CTF is designed to be a solid foundation that anyone can customize the way they like. There are numerous configuration options, hooks, and APIs you can use to interface with the gamemode.

Even trough the gamemode is designed to only include the bare minimum that is needed to be a complete game, certain parts can be disabled or replaced to your liking. For a (somewhat) complete documentation see our [docs](https://b2ctf.marcsello.com/docs) page. If you still have any question feel free to open an [issue](https://github.com/marcsello/b2ctf/issues/new).

Pull requests are also highly appreciated!
