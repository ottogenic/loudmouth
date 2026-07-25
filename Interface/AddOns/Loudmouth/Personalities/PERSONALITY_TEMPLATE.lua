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
-- EXAMPLE:  DwarfFemaleHunterQuirky.lua
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
    -- LIKES TABLE (place and entity preferences for banter)
    -- ==================================================================
    -- Each personality can define what they like and hate about places and entities.
    -- Case-insensitive substring matching is used for all comparisons.
    -- Hates takes precedence over Likes when multiple traits match.
    --
    -- Places: list of zone/subzone substrings that trigger banter when present.
    -- Entities: list of target name/class/race substrings that trigger banter.
    --
    -- Trait-specific dialogue is defined under the Lines table below.
    -- ==================================================================
    Likes = {
        Places = {
            -- Example: zone/subzone substrings
            -- "Lake",
            -- "Water",
            -- "Beach",
        },
        Entities = {
            -- Example: target name/class/race substrings
            -- "Gnome",
            -- "Gnomes",
        },
    },
    Hates = {
        Places = {
            -- Example: zone/subzone substrings
            -- "Ironforge",
            -- "Dwarfs",
        },
        Entities = {
            -- Example: target name/class/race substrings
            -- "Dark Iron",
            -- "Dwarf",
        },
    },

    -- ==================================================================
    -- SUBZONES TABLE (keyword-match subzone dialogue)
    -- ==================================================================
    -- Keys are substrings.  When GetSubZoneText() contains the key
    -- (case-insensitive partial match), the engine picks a random line.
    --
    -- Subzones are implemented by the core engine. A subzone check happens once
    -- per pending location visit; matched entries pick a random line directly.
    -- ==================================================================
    subzones = {
        -- Example entries (replace with subzones relevant to your character):
        -- ["Elwynn Forest"] = {
        --     lines = {
        --         "The forest is peaceful today.",
        --     },
        -- },
    },

    -- ==================================================================
    -- LINES TABLE (trait-specific dialogue)
    -- ==================================================================
    -- Each personality can define dialogue that triggers when the player's
    -- current zone/subzone or target matches their Likes or Hates traits.
    --
    -- Structure: Lines.<Polarity>.<Context>.<Trait> or Lines.<Polarity>.<Context>.Generic
    --   Polarity: "Likes" or "Hates"
    --   Context: "Places" or "Entities"
    --   Trait: matched trait string from Likes/Hates table, or "Generic" for fallback
    --
    -- Priority chain:
    --   1. Place traits (zones/subzones) are checked before action traits
    --   2. Hates lines take precedence over Likes lines when multiple traits match
    --   3. Entity lines are action-specific (use action key) or Generic fallback
    --
    -- Example: Ironforge (hates Dwarfs)
    --   Likes.Places = { "Lake" }
    --   Hates.Places = { "Ironforge", "Dwarfs" }
    --   Lines.Hates.Places["Ironforge"] = {
    --       "Smells like feet and malt liqour... Dwarfs are disgusting.",
    --   }
    --
    -- Example: Casting Shadowbolt on Dark Iron Dwarf
    --   Hates.Entities = { "Dark Iron", "Dark Iron Dwarf", "Dwarf" }
    --   Lines.Hates.Entities["Dark Iron Dwarf"]["Shadow Bolt"] = {
    --       "I hope this burns the hair of your ugly dwarf feet!",
    --   }
    --
    -- Example: Casting Shadowbolt on Leper Gnome (generic entity fallback)
    --   Likes.Entities = { "Gnome", "Leper Gnome" }
    --   Lines.Likes.Entities["Leper Gnome"]["Generic"] = {
    --       "Gnomes are adorable!",
    --   }
    -- ==================================================================
    Lines = {
        Likes = {
            Places = {
                -- Example: trait-specific lines for place matches
                -- ["Lake"] = {
                --     "Ohhh, the water is so pretty! Wonder if we can get a boat ride?",
                -- },
            },
            Entities = {
                -- Example: trait-specific lines for entity matches
                -- ["Gnome"] = {
                --     Generic = {
                --         "Gnomes are adorable!",
                --     },
                -- },
                -- ["Leper Gnome"] = {
                --     Generic = {
                --         "Gnomes are adorable!",
                --     },
                -- },
            },
        },
        Hates = {
            Places = {
                -- Example: trait-specific lines for place matches
                -- ["Ironforge"] = {
                --     "Smells like feet and malt liqour... Dwarfs are disgusting.",
                -- },
            },
            Entities = {
                -- Example: action-specific entity lines
                -- ["Dark Iron Dwarf"] = {
                --     ["Shadow Bolt"] = {
                --         "I hope this burns the hair of your ugly dwarf feet!",
                --     },
                --     Generic = {
                --         "Dwarfs are so annoying.",
                --     },
                -- },
                -- ["Dwarf"] = {
                --     Generic = {
                --         "Dwarfs are so annoying.",
                --     },
                -- },
            },
        },
    },
}

-- ============================================================================
-- TRIGGER() PRIORITY CHAIN (for reference when writing dialogue)
-- ============================================================================
--
-- When Trigger(action) is called by a macro button, the engine follows
-- this priority order:
--
--   1. PENDING ZONE COMMENT (100% when queued)
--      If a zone comment is queued (the player just entered a new zone),
--      it is spoken first with 100% probability.
--
    --   2. EXACT ZONE MATCH / ALIAS MATCH
--      If the current zone (GetRealZoneText()) matches a key in the
--      `zones` table, a random zone line is selected and spoken.
    --      Pending major-zone lines trigger once at 100% when matched.
--
--   3. SUBZONE KEYWORD MATCH
--      If GetSubZoneText() contains a key from `subzones`, a random subzone
--      line is selected and spoken once for that location visit.
--
--   4. ACTION ROLL
--      The engine looks up the action name in `actions[action]`.
--      It rolls math.random() against actionData.weight.  If the roll
--      succeeds, a random line from `lines` is sent to chat.
--      If the action is not found, it falls back to `actions["Generic"]`.
--
    --   5. COOLDOWN CHECK
--      Each action has its own per-action cooldown (Loudmouth.CooldownTime,
--      default 5 seconds).  If the action was triggered recently, the
--      entire chain is skipped for that action.
--
-- DESIGN NOTE:
--   Keep action weights low (e.g. 1/100 to 1/500) for combat spells so
--   the character doesn't speak every time a button is pressed.
--   Keep consumable weights higher (e.g. 1/5 to 1) since they're
--   used less frequently.
--   Always include "Generic" with weight = 1 as a safety net.
-- ============================================================================
