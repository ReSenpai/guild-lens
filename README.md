# GuildLens

**Who is that in guild chat? Level, class, rank and more about a guildmate, right in the menu of their name.**

**English** · [Русский](README.ru.md) · [Architecture](docs/ARCHITECTURE.md)

Someone in guild chat asks for help, and you wonder: what level are they, which class, are they an officer, where are
they? Right-click their name: below the game's own menu items GuildLens shows what the guild roster knows about them.
No need to open the guild window and scroll through hundreds of names.

[![Latest release](https://img.shields.io/github/v/release/ReSenpai/guild-lens?label=Release&logo=github)](https://github.com/ReSenpai/guild-lens/releases/latest)
[![WoW Classic Era](https://img.shields.io/badge/WoW-Classic%20Era%201.15-c79c6e)](#compatibility)
[![WoW Forever](https://img.shields.io/badge/WoW-Forever-c79c6e)](#compatibility)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

## What does it do?

### The menu of a guildmate's name

Right-click a name in guild chat, in the guild window's member list or in the guild window's own chat. At the end of
the menu, after a divider:

```
[icon] Hunter, level 24
Race: Night Elf, female
Rank: Officer
Status: online
Zone: Redridge Mountains
Professions: Herbalism, Mining
Note: main tank of the raid
```

- **Class** in its colour, with its icon, and the **level** — always.
- **Race** (and sex, where the game tells it), **rank**, **status** (online, away, busy; for those offline, when they
  were last seen), **zone** (for those offline, where they were last), **professions** and the public **note** — each
  can be turned off in the options.
- The game's own menu items stay where they are and work as before: GuildLens only adds lines below them.
- Names outside the guild, and other channels, are left alone.

### Guild chat

Optionally, guild chat lines can show the sender's class icon, level and zone in place of `[Guild]`:
`[<icon>24, Redridge Mountains] [Name]: hello`. Each part is its own option, and all of them are off by default:
guild chat stays as the game shows it until you tick something. The tag stays clickable like `[Guild]` was. Officer
chat keeps its name.

### Options

`/glens` (or `/guildlens`) opens the options window; it is also in the AddOns tab of the game options.
`/glens help` lists the commands, `/glens status` shows how many guild members the roster has.

## Privacy

Everything comes from what your game client already knows about your guild: the guild roster and the guild's
community. GuildLens sends nothing to anyone, talks to no other addon and keeps no data about guild members in its
saved variables. The one exception is `/glens debug`, off unless you turn it on: it records what the last few name
menus carried, names included, for a bug report, and forgets it when turned off.

## Installation

1. Download `GuildLens-v<version>.zip` from the [latest release](https://github.com/ReSenpai/guild-lens/releases/latest).
2. Unpack it into `World of Warcraft\_classic_era_\Interface\AddOns` (or `_forever_` for Forever). You should get the
   folder `Interface\AddOns\GuildLens`.
3. Restart the game and check on the character screen, under AddOns, that GuildLens is enabled.

To remove it, delete the `Interface\AddOns\GuildLens` folder.

## Compatibility

- **Classic Era** (1.15): `GuildLens_Vanilla.toc`.
- **Classic Forever**: `GuildLens.toc`.

The addon's own text is in English and Russian. Class, race, zone and profession names come in the client's language;
the default guild rank names (Guild Master, Officer, Veteran, Member, Initiate) are translated, ranks a guild named
itself are shown as they are. The game tells a member's professions but not their skill.

## How it works

- `Sources/GuildRoster.lua` — the guild roster, by name and by GUID.
- `Sources/GuildClub.lua` — what the guild's community knows beyond the roster: race and professions.
- `UI/ChatResolver.lua` — which guild member a menu is about.
- `Core/Lines.lua` — builds the lines about a member.
- `UI/ContextMenu.lua` — adds them to the game's name menus; `UI/GuildChat.lua` — the guild chat tag.
- `Core/Options.lua` — the options window; `Libs/` — the Ace3 libraries behind it.

The details: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

Checks: `powershell -File tools/test.ps1` parses the Lua files and runs a smoke test against stubbed game APIs in
English and Russian, as a modern and as an older client (needs Python with `lupa` and `luaparser`, e.g.
`pip install --target .tools/pylib lupa luaparser`).

Releases: raise `## Version` in both TOC files and add a section for it to `CHANGELOG.md`; once that is on `main`,
`.github/workflows/release.yml` tags it and the [BigWigs packager](https://github.com/BigWigsMods/packager) builds
the zip and publishes it on GitHub. Pull requests are checked by `.github/workflows/checks.yml`.

## License

GuildLens is free software under the [GNU General Public License v3.0](LICENSE) or later; see [NOTICE](NOTICE) for
what it covers and the libraries it ships. Contributions are welcome, see [CONTRIBUTING](CONTRIBUTING.md).

GuildLens is an unofficial fan project, not affiliated with or endorsed by Blizzard Entertainment.
