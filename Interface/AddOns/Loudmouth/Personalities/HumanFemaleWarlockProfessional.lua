Loudmouth = Loudmouth or {}
Loudmouth._RawPersonalities = Loudmouth._RawPersonalities or {}

Loudmouth._RawPersonalities["HumanFemaleWarlockProfessional"] = {
    likes = {
        zones = { "graveyard", "cave", "haunted", "demonic", "undead" },
        entities = {
            ["gnome"] = {
                weight = 1 / 20,
                lines = {
                    "Oh, you're so cute!",
                    "Sorry, little one. Professional obligations.",
                    "Such a tiny target. This almost feels unfair.",
                    "Adorable. Dangerous, perhaps, but still adorable.",
                },
            },
        },
    },

    hates = {
        zones = { "dwarf" },
        entities = {
            ["dwarf"] = {
                weight = 1 / 20,
                lines = {
                    "I hope this burns the hair off your ugly dwarf feet!",
                    "Hold still, dwarf. Personal hygiene is about to become irrelevant.",
                    "A dwarf in my sights. The day improves already.",
                    "Try hiding behind that beard when the shadows arrive.",
                },
            },
        },
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
            weight = 1 / 5, -- early armor buff; mutually exclusive with Demon Armor
            lines = {
                "Show some respect for the void.",
                "The darker your skin, the harder you fall.",
                "Armor of shadow, fortitude of hellfire.",
            },
        },
        ["Drain Soul"] = {
            weight = 1 / 100, -- frequently used shard-generating channel
            lines = {
                "Your essence... mine.",
                "Siphoning what remains.",
                "Feel that drain? That's death, slowly.",
                "Every last drop.",
            },
        },
        ["Create Healthstone"] = {
            weight = 1 / 5,
            lines = {
                "A little insurance, shaped from a soul.",
                "Healthstone prepared. Try not to waste it on a paper cut.",
                "Soul shard in, survival out. Efficient.",
            },
        },
        ["Health Funnel"] = {
            weight = 1 / 50,
            lines = {
                "My life for yours, demon. Do make it worthwhile.",
                "Hold still. This is maintenance, not affection.",
                "A measured transfer of vitality. Nothing sentimental.",
            },
        },
        ["Ritual of Summoning"] = {
            weight = 1,
            lines = {
                "The portal is ready. Two assistants, if you please.",
                "Stand at the circle and try not to interrupt the ritual.",
                "We will bring them here. Distance is merely an inconvenience.",
            },
        },
        ["Shadow Ward"] = {
            weight = 1 / 10,
            lines = {
                "Shadow answers to me, not them.",
                "A ward against the void. Professional caution.",
                "Darkness is less threatening when properly contained.",
            },
        },
        ["Create Firestone"] = {
            weight = 1 / 5,
            lines = {
                "Fire, compressed into something useful.",
                "A firestone for when ordinary flames lack discipline.",
                "Shard, flame, focus. The formula remains elegant.",
            },
        },
        ["Create Spellstone"] = {
            weight = 1 / 5,
            lines = {
                "A spellstone turns hostile magic into a temporary inconvenience.",
                "Arcane protection, produced by superior methods.",
                "Let their magic break against this stone.",
            },
        },
        ["Sense Demons"] = {
            weight = 1 / 10,
            lines = {
                "Demons leave a distinctive stain on the world.",
                "Something infernal is nearby. I can feel it.",
                "No demon escapes a trained eye for long.",
            },
        },
        ["Detect Invisibility"] = {
            weight = 1 / 10,
            lines = {
                "Hidden does not mean safe.",
                "Let us see what prefers not to be seen.",
                "Invisibility is merely a problem of perception.",
            },
        },
        ["Summon Incubus"] = {
            weight = 1,
            lines = {
                "Incubus, compose yourself. We have work to do.",
                "Charm is useful. Discipline is essential.",
                "Come forth, incubus, and keep the theatrics brief.",
            },
        },
        ["Warlock Mount"] = {
            weight = 1 / 10,
            lines = {
                "A proper steed should arrive in flame.",
                "No reins, no stable fees, only a binding contract.",
                "The road is long. Fortunately, the nether provides transportation.",
            },
        },
        ["Amplify Curse"] = {
            weight = 1 / 5,
            lines = {
                "A small adjustment should make this considerably worse.",
                "Why settle for a curse when one can refine it?",
                "The affliction is sound. Let us increase the dosage.",
            },
        },
        ["Curse of Exhaustion"] = {
            weight = 1 / 50,
            lines = {
                "Every step will feel like the last.",
                "Run if you like. Fatigue will catch you first.",
                "Let exhaustion drag at your bones.",
            },
        },
        ["Siphon Life"] = {
            weight = 1 / 100,
            lines = {
                "Your life is being reassigned to a better owner.",
                "A steady flow of vitality. Much appreciated.",
                "Waste not. Even your life has some value.",
            },
        },
        ["Dark Pact"] = {
            weight = 1 / 50,
            lines = {
                "The contract includes an energy surcharge.",
                "Lend me your power, demon. That was not a request.",
                "A familiar is simply a reserve of useful magic.",
            },
        },
        ["Fel Domination"] = {
            weight = 1,
            lines = {
                "No delays. I require a demon immediately.",
                "A firm command shortens any summoning ritual.",
                "The nether will answer now.",
            },
        },
        ["Demonic Sacrifice"] = {
            weight = 1,
            lines = {
                "Your service concludes with one final contribution.",
                "Nothing personal, demon. Your essence is simply more useful.",
                "A binding contract always includes a termination clause.",
            },
        },
        ["Soul Link"] = {
            weight = 1 / 10,
            lines = {
                "Our souls are linked. Try not to embarrass me.",
                "Shared pain encourages excellent discipline.",
                "One bond, two bodies, considerably better odds.",
            },
        },
        ["Shadowburn"] = {
            weight = 1 / 100,
            lines = {
                "A final spark of shadow should suffice.",
                "Burn quickly. I have other appointments.",
                "One shard for one abrupt ending.",
            },
        },
        ["Conflagrate"] = {
            weight = 1 / 100,
            lines = {
                "The fire was already there. I merely encouraged it.",
                "Let every lingering ember erupt at once.",
                "A controlled conflagration, more or less.",
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
                "Night Elf arrogance in flesh and bark. They hide from history while it catches up to them.",
            },
        },
        ["Teldrassil"] = {
            weight = 0.10,
            lines = {
                "A floating tree. The futility of trying to climb your way to the heavens.",
            },
        },
        -- Mid-Level Hubs & Dark Places
        ["City of Ironforge"] = {
            weight = 0.15,
            lines = {
                "Smells like feet and malt liquor... Dwarfs are disgusting.",
                "The stonework is impressive, but only if you enjoy looking at something that reeks of sweat and cheap beer.",
                "Dwarves are the reason the air in Ironforge feels thick and stale.",
                "I'd rather kiss a ghoul than spend another moment in that smelly hole.",
            },
        },
        ["Iron Forge"] = {
            weight = 0.15,
            lines = {
                "The Great Forge never sleeps, so the soot, noise, and dwarven stench never stop either.",
            },
        },
        ["Dwarven Halls"] = {
            weight = 0.15,
            lines = {
                "Endless stone corridors amplifying every dwarven belch. These halls are intolerable.",
            },
        },
        ["Dun Morogh"] = {
            weight = 0.15,
            lines = {
                "Cold, damp, and crawling with dwarves. Even an imp would complain about the smell.",
                "Snow, rock, and dwarves in every direction. What a miserable little kingdom.",
                "Dun Morogh might look pristine if the snow were not packed down by filthy dwarf boots.",
                "A frozen landscape full of wet beards and stale ale. Revolting.",
            },
        },
        ["Loch Modan"] = {
            weight = 0.10,
            lines = {
                "Thelsamar is another heap of stone, smoke, and dwarf-sized furniture. Tedious.",
                "Loch Modan... a lovely lake ruined by the smell of wet dwarves. Ick.",
                "The lake is beautiful from a distance. Unfortunately, the dwarves are visible from here too.",
                "Even the mountain air cannot overpower the stench drifting out of Thelsamar.",
            },
        },
        ["Westfall"] = {
            weight = 0.10,
            lines = {
                "Furlbrow's farm is a tragic reminder of what happens when you underestimate the void.",
            },
        },
        ["Duskwood"] = {
            weight = 0.15,
            lines = {
                "Smells like death... I LOVE IT!",
                "The air is thick with decay — absolutely intoxicating.",
                "The trees are twisted, the shadows suffocating, and the screams endless... what a symphony.",
                "Everything here is cursed, haunted, or dying... I feel right at home.",
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
                "Dust, heat, and endless rock. The Badlands certainly earned the name.",
            },
        },
        ["Searing Gorge"] = {
            weight = 0.12,
            lines = {
                "The volcanic air would be tolerable if it did not carry the smell of singed dwarf hair.",
                "Searing Gorge: ash in my lungs and Dark Iron dwarves under every rock. Ghastly.",
                "The landscape is already burning. Surely it can manage to dispose of the dwarves too.",
                "Thorium Point proves dwarves can make even a volcanic wasteland less pleasant.",
            },
        },
        ["Blasted Lands"] = {
            weight = 0.15,
            lines = {
                "A barren red wasteland scarred by old magic. At least the view is honest.",
            },
        },
        -- Late Game / Hardcore Endgame Zones
        ["Burning Steppes"] = {
            weight = 0.15,
            lines = {
                "Fire everywhere. It is comforting, in a way.",
                "Molten Core is right around the bend; the fel energy radiating from the mountain would make even a lesser mage weep.",
            },
        },
        ["Western Plaguelands"] = {
            weight = 0.15,
            lines = {
                "Chillwind Camp is freezing. But Scholomance... ah, that ancient mausoleum. An entire dungeon of corpses waiting for a fresh soul to bind them.",
            },
        },
        ["Eastern Plaguelands"] = {
            weight = 0.15,
            lines = {
                "Light's Hope Chapel stands as a monument to human stubbornness, but Stratholme remains the true prize. An entire city preserved in undeath.",
            },
        },
        ["Blackrock Mountain"] = {
            weight = 0.18,
            lines = {
                "A cathedral of ash and magma. The upper reaches house our greatest trials—Lower, Upper, and the Deep.",
            },
        },
        ["Deadwind Pass"] = {
            weight = 0.15,
            lines = {
                "Karazhan looms ahead, defying gravity and reason alike. A chaotic masterpiece perfectly suited for my craft.",
            },
        },
        ["Tanaris"] = {
            weight = 0.12,
            lines = {
                "Gadgetzan is neutral ground. Useful, but dusty. However, Zul'Farrak offers plenty of ancient curses to study.",
            },
        },
        ["Tirisfal Glades"] = {
            weight = 0.15,
            lines = {
                "The dead have inherited these gloomy woods. They have improved the neighborhood considerably.",
                "Tirisfal is steeped in undeath, decay, and dreadful history. I approve.",
            },
        },
        ["Silverpine Forest"] = {
            weight = 0.15,
            lines = {
                "A shadowed forest thick with undead influence. Silverpine has excellent atmosphere.",
                "The living cling nervously to these woods while the dead thrive. Sensible priorities.",
            },
        },
        ["Felwood"] = {
            weight = 0.15,
            lines = {
                "Fel energy has soaked into the forest itself. What magnificent corruption.",
                "Demons and fel magic have transformed Felwood into something truly interesting.",
            },
        },
        ["Undercity"] = {
            weight = 0.15,
            lines = {
                "An entire capital beneath the earth, run by the undead. Inspired.",
                "Undercity smells of plague and alchemy, but the residents have impeccable taste in decor.",
            },
        },
        ["Ragefire Chasm"] = {
            weight = 0.18,
            lines = {
                "A volcanic cave with demonic company. Ragefire Chasm has everything I require.",
                "Hot stone, deep shadows, and demonic whispers... delightful working conditions.",
            },
        },
        ["Wailing Caverns"] = {
            weight = 0.18,
            lines = {
                "A vast cave that actually wails. Finally, architecture with personality.",
                "The twisting tunnels of Wailing Caverns feel wonderfully removed from the sun.",
            },
        },
        ["The Deadmines"] = {
            weight = 0.18,
            lines = {
                "Miles of dark mine tunnels beneath Westfall. Much better than the farmland above.",
                "The Deadmines are damp, secretive, and full of useful echoes. Charming.",
            },
        },
        ["Blackfathom Deeps"] = {
            weight = 0.18,
            lines = {
                "A drowned cavern of ancient shadows. Blackfathom Deeps is exquisite.",
                "Ruined halls beneath the earth and sea... exactly where forbidden things belong.",
            },
        },
        ["Razorfen Kraul"] = {
            weight = 0.18,
            lines = {
                "A thorn-choked cavern hidden from daylight. Surprisingly tasteful.",
                "Razorfen Kraul is cramped, dark, and dangerous. I feel quite comfortable.",
            },
        },
        ["Razorfen Downs"] = {
            weight = 0.18,
            lines = {
                "A cavern, a graveyard, and an undead infestation together at last. Perfect.",
                "Razorfen Downs combines deep shadows with restless dead. An inspired arrangement.",
                "Bones below ground and spirits that refuse to leave... I adore this place.",
            },
        },
        ["Uldaman"] = {
            weight = 0.18,
            lines = {
                "These ancient caverns would be magnificent without dwarves pawing over every relic.",
                "A buried titan vault spoiled by dwarf boots, dwarf picks, and dwarf opinions. Disgusting.",
                "I love the darkness of Uldaman. I hate the wet-dwarf smell trapped inside it.",
                "Wonderful caves, priceless secrets, and far too many dwarves. What a waste.",
            },
        },
        ["Maraudon"] = {
            weight = 0.18,
            lines = {
                "Maraudon's vast corrupted caverns are almost soothing.",
                "A subterranean maze where nature has gone terribly wrong. Beautiful.",
            },
        },
        ["Blackrock Depths"] = {
            weight = 0.18,
            lines = {
                "An underground city full of Dark Iron dwarves. As if ordinary dwarves were not unpleasant enough.",
                "Blackrock Depths has impressive scale and absolutely appalling residents.",
                "Lava, iron, and the smell of scorched beard. This place is intolerable.",
                "The Dark Irons buried themselves deep underground. If only they had stayed buried.",
            },
        },
        ["Shadowfang Keep"] = {
            weight = 0.18,
            lines = {
                "A haunted keep crowded with undead and curses. Shadowfang understands hospitality.",
                "Every corridor groans with restless spirits. I could happily move in.",
            },
        },
        ["Scholomance"] = {
            weight = 0.18,
            lines = {
                "A haunted school of necromancy filled with undead scholars. Finally, serious academics.",
                "Scholomance turns death into a curriculum. I admire its standards.",
            },
        },
        ["Stratholme"] = {
            weight = 0.18,
            lines = {
                "An entire city preserved in undeath. Stratholme is a masterpiece.",
                "The dead own every street now, and the city has never felt more alive.",
            },
        },
        ["Molten Core"] = {
            weight = 0.18,
            lines = {
                "A cavern large enough to contain a sea of fire. Magnificent.",
                "Molten Core proves that caves need not be cold to be inviting.",
            },
        },
        ["Onyxia's Lair"] = {
            weight = 0.18,
            lines = {
                "A dragon's cavern should always feel this grand and threatening.",
                "Onyxia chose a dark volcanic lair. The dragon has taste.",
            },
        },
        ["Blackwing Lair"] = {
            weight = 0.18,
            lines = {
                "Deep mountain halls full of fire and dragons. Splendid.",
                "Blackwing Lair is dark, volcanic, and magnificently hostile.",
            },
        },
        ["Naxxramas"] = {
            weight = 0.18,
            lines = {
                "A fortress ruled by necromancers and packed with undead. Breathtaking.",
                "Naxxramas elevates undeath from a practice to an art form.",
            },
        },
        ["Un'Goro Crater"] = {
            weight = 0.15,
            lines = {
                "Prehistoric monsters and toxic mud. My absolute favorite hunting ground.",
            },
        },
    },

    subzones = {
        ["Durotar"] = {
            ["Skull Rock"] = { lines = { "Skull Rock is dark, enclosed, and named for a skull. Excellent taste." } },
            ["Dustwind Cave"] = { lines = { "Dustwind Cave keeps out the sun and most unwanted company. Delightful." } },
        },
        ["The Barrens"] = {
            ["Boulder Lode Mine"] = { lines = { "At last, a proper cave beneath all that tedious Barrens sunlight." } },
            ["The Venture Co. Mine"] = { lines = { "A dark mine is still a cave, even after goblins fill it with machinery. I approve." } },
            ["Dreadmist Den"] = { lines = { "Dreadmist Den is the first part of the Barrens with respectable lighting." } },
            ["Bael Modan"] = { lines = { "Bael Modan proves dwarves can make even ancient ruins smell like wet beard." } },
        },
        ["Teldrassil"] = {
            ["Shadowthread Cave"] = { lines = { "Shadowthread Cave is wonderfully dark, despite the intolerable tree outside." } },
            ["Fel Rock"] = { lines = { "A demonic cave beneath Teldrassil... finally, something here worth admiring." } },
            ["Ban'ethil Barrow Den"] = { lines = { "The barrow den is dark, corrupted, and far more appealing than the forest above." } },
        },
        ["Darkshore"] = {
            ["Ameth'Aran"] = { lines = { "Haunted ruins full of lingering dead... Ameth'Aran has aged beautifully." } },
            ["Bashal'Aran"] = { lines = { "Bashal'Aran's restless dead give these ruins exactly the right atmosphere." } },
        },
        ["Ashenvale"] = {
            ["Talondeep Path"] = { lines = { "Talondeep Path trades forest sunlight for cave walls. A marked improvement." } },
            ["Felfire Hill"] = { lines = { "Felfire Hill is corrupted, demonic, and positively radiant with fel power." } },
            ["Demon Fall Canyon"] = { lines = { "A canyon steeped in demonic corruption. Demon Fall is magnificent." } },
            ["Demon Fall Ridge"] = { lines = { "Demon Fall Ridge still carries the stain of demons. I hope it never fades." } },
            ["Satyrnaar"] = { lines = { "Demonic satyrs among corrupted ruins... Satyrnaar is charmingly decadent." } },
        },
        ["Thousand Needles"] = {
            ["Roguefeather Den"] = { lines = { "Roguefeather Den offers blessed shade from this endless canyon." } },
            ["Splithoof Crag"] = { lines = { "Splithoof Crag is dark, defensible, and pleasantly cave-like." } },
            ["Rustmaul Dig Site"] = { lines = { "Dwarves digging in the desert. Apparently nowhere is safe from their stink." } },
        },
        ["Stonetalon Mountains"] = {
            ["Boulderslide Ravine"] = { lines = { "The caves of Boulderslide Ravine are much more inviting than their occupants." } },
            ["Windshear Mine"] = { lines = { "Windshear Mine is industrial, but its dark tunnels remain appealing." } },
        },
        ["Desolace"] = {
            ["Kodo Graveyard"] = { lines = { "A graveyard of enormous bones beneath an empty sky. Beautiful." } },
            ["Mannoroc Coven"] = { lines = { "Mannoroc Coven still reeks of fel rituals. I feel welcome already." } },
            ["Sargeron"] = { lines = { "Demonic ruins in a barren wasteland... Sargeron has genuine character." } },
        },
        ["Feralas"] = {
            ["The Writhing Deep"] = { lines = { "The Writhing Deep is a living cave of chittering darkness. Wonderful." } },
            ["Dire Maul"] = { lines = { "Dire Maul's ruins conceal arcane and demonic treasures. An excellent combination." } },
        },
        ["Dustwallow Marsh"] = {
            ["The Den of Flame"] = { lines = { "A fiery cave hidden in a swamp. The Den of Flame is unexpectedly tasteful." } },
            ["Darkmist Cavern"] = { lines = { "Darkmist Cavern is damp, lightless, and appropriately named." } },
            ["Bael'dun Keep"] = { lines = { "A dwarf keep sinking into a swamp. The swamp has my sympathy." } },
        },
        ["Tanaris"] = {
            ["Caverns of Time"] = { lines = { "Ancient caverns outside ordinary time... now this is serious architecture." } },
        },
        ["Felwood"] = {
            ["Jaedenar"] = { lines = { "Jaedenar is saturated with demons and fel corruption. Exquisite." } },
            ["Shadow Hold"] = { lines = { "A fel-infested demonic cave beneath Jaedenar. Shadow Hold is nearly perfect." } },
            ["Shrine of the Deceiver"] = { lines = { "The Shrine of the Deceiver hums with demonic power. Lovely." } },
            ["Shatter Scar Vale"] = { lines = { "Demonic corruption has carved Shatter Scar Vale into a work of art." } },
            ["Jadefire Run"] = { lines = { "Jadefire Run is crawling with demons and steeped in fel magic. Delightful." } },
            ["Irontree Cavern"] = { lines = { "Irontree Cavern is dark enough to make even Felwood feel brighter outside." } },
        },
        ["Un'Goro Crater"] = {
            ["Fungal Rock"] = { lines = { "A humid cave full of giant beasts. Fungal Rock is wonderfully impractical." } },
            ["The Slithering Scar"] = { lines = { "The Slithering Scar is a cave that moves, bites, and breeds. Fascinating." } },
        },
        ["Silithus"] = {
            ["Hive'Ashi"] = { lines = { "Hive'Ashi turns an entire cave system into one chittering organism. Impressive." } },
            ["Hive'Zora"] = { lines = { "The tunnels of Hive'Zora pulse with hidden life. I adore unsettling caves." } },
            ["Hive'Regal"] = { lines = { "Hive'Regal is deep, hostile, and magnificently alien." } },
            ["Bronzebeard Encampment"] = { lines = { "Bronzebeard Encampment: tents, dust, and dwarves pretending not to smell." } },
        },
        ["Winterspring"] = {
            ["Mazthoril"] = { lines = { "An arcane dragon cave beneath the snow. Mazthoril is splendid." } },
            ["Darkwhisper Gorge"] = { lines = { "A demonic cave hidden in frozen mountains... Darkwhisper Gorge is worth the climb." } },
        },
        ["Orgrimmar"] = {
            ["Cleft of Shadow"] = { lines = { "The Cleft of Shadow is underground, demonic, and the only civilized part of Orgrimmar." } },
        },
        ["Badlands"] = {
            ["Dustbelch Grotto"] = { lines = { "Dustbelch Grotto is dark and cool, a welcome refuge from the Badlands." } },
            ["Uldaman"] = { lines = { "A magnificent cave complex spoiled by dwarves scratching at titan relics. Revolting." } },
            ["Angor Fortress"] = { lines = { "Angor Fortress is what happens when dwarves combine stonework with poor hygiene." } },
            ["Hammertoe's Digsite"] = { lines = { "Another dwarf digsite, another cloud of dust and beard dandruff." } },
        },
        ["Blasted Lands"] = {
            ["The Tainted Scar"] = { lines = { "The Tainted Scar is drenched in fel corruption and demonic power. Magnificent." } },
            ["The Dark Portal"] = { lines = { "The Dark Portal hums with raw demonic chaos. Delicious." } },
            ["Altar of Storms"] = { lines = { "An altar built for demonic transformation. At last, proper craftsmanship." } },
        },
        ["Tirisfal Glades"] = {
            ["The Deathknell Graves"] = { lines = { "Deathknell's haunted graves are an encouraging start to any journey." } },
            ["Shadow Grave"] = { lines = { "Shadow Grave is full of restless dead and excellent possibilities." } },
            ["Faol's Rest"] = { lines = { "A haunted grave beneath gloomy trees. Faol chose a lovely resting place." } },
            ["Agamand Mills"] = { lines = { "The Agamand dead still tend their family grounds. Such dedication." } },
            ["Garren's Haunt"] = { lines = { "Garren's Haunt lives up to its name in the most delightful way." } },
            ["Ruins of Lordaeron"] = { lines = { "Haunted ruins occupied by the undead... Lordaeron has finally found its purpose." } },
        },
        ["Silverpine Forest"] = {
            ["The Sepulcher"] = { lines = { "An undead settlement named for a tomb. The Sepulcher understands branding." } },
            ["Fenris Isle"] = { lines = { "Fenris Isle is haunted, ruined, and thick with undead. Charming." } },
            ["Pyrewood Village"] = { lines = { "A haunted village with a worgen problem. Pyrewood has wonderful energy." } },
            ["Shadowfang Keep"] = { lines = { "Shadowfang Keep is haunted by undead and worgen alike. I feel spoiled." } },
        },
        ["Western Plaguelands"] = {
            ["School of Necromancy"] = { lines = { "A haunted school where the undead study necromancy. Finally, respectable education." } },
            ["Sorrow Hill"] = { lines = { "Sorrow Hill is a graveyard full of undead and excellent raw materials." } },
            ["The Weeping Cave"] = { lines = { "Even the cave is weeping here. I find that strangely endearing." } },
            ["Caer Darrow"] = { lines = { "Caer Darrow's haunted undead ruins make a perfect approach to Scholomance." } },
        },
        ["Hillsbrad Foothills"] = {
            ["Purgation Isle"] = { lines = { "A haunted island of undead suffering. Purgation is more appealing than advertised." } },
            ["Dun Garok"] = { lines = { "Dun Garok is packed with dwarves. The mountain deserved better." } },
        },
        ["The Hinterlands"] = {
            ["Skulk Rock"] = { lines = { "Skulk Rock offers a wonderfully dark escape from the Hinterlands." } },
            ["Aerie Peak"] = { lines = { "Aerie Peak would be picturesque if the Wildhammer dwarves bathed occasionally." } },
            ["Wildhammer Keep"] = { lines = { "Wildhammer Keep smells like feathers, ale, and damp dwarf. Awful." } },
        },
        ["Dun Morogh"] = {
            ["Frostmane Hold"] = { lines = { "A useful cave, ruined by the dwarf stench drifting in from outside." } },
            ["The Grizzled Den"] = { lines = { "The Grizzled Den is a fine cave surrounded by far too many grizzled dwarves." } },
            ["Gol'Bolar Quarry"] = { lines = { "Dark quarry tunnels should be pleasant, but dwarf labor has fouled the air." } },
        },
        ["Searing Gorge"] = {
            ["The Slag Pit"] = { lines = { "A dark industrial cave full of Dark Irons. One good feature, one terrible infestation." } },
            ["Blackchar Cave"] = { lines = { "Blackchar Cave would be delightful if dwarves had not tracked soot through it." } },
            ["Thorium Point"] = { lines = { "Thorium Point is where dwarves add ale breath to the volcanic fumes." } },
        },
        ["Burning Steppes"] = {
            ["Dreadmaul Rock"] = { lines = { "Demonic power lingers around Dreadmaul Rock. I admire the atmosphere." } },
            ["Altar of Storms"] = { lines = { "This demonic altar has survived beautifully. Someone maintained their standards." } },
            ["Ruins of Thaurissan"] = { lines = { "The ruins of a dwarf city smell better than the occupied ones, but only slightly." } },
        },
        ["Deadwind Pass"] = {
            ["The Vice"] = { lines = { "A demonic cave in a haunted canyon. The Vice is wonderfully excessive." } },
            ["Morgan's Plot"] = { lines = { "Morgan's haunted grave is one of Deadwind Pass's finer attractions." } },
            ["Karazhan"] = { lines = { "Karazhan is haunted, demonic, and saturated with arcane disaster. A masterpiece." } },
        },
        ["Duskwood"] = {
            ["Raven Hill"] = { lines = { "Raven Hill is ruined, haunted, and crawling with undead... lovely." } },
            ["Raven Hill Cemetery"] = { lines = { "A haunted cemetery full of undead... Raven Hill is practically a resort." } },
            ["Tranquil Gardens Cemetery"] = { lines = { "Tranquil Gardens is haunted, but the spirits are excellent company." } },
            ["Dawning Wood Catacombs"] = { lines = { "Undead in a haunted cave beneath a cemetery... the catacombs are perfect." } },
            ["Roland's Doom"] = { lines = { "A haunted worgen cave called Roland's Doom. I could not name it better myself." } },
            ["Vul'Gol Ogre Mound"] = { lines = { "The ogres are tiresome, but their cave is pleasantly dark." } },
        },
        ["Loch Modan"] = {
            ["Silver Stream Mine"] = { lines = { "Silver Stream Mine is a lovely cave poisoned by the smell of dwarf boots." } },
            ["Stonesplinter Valley"] = { lines = { "Fine caves, foul dwarves nearby. Loch Modan remains committed to disappointment." } },
        },
        ["Redridge Mountains"] = {
            ["Rethban Caverns"] = { lines = { "Rethban Caverns are cool, dark, and blessedly far from Lakeshire." } },
            ["Render's Rock"] = { lines = { "Render's Rock is exactly the sort of deep cave I appreciate." } },
        },
        ["Stranglethorn Vale"] = {
            ["Crystalvein Mine"] = { lines = { "Crystalvein Mine is the rare part of Stranglethorn with enough shade." } },
            ["Nek'mani Wellspring"] = { lines = { "A hidden cave beneath the jungle. Nek'mani Wellspring is a welcome secret." } },
        },
        ["Swamp of Sorrows"] = {
            ["Itharius's Cave"] = { lines = { "Itharius chose a damp cave in a gloomy swamp. Sensible." } },
            ["Stagalbog Cave"] = { lines = { "Stagalbog Cave is dark, wet, and wonderfully secluded." } },
        },
        ["Westfall"] = {
            ["Gold Coast Quarry"] = { lines = { "The quarry tunnels are a welcome refuge from Westfall's glaring fields." } },
            ["Jangolode Mine"] = { lines = { "Jangolode Mine is dark enough to make Westfall briefly tolerable." } },
        },
        ["Wetlands"] = {
            ["Thelgen Rock"] = { lines = { "Thelgen Rock hides a perfectly respectable cave beneath the marsh." } },
            ["Whelgar's Excavation Site"] = { lines = { "A promising cave and titan ruin, spoiled by dwarf excavation dust and worse odors." } },
            ["Dun Modr"] = { lines = { "Dun Modr is yet another pile of dwarf stonework marinated in ale." } },
            ["Ironbeard's Tomb"] = { lines = { "A dead dwarf in a tomb is marginally less offensive than a live one in a tavern." } },
            ["Dun Algaz"] = { lines = { "Dun Algaz squeezes every traveler through a corridor of concentrated dwarf smell." } },
        },
        ["Stormwind City"] = {
            ["The Slaughtered Lamb"] = { lines = { "The Slaughtered Lamb keeps its demons below stairs, just as proper establishments should." } },
            ["Dwarven District"] = { lines = { "The Dwarven District proves Stormwind has no standards for air quality." } },
        },
        ["Scarlet Monastery"] = {
            ["Chamber of Atonement"] = { lines = { "A haunted graveyard chamber full of undead penitents. Delightful." } },
            ["Forlorn Cloister"] = { lines = { "The Forlorn Cloister is haunted, funereal, and wonderfully bleak." } },
            ["Honor's Tomb"] = { lines = { "Honor's Tomb has the undead, haunted dignity its name promises." } },
        },
        ["Dire Maul"] = {
            ["Warpwood Quarter"] = { lines = { "Demonic corruption has improved the Warpwood Quarter considerably." } },
            ["The Conservatory"] = { lines = { "A corrupted demonic garden in ancient ruins... unexpectedly lovely." } },
            ["Capital Gardens"] = { lines = { "Haunted Highborne gardens full of undead are still gardens worth visiting." } },
            ["Court of the Highborne"] = { lines = { "Arcane ghosts haunt the Court of the Highborne with admirable persistence." } },
            ["Prison of Immol'thar"] = { lines = { "An arcane prison built around a demon. Dire Maul understands priorities." } },
        },
        ["inn"] = {
            weight = 0.10,
            lines = {
                "Time for a rest. Perhaps a tank of something strong.",
                "Inns exist solely because adventurers have terrible stamina.",
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
