# Security policy

## Supported versions

Only the latest release on the [Releases](https://github.com/ReSenpai/guild-lens/releases) page (and on CurseForge)
gets fixes.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Report it privately through
[GitHub's private vulnerability reporting](https://github.com/ReSenpai/guild-lens/security/advisories/new) with what
you found, how to reproduce it and what it could affect.

You can usually expect a first answer within a week. Once a fix is released, the advisory is published with credit to
you, unless you prefer otherwise.

Things of particular interest: anything that could make the addon run code from its saved variables or from text it
shows (a name, a guild note), take protected actions or cause errors in combat, break the game's own menus, or reveal
what a player is not allowed to see (such as officer notes).
