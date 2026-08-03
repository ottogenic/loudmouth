-- ============================================================================
-- Loudmouth Personality Template
-- ============================================================================
-- FILENAME FORMAT: <Race><Gender><Class><Variant>.lua
--   <Race>    — NightElf | Human | Dwarf | Undead | Orc | Tauren | Gnome | Troll
--   <Gender>  — Male | Female
--   <Class>   — Warrior | Paladin | Hunter | Rogue | Priest | Shaman | Mage |
--               Warlock | Druid
--   <Variant> — freeform descriptor (e.g. Quirky, Professional, Grumpy)
--
-- EXAMPLE:  HumanFemaleWarlockProfessional.lua
--           HumanFemaleWarlockProfessional.lua
--
-- This file is a STATIC TEMPLATE.  Copy it, rename it to match the format above,
-- fill in the data, and drop it into Interface/AddOns/Loudmouth/Personalities/.
-- Do NOT add any executable logic — only data tables.
-- ============================================================================

Loudmouth = Loudmouth or {}
Loudmouth._RawPersonalities = Loudmouth._RawPersonalities or {}

Loudmouth._RawPersonalities["<Race><Gender><Class><Variant>"] = {

    -- ==================================================================
    -- LIKES / HATES (optional context-aware dialogue)
    -- ==================================================================
    -- Zone traits match race/vibe metadata from ClassicMetadata.lua. They do
    -- not contain dialogue. Use every matching trait when authoring the exact
    -- zone/subzone lines below; hated traits control the overall tone when a
    -- location matches both a like and a hate.
    -- Entity keys match the target's name, race, class, and creature type.
    -- Matching is case-insensitive; hates win when both polarities match.
    -- Entity `weight` is its speaking probability; omit it to inherit the
    -- triggering action's weight.
    -- ==================================================================
    likes = {
        zones = { "graveyard", "cave" },
        entities = {
            -- ["gnome"] = {
            --     weight = 1 / 20,
            --     lines = { "Oh, you're so cute!" },
            -- },
        },
    },

    hates = {
        zones = { "dwarf" },
        entities = {
            -- ["dwarf"] = {
            --     weight = 1 / 20,
            --     lines = { "This one is for every terrible dwarven ale." },
            -- },
        },
    },

    -- ==================================================================
    -- ACTIONS TABLE
    -- ==================================================================
    -- Each key is an action / spell name that can trigger dialogue. Macro
    -- creation order is centralized in Loudmouth.ActionOrderByClass, not in
    -- personality files.
    --
    --   weight  — probability of speaking (0..1).  1 = always, 1/10 = 10%,
    --             1/100 = 1%, etc.
    --   lines   — array of dialogue strings.  One is chosen at random.
    --
    -- REQUIRED: Include a "Generic" action (weight = 1) as a fallback.
    -- NOTE: Zone/subzone entries do NOT have weights — the engine selects
    --       a random line directly when a zone match fires.
    -- ==================================================================
    actions = {
        -- Example: a spell action
        -- ["Shadow Bolt"] = {
        --     weight = 1 / 100,   -- ~1% chance per press
        --     lines = {
        --         "Shadow Bolt — a gift from the void.",
        --         "Feel the darkness take hold.",
        --         "One bolt, one corpse.",
        --     },
        -- },

        -- Example: a consumable / utility action (higher weight)
        -- ["Healing Items"] = {
        --     weight = 1,           -- always attempt to speak
        --     lines = {
        --         "Time for a healthstone.",
        --         "Patch up and keep moving.",
        --     },
        -- },

        -- REQUIRED: Generic fallback (used when no specific action matches)
        -- Every bucket MUST have at least 3 lines.
        ["Generic"] = {
            weight = 1,
            lines = {
                "I should keep my eyes open.",
                "Steady now. One step at a time.",
                "Nothing wrong with a careful look around.",
            },
        },
    },

    -- ==================================================================
    -- ZONES TABLE (exact-match zone dialogue)
    -- ==================================================================
    -- Keys are exact zone names as returned by GetRealZoneText().
    -- When the player enters a matching zone, the engine selects one of
    -- the lines at random and sends it to chat.
    --
    -- To find the exact zone name, print GetRealZoneText() in-game or
    -- check the WoW wiki.
    -- ==================================================================
    zones = {
        -- Example entries (replace with zones relevant to your character):
        -- ["Stormwind"] = {
        --     lines = {
        --         "Stormwind's walls are impressive.",
        --         "A city of light. How quaint.",
        --     },
        -- },
    },

    -- ==================================================================
    -- SUBZONES TABLE (keyword-match subzone dialogue)
    -- ==================================================================
    -- Parent-zone keys may contain exact/substring subzone entries. This is
    -- preferred for tailored comments and prevents duplicate subzone names
    -- from crossing zones. Flat keyword entries remain available as neutral
    -- fallback comments for broad features such as inns.
    --
    -- Subzones are implemented by the core engine. A subzone check happens once
    -- per pending location visit; matched entries pick a random line directly.
    -- ==================================================================
    subzones = {
        -- ["Dun Morogh"] = {
        --     ["The Grizzled Den"] = {
        --         -- Likes caves + hates dwarves: acknowledge both, hate wins.
        --         lines = { "A fine cave ruined by the smell of wet dwarves." },
        --     },
        -- },
        -- Example entries (replace with subzones relevant to your character):
        -- ["Elwynn Forest"] = {
        --     lines = {
        --         "The forest is peaceful today.",
        --     },
        -- },
    },
}

-- ============================================================================
-- TRIGGER() PRIORITY CHAIN (for reference when writing dialogue)
-- ============================================================================
--
-- When Trigger(action, targetUnit) is called by a macro button, the engine follows
-- this priority order:
--
--   1. PENDING LOCATION COMMENT (100% when queued)
--      New-zone events select an exact/alias `zones` entry. Subzone events
--      select a parent-scoped or flat-keyword `subzones` entry. If both are
--      pending, the zone is spoken first and the subzone remains queued.
--
--   2. COOLDOWN CHECK
--      Each action has its own per-action cooldown (Loudmouth.CooldownTime,
--      default 5 seconds). Pending location comments are checked before it.
--
--   3. TARGET ENTITY MATCH / ACTION ROLL
--      Target name, race, class, and creature type are matched against
--      `hates.entities`, then `likes.entities`. A matching line replaces the
--      normal action line but uses the same probability and cooldown.
--
--   4. ACTION FALLBACK
--      The engine looks up the action name in `actions[action]`.
--      It rolls math.random() against actionData.weight.  If the roll
--      succeeds, a random line from `lines` is sent to chat.
--      If the action is not found, it falls back to `actions["Generic"]`.
--
-- AUTHORING NOTE:
--   `likes.zones` and `hates.zones` guide each exact location's authored
--   lines; they are not separate runtime dialogue pools.
--
-- DESIGN NOTE:
--   Keep action weights low (e.g. 1/100 to 1/500) for combat spells so
--   the character doesn't speak every time a button is pressed.
--   Keep consumable weights higher (e.g. 1/5 to 1) since they're
--   used less frequently.
--   Always include "Generic" with weight = 1 as a safety net.
-- ============================================================================
