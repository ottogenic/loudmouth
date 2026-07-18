# Product Requirements Document: Loudmouth

## 1. Overview
**Loudmouth** is a World of Warcraft (WoW) Classic Era addon designed to inject personality into the gameplay experience. Instead of static chat, Loudmouth uses a personality-driven dialogue system that triggers context-aware messages based on the player's race, class, and current game state, simulating a "loudmouth" character who constantly comments on their surroundings.

## 2. Goals
- **Immersive Roleplay:** Provide a way for players to automate flavor text and personality-driven dialogue.
- **Dynamic Interaction:** Use game state detection to trigger relevant dialogue (e.g., a Dwarf Hunter talking about their pet).
- **Customizability:** Allow players to select from different "Personalities" and potentially create their own.
- **Compliance:** Ensure all functionality remains within the WoW Terms of Service (ToS) by focusing on chat/macros rather than gameplay automation.

## 3. Key Features

### 3.1 Personality System
- **Selection Menu:** A basic UI allowing users to choose a personality (e.g., "Quirky Dwarf Hunter").
- **Dialogue Libraries:** Each personality has a dedicated set of phrases categorized by trigger (e.g., combat start, target change, idle).

### 3.2 Macro Generator
- **Dynamic Macro Creation:** The addon will generate and execute macros that combine game logic with chat output.
- **Probability Engine:** A system to ensure dialogue doesn't trigger every time, making the "loudmouth" feel more natural and less like a bot.
- **Cooldown Management:** Internal timers to prevent chat spam and maintain a rhythmic flow of dialogue.

### 3.3 Game State Detection
- Integration with WoW API to detect:
    - Player/Target Race and Class.
    - Combat status.
    - Pet presence and status.

## 4. Technical Constraints
- **API:** Must use WoW Classic Era Lua API.
- **ToS Compliance:** No automation of combat rotations, movement, or gameplay decisions. Only `/say`, `/yell`, and `/emote` commands are permitted.
- **Performance:** Minimal impact on frame rate; efficient use of event listeners.

## 5. Roadmap

### Phase 1: Quirky Dwarf Hunter Pilot
- Implement core Lua logic for probability and cooldowns.
- Create a basic UI for personality selection.
- Develop the macro generator.
- Build the initial dialogue library for the Quirky Dwarf Hunter.

### Phase 2: Expansion
- Add support for additional personalities.
- Expand coverage to all classes and races.
- Implement pet-specific dialogue triggers.

### Phase 3: Polishing & Community
- Add Import/Export functionality for custom dialogue libraries.
- Performance optimization.
- Community sharing of personality profiles.
