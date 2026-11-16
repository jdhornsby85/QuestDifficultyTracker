# Quest Difficulty Colors

A World of Warcraft: Forever addon that colors the quest icons on the world map to match
the color of the quest's title in your quest log — grey (trivial), green, yellow, orange,
red (much higher level). Red quests also get a small skull.

Each icon gets a colored ring, and the dots inside the icon are tinted the same color.

## Install

1. Copy the `QuestDifficultyColors` folder into
   `World of Warcraft\_forever_\Interface\AddOns\`
2. Restart the game or log out to character select, and make sure
   **Quest Difficulty Colors** is ticked in the AddOns list.
3. You'll see `QDC: loaded` in chat when it's running.

## Commands

| Command | What it does |
|---|---|
| `/qdc` | Show options |
| `/qdc halo` | Toggle the colored ring around icons |
| `/qdc icon` | Toggle tinting the icon itself |
| `/qdc skull` | Toggle the skull on red quests |
| `/qdc pins` | Debug: list the pin types on the open map |

Settings are saved per account.

## Compatibility

Built for WoW Forever (interface `16001`).
