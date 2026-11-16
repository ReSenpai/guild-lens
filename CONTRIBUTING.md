# Contributing to GuildLens

Thanks for taking a look. Bug reports, translations and pull requests are welcome.

## Licensing of contributions

GuildLens is licensed under the [GNU GPL v3.0 or later](LICENSE). By sending a pull request you agree that your
contribution is licensed under the same terms, and that you have the right to license it.

Sign your commits off with `git commit -s` (the [Developer Certificate of Origin](https://developercertificate.org/)),
which adds a `Signed-off-by` line to the commit message.

## How the repository is laid out

The repository root is the addon itself (the TOC files at the top), so it can be linked straight into the game:

```
mklink /J "C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\GuildLens" "<path>\guild-lens"
```

- `Core/` — start-up and settings, slash commands, the lines about a member, the options window.
- `Sources/` — the guild roster and the guild's community.
- `UI/` — the name menus, guild chat, and which member a menu is about.
- `Locales/` — the addon's own text.
- `Libs/` — the Ace3 libraries behind the options window.
- `tests/`, `tools/` — the checks below. Neither goes into the release zip.

How the modules fit together is described in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Data and privacy

GuildLens reads only what the client already knows about the guild, sends nothing and keeps no data about guild
members. Please keep it that way: no addon messages, no stored rosters. Bug reports and test data should not carry
real players' names.

## Translations

A new language is one more file in `Locales/` (like `ruRU.lua`, with the same keys as `enUS.lua`), added to both TOC
files after `Locales\ruRU.lua`. A language with names by sex may also give the female race names
(`ns.FemaleRaceNames`) and the default guild rank names (`ns.RankNames`), as `ruRU.lua` does.

## Working style

- Test in the game client (Classic Era 1.15 or Forever); code changes need `/reload`, new files a restart of the game.
- Run the checks before a pull request: `powershell -File tools/test.ps1` (Python with `lupa` and `luaparser`,
  e.g. `pip install --target .tools/pylib lupa luaparser`).
- Every string the player sees goes through `Locales/`.
- Don't move or change the game's own menu items; a field the game doesn't give is left out, not an error.
- Text files use LF line endings and UTF-8 (`.gitattributes`, `.editorconfig`).
