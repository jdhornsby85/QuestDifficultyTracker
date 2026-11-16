# Quest Difficulty Colors

A World of Warcraft: Forever addon that colors the quest icons on the world map to match
the color of the quest's title in your quest log — grey (trivial), green, yellow, orange,
red (much higher level). Red quests also get a small skull.

Each icon gets a colored ring, and the dots inside the icon are tinted the same color.

## Install

Clone the repo somewhere outside the game folder, then get the `QuestDifficultyColors`
folder (the one inside this repo, not the whole repo) into your Forever AddOns folder:

```
C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\
```

You should end up with `AddOns\QuestDifficultyColors\QuestDifficultyColors.toc`.
WoW only loads an addon whose folder name matches its `.toc`, so don't copy the
`QuestDifficultyTracker` folder itself.

### Option 1: copy the folder (simplest)

1. Clone the repo:
   ```bash
   git clone https://github.com/jdhornsby85/QuestDifficultyTracker.git
   ```
2. Copy `QuestDifficultyTracker\QuestDifficultyColors` into the AddOns folder above.

To update later, `git pull` and copy the folder again.

### Option 2: link it, so updates are automatic

A directory junction makes the AddOns folder point at your clone, so after a
`git pull` you only need `/reload` in game.

1. Clone it somewhere permanent, e.g. `C:\Code`:
   ```bash
   git clone https://github.com/jdhornsby85/QuestDifficultyTracker.git C:/Code/QuestDifficultyTracker
   ```
2. If you already have a copied `QuestDifficultyColors` folder in AddOns, delete it first.
3. In Command Prompt (cmd), create the link:
   ```
   mklink /J "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\QuestDifficultyColors" "C:\Code\QuestDifficultyTracker\QuestDifficultyColors"
   ```

To update later:
```bash
git -C C:/Code/QuestDifficultyTracker pull
```

### First launch

1. The first time, log out to character select or restart the game (`/reload` doesn't
   pick up a brand-new addon folder), and make sure **Quest Difficulty Colors** is
   ticked in the AddOns list.
2. You'll see `QDC: loaded` in chat when it's running.
3. After that, `/reload` is enough to pick up changes.

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
