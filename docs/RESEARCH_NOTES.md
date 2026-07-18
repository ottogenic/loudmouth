# Research Notes: WoW Classic Era API & Architecture

## 1. API Detection Functions
To drive the personality system, the following WoW API functions are primary for state detection:
- `UnitRace(unit)`: Returns the race of the specified unit.
- `UnitClass(unit)`: Returns the class of the specified unit.
- `UnitName(unit)`: Returns the name of the specified unit.
- `UnitExists(unit)`: Checks if a unit (e.g., "target", "pet") exists.
- `UnitCombatState(unit)`: Checks if the unit is currently in combat.
- `GetBaneOfGlory()` (and similar): Contextual checks for specific game states.

## 2. Terms of Service (ToS) & Compliance
**Critical Warning:** Automation of gameplay (combat rotations, movement, target selection) is a bannable offense.
- **Allowed:** Automating chat, emotes, and cosmetic macros.
- **Forbidden:** Any logic that provides a competitive advantage or removes the need for player input in gameplay.
- **Strategy:** Loudmouth strictly operates as a "Chat Overlay," triggering `/say` or `/yell` based on events, without influencing the player's actual actions.

## 3. Macro-Loop Architecture
The system will utilize a "Macro-Loop" design to handle dialogue triggers:
- **Event Listeners:** Use `WoW` events (e.g., `PLAYER_REGEN_DISABLED` for combat start) to trigger checks.
- **The Logic Gate:**
    1. **Event Triggered** $\rightarrow$ 2. **Check Cooldown** $\rightarrow$ 3. **Roll Probability** $\rightarrow$ 4. **Select Dialogue** $\rightarrow$ 5. **Execute Macro**.
- **Macro Execution:** Using `/run` commands or dynamically created macros to output text.
- **Cooldowns:** Implement a global and per-category cooldown (e.g., "Combat" dialogue can only happen every 30 seconds) to avoid spamming and detection as a bot.
