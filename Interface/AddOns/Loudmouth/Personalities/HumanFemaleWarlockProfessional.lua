Loudmouth = Loudmouth or {}
Loudmouth._RawPersonalities = Loudmouth._RawPersonalities or {}

Loudmouth._RawPersonalities["HumanFemaleWarlockProfessional"] = {
    -- Per-personality abbreviation table.
    -- Each entry maps an action key to a short, unique uppercase abbreviation.
    -- If a spell is missing here, MakeMacroName falls back to the heuristic.
    abbrevs = {
        ["Shadow Bolt"]        = "SHBT",
        ["Immolate"]           = "IMLT",
        ["Corruption"]         = "CRPT",
        ["Curse of Weakness"]  = "CWRK",
        ["Curse of Agony"]     = "CSGN",
        ["Curse of Recklessness"] = "CRCK",
        ["Curse of Tongues"]   = "CTGN",
        ["Curse of the Elements"] = "CELE",
        ["Curse of Shadow"]    = "CSDW",
        ["Curse of Doom"]      = "CDOM",
        ["Searing Pain"]       = "SRPN",
        ["Rain of Fire"]       = "RNFN",
        ["Hellfire"]           = "HLFN",
        ["Soul Fire"]          = "SLFR",
        ["Drain Life"]         = "DRFL",
        ["Drain Mana"]         = "DRMN",
        ["Life Tap"]           = "LTAP",
        ["Fear"]               = "FR",
        ["Howl of Terror"]     = "HTRR",
        ["Summon Imp"]         = "SIMP",
        ["Summon Voidwalker"]  = "SVKD",
        ["Summon Succubus"]    = "SSCB",
        ["Summon Felhunter"]   = "SFLH",
        ["Banish"]             = "BNSH",
        ["Death Coil"]         = "DTCL",
        ["Inferno"]            = "IFNR",
        ["Eye of Kilrogg"]     = "EKLK",
        ["Unending Breath"]    = "UBTH",
        ["Demon Armor"]        = "DMAR",
        ["Soulstone"]          = "SLST",
        ["Subjugate Demon"]    = "SDMN",
        ["Ritual of Doom"]     = "RTDD",
        ["Healing Items"]      = "HLTM",
        ["Generic"]            = "GRIC",
        ["Demon Skin"]         = "DMKN",
        ["Drain Soul"]         = "DRSL",
    },

    actions = {
        ["Shadow Bolt"] = {
            weight = 1 / 100,
            lines = {
                "Shadow Bolt — a gift from the void.",
                "Feel the darkness take hold.",
                "That's the sound of a soul breaking.",
                "One bolt, one corpse.",
                "The shadows hunger. Let them feed.",
            },
        },
        ["Immolate"] = {
            weight = 1 / 100,
            lines = {
                "Burn, little worm.",
                "Felfire consumes all.",
                "You're already ash — you just haven't noticed yet.",
                "A slow, agonizing blaze.",
                "The flames of the nether do not discriminate.",
            },
        },
        ["Corruption"] = {
            weight = 1 / 100,
            lines = {
                "Savor the decay.",
                "A slow, agonizing end.",
                "Your soul is already mine.",
                "The corruption takes root. Watch it bloom.",
                "Life fades. Corruption remains.",
            },
        },
        ["Curse of Weakness"] = {
            weight = 1 / 50,
            lines = {
                "Let the shadows sap your strength.",
                "You'll struggle to lift that sword.",
                "Weakness is a curse — and a gift.",
                "Feel your muscles wither.",
                "The void saps your vigor.",
            },
        },
        ["Curse of Agony"] = {
            weight = 1 / 50,
            lines = {
                "Feel the burn of the void!",
                "Scream for me!",
                "Absolute agony, isn't it?",
                "Every heartbeat is a fresh torment.",
                "The agony will not stop. It never does.",
            },
        },
        ["Curse of Recklessness"] = {
            weight = 1 / 50,
            lines = {
                "Make a mistake, and pay for it.",
                "Your aim wavers. Your guard drops.",
                "Recklessness is the path to an early grave.",
                "Let the curse cloud their judgment.",
                "Foolishness, amplified.",
            },
        },
        ["Curse of Tongues"] = {
            weight = 1 / 2,
            lines = {
                "Your words mean nothing to them now.",
                "Let them struggle to understand.",
                "A small curse. A large advantage.",
                "Language is a barrier I happily enforce.",
                "They'll never guess your next move.",
            },
        },
        ["Curse of the Elements"] = {
            weight = 1 / 50,
            lines = {
                "The elements themselves conspire against you.",
                "Nature's fury, directed at your flesh.",
                "Let the elements teach you humility.",
                "Fire, frost, earth, and air — all against you.",
                "The elements are not your friends.",
            },
        },
        ["Curse of Shadow"] = {
            weight = 1 / 50,
            lines = {
                "Shadow consumes all light.",
                "The void sees you clearly now.",
                "Darkness is my domain.",
                "Shadows cloak their weakness.",
                "In shadow, there is no escape.",
            },
        },
        ["Curse of Doom"] = {
            weight = 1 / 200,
            lines = {
                "Doom approaches. You can feel it.",
                "A countdown to oblivion.",
                "The shadows whisper your end.",
                "Doom is not a threat. It is a promise.",
                "When the timer runs out, you will cease.",
            },
        },
        ["Searing Pain"] = {
            weight = 1 / 100,
            lines = {
                "Searing pain, just for you.",
                "Feel the heat of the nether!",
                "Pain is a teacher. I am a generous professor.",
                "That should leave a mark.",
                "Searing pain. Lasting memory.",
            },
        },
        ["Rain of Fire"] = {
            weight = 1 / 100,
            lines = {
                "Let the fire rain down.",
                "A storm of flame. Dance if you can.",
                "The ground itself burns beneath you.",
                "Rain of fire — a classic.",
                "Every drop is a spark of the void.",
            },
        },
        ["Hellfire"] = {
            weight = 1 / 200,
            lines = {
                "Hellfire cleanses all.",
                "The nether erupts. Feel its wrath.",
                "Self-immolation is a small price for victory.",
                "Burn in the fire of a thousand demons.",
                "Hellfire knows no mercy.",
            },
        },
        ["Soul Fire"] = {
            weight = 1 / 100,
            lines = {
                "Your soul is the fuel.",
                "A bolt of pure void energy.",
                "Soul Fire — devastating and beautiful.",
                "The fire that consumes the soul.",
                "One shot. One kill. That is the way.",
            },
        },
        ["Drain Life"] = {
            weight = 1 / 100,
            lines = {
                "Your vitality flows to me.",
                "Sustenance, taken freely.",
                "I grow stronger as you grow weaker.",
                "A sip of life from your cup.",
                "The life force is a river. I am the dam.",
            },
        },
        ["Drain Mana"] = {
            weight = 1 / 100,
            lines = {
                "Your magic is mine now.",
                "Empty your well, fill my own.",
                "Mana is a finite resource. I am its collector.",
                "Every spell you cast drains you further.",
                "The void always collects its due.",
            },
        },
        ["Life Tap"] = {
            weight = 1 / 100,
            lines = {
                "A small price for power.",
                "Tap into the life force. Yours.",
                "Magic demands sacrifice. You are the sacrifice.",
                "I'll take a sip of your mana, thanks.",
                "Life for power. A fair trade.",
            },
        },
        ["Fear"] = {
            weight = 1 / 5,
            lines = {
                "Terror has a face. It's mine.",
                "Run. Run while you still can.",
                "Fear is the most potent weapon.",
                "Let panic take hold.",
                "The darkness whispers your deepest fears.",
            },
        },
        ["Howl of Terror"] = {
            weight = 1 / 1,
            lines = {
                "Terror for the whole party!",
                "Let them hear the howl of the void.",
                "Panic spreads like wildfire.",
                "A cacophony of dread.",
                "Howl of terror — the sound of their courage breaking.",
            },
        },
        ["Summon Imp"] = {
            weight = 1 / 1,
            lines = {
                "Come forth, little imp.",
                "A tiny demon with a big attitude.",
                "Imps are useful. Mostly for distractions.",
                "The smallest demon can cause the biggest chaos.",
                "Imp, report for duty!",
            },
        },
        ["Summon Voidwalker"] = {
            weight = 1 / 1,
            lines = {
                "Voidwalker, stand between us and death.",
                "A bulwark of shadow and stone.",
                "The voidwalker will absorb their blows.",
                "Tank duty falls to the void.",
                "A voidwalker does not flinch. Neither should you.",
            },
        },
        ["Summon Succubus"] = {
            weight = 1 / 1,
            lines = {
                "Succubus, charm them into submission.",
                "Beauty and danger — the succubus combo.",
                "Let the succubus do what she does best.",
                "Charm is a weapon. She wields it well.",
                "Succubus, go. Enchant them.",
            },
        },
        ["Summon Felhunter"] = {
            weight = 1 / 1,
            lines = {
                "Felhunter, silence them.",
                "A hunter that hunts spellcasters.",
                "The felhunter devours magic.",
                "No spell will save them from the felhunter.",
                "Felhunter — the bane of every mage.",
            },
        },
        ["Banish"] = {
            weight = 1 / 2,
            lines = {
                "Banished to the void where you belong.",
                "Back to where you came from.",
                "Banishment is a temporary inconvenience.",
                "The void claims its own.",
                "Banish. Contain. Survive.",
            },
        },
        ["Death Coil"] = {
            weight = 1 / 100,
            lines = {
                "Death Coil — the touch of the grave.",
                "Feel the chill of death.",
                "A coil of death wraps around their soul.",
                "Death Coil never misses. It always finds you.",
                "The grave is closer than you think.",
            },
        },
        ["Inferno"] = {
            weight = 1 / 200,
            lines = {
                "Inferno — a storm of destruction.",
                "The nether erupts in fury.",
                "Inferno cleanses the battlefield.",
                "Let the inferno rage.",
                "Inferno: because one fire is never enough.",
            },
        },
        ["Eye of Kilrogg"] = {
            weight = 1 / 10,
            lines = {
                "Eye of Kilrogg — see all, miss nothing.",
                "Reave reveals all secrets.",
                "The Eye sees what others cannot.",
                "Scout ahead. The Eye will guide us.",
                "Kilrogg's eye pierces the veil of deception.",
            },
        },
        ["Unending Breath"] = {
            weight = 1 / 10,
            lines = {
                "Unending breath — for the depths ahead.",
                "Breathe easy. The void provides.",
                "Water holds no terror for a warlock.",
                "Unending breath. Endless determination.",
                "The depths are no obstacle.",
            },
        },
        ["Demon Armor"] = {
            weight = 1 / 10,
            lines = {
                "Demon Armor. The void protects.",
                "Let the armor of the damned shield me.",
                "Dark armor. Darker intentions.",
                "The void lends its strength.",
                "Armor of the demon. Power of the warlock.",
            },
        },
        ["Soulstone"] = {
            weight = 1 / 10,
            lines = {
                "Soulstone — a second chance at life.",
                "Your soul is preserved. For now.",
                "A soulstone is insurance against folly.",
                "Soulstone ready. Don't waste it.",
                "The stone holds your soul. Guard it well.",
            },
        },
        ["Subjugate Demon"] = {
            weight = 1 / 10,
            lines = {
                "Submit, demon. I am your master now.",
                "Subjugate — bend the will of any demon.",
                "Even demons kneel before a true warlock.",
                "The subjugation is complete.",
                "A demon's will is no match for mine.",
            },
        },
        ["Ritual of Doom"] = {
            weight = 1 / 200,
            lines = {
                "The Ritual of Doom begins.",
                "Five souls for one death.",
                "A ritual that demands sacrifice.",
                "Ritual of Doom — the end is certain.",
                "The void demands five souls. Let the ritual begin.",
            },
        },
        ["Healing Items"] = {
            weight = 1,
            lines = {
                "Healthstone on cooldown. Stay sharp.",
                "A healthstone is worth a thousand spells.",
                "Consume the healthstone. Live to fight again.",
                "Healing items at the ready. Survival first.",
                "The healthstone is a warlock's best friend.",
                "Take the stone. Patch up. Keep moving.",
            },
        },
        ["Generic"] = {
            weight = 1,
            lines = {
                "Amateurs. All of them.",
                "The arcane is but a tool for the truly gifted.",
                "I could rewrite your destiny with a snap of my fingers.",
                "The void whispers. I listen.",
                "Patience. The kill will come.",
                "Every battle is a lesson in power.",
            },
        },
        ["Demon Skin"] = {
            weight = 1 / 5,   -- passive aura swap, not every button press
            lines = {
                "Show some respect for the void.",
                "The darker your skin, the harder you fall.",
                "Armor of shadow, fortitude of hellfire.",
            },
        },
        ["Drain Soul"] = {
            weight = 1 / 100, -- endgame nuke
            lines = {
                "Your essence... mine.",
                "Siphoning what remains.",
                "Feel that drain? That's death, slowly.",
                "Every last drop.",
            },
        },
    },

    zones = {
        -- Starting Zones (Alliance)
        ["Goldshire"] = {
            weight = 0.10,
            lines = {
                "Just a logging camp. Boring. Though the innkeeper pours a decent draught.",
            },
        },
        ["Stormwind City"] = {
            weight = 0.12,
            lines = {
                "The nobility strut around as if they invented order. Typical human vanity.",
                "They fear anything they can't tax or decree away.",
            },
        },
        ["Elwynn Forest"] = {
            weight = 0.10,
            lines = {
                "Trees. Everywhere. Humans prefer their forests sheltered.",
                "The wild is far more... productive when left to rot.",
            },
        },
        ["Darnassus"] = {
            weight = 0.10,
            lines = {
                "Night Elf arrogance in flesh and bark. They hide from history",
                "while it catches up to them.",
            },
        },
        ["Teldrassil"] = {
            weight = 0.10,
            lines = {
                "A floating tree. The futility of trying to climb your way",
                "to the heavens.",
            },
        },
        -- Mid-Level Hubs & Dark Places
        ["City of Ironforge"] = {
            weight = 0.15,
            lines = {
                "Home sweet home. The stone works have excellent acoustic",
                "properties, and the dwarves seem to drink with enough passion",
                "to rival a cult gathering.",
                "The Great Forge is admirably efficient—heat, industry, and just enough danger to feel familiar.",
                "Ironforge's stonework is impeccable. Even the summoning chambers could learn a thing or two.",
            },
        },
        ["Iron Forge"] = {
            weight = 0.15,
            lines = {
                "The Great Forge never sleeps, and neither do the dwarves who",
                "work it. A spectacle of industry and soot.",
            },
        },
        ["Dwarven Halls"] = {
            weight = 0.15,
            lines = {
                "The halls beneath Ironforge are a marvel of stonework and",
                "engineering, though the acoustics are rather dreadful.",
            },
        },
        ["Dun Morogh"] = {
            weight = 0.15,
            lines = {
                "Cold and damp. Perfect conditions for an imp.",
                "And those dwarves—honestly, the only civilized creatures",
                "in the Alliance.",
            },
        },
        ["Loch Modan"] = {
            weight = 0.10,
            lines = {
                "Thelsamar is a forge town, but it lacks the artistic spark",
                "of Ironforge's streets. It is simply... heavy industry.",
            },
        },
        ["Westfall"] = {
            weight = 0.10,
            lines = {
                "Furlbrow's farm is a tragic reminder of what happens",
                "when you underestimate the void.",
            },
        },
        ["Duskwood"] = {
            weight = 0.15,
            lines = {
                "Now *this* is a landscape I appreciate. Twilight Grove",
                "isn't much, but Darkshire knows how to handle its dead.",
            },
        },
        ["Swamp of Sorrows"] = {
            weight = 0.12,
            lines = {
                "Stonard is mud, filth, and despair. It is beautiful.",
            },
        },
        ["Badlands"] = {
            weight = 0.12,
            lines = {
                "Kargath is surrounded by caverns. Do you have any idea",
                "how convenient that is for excavating lost artifacts?",
            },
        },
        ["Searing Gorge"] = {
            weight = 0.12,
            lines = {
                "The air burns, but the volcanic soil is excellent for",
                "brewing. Plus, Thorium Point is right next to the entrance",
                "to Blackrock Mountain.",
            },
        },
        ["Blasted Lands"] = {
            weight = 0.15,
            lines = {
                "We are close now. The Dark Portal hums with raw, unrefined",
                "chaos. Delicious.",
            },
        },
        -- Late Game / Hardcore Endgame Zones
        ["Burning Steppes"] = {
            weight = 0.15,
            lines = {
                "Fire everywhere. It is comforting, in a way.",
                "Molten Core is right around the bend; the fel energy",
                "radiating from the mountain would make even a lesser mage weep.",
            },
        },
        ["Western Plaguelands"] = {
            weight = 0.15,
            lines = {
                "Chillwind Camp is freezing. But Scholomance... ah, that",
                "ancient mausoleum. An entire dungeon of corpses waiting",
                "for a fresh soul to bind them.",
            },
        },
        ["Eastern Plaguelands"] = {
            weight = 0.15,
            lines = {
                "Light's Hope Chapel stands as a monument to human",
                "stubbornness, but Stratholme remains the true prize.",
                "An entire city preserved in undeath.",
            },
        },
        ["Blackrock Mountain"] = {
            weight = 0.18,
            lines = {
                "A cathedral of ash and magma. The upper reaches house",
                "our greatest trials—Lower, Upper, and the Deep.",
            },
        },
        ["Deadwind Pass"] = {
            weight = 0.15,
            lines = {
                "Karazhan looms ahead, defying gravity and reason alike.",
                "A chaotic masterpiece perfectly suited for my craft.",
            },
        },
        ["Tanaris"] = {
            weight = 0.12,
            lines = {
                "Gadgetzan is neutral ground. Useful, but dusty.",
                "However, Zul'Farrak offers plenty of ancient curses to study.",
            },
        },
        ["Un'Goro Crater"] = {
            weight = 0.15,
            lines = {
                "Prehistoric monsters and toxic mud. My absolute favorite",
                "hunting ground.",
            },
        },
    },

    subzones = {
        ["inn"] = {
            weight = 0.10,
            lines = {
                "Time for a rest. Perhaps a tank of something strong.",
                "Inns exist solely because adventurers have terrible stamina.",
            },
        },
        ["grave"] = {
            weight = 0.15,
            lines = {
                "Fresh earth... ideal for planting soul shards.",
                "Why do humans get so upset about a little burial?",
            },
        },
        ["crypt"] = {
            weight = 0.20,
            lines = {
                "Oh, a crypt! The spirits here must be bound tightly.",
                "Look at that architecture. Designed purely to trap the living.",
            },
        },
        ["cavern"] = {
            weight = 0.15,
            lines = {
                "Dark, damp, and completely pitch black. Just how I like it.",
                "Are we near a cave yet? It's impossible to practice",
                "properly in open daylight.",
            },
        },
        ["ruin"] = {
            weight = 0.15,
            lines = {
                "Old ruins... rich in residual magical fallout.",
                "Someone failed to contain whatever happened here.",
            },
        },
        ["camp"] = {
            weight = 0.05,
            lines = {
                "Military camps always attract the most aggressive patrols.",
            },
        },
    },
}