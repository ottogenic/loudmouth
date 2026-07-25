Loudmouth = Loudmouth or {}
Loudmouth._RawPersonalities = Loudmouth._RawPersonalities or {}

Loudmouth._RawPersonalities["DwarfFemaleHunterQuirky"] = {
    -- Likes and Hates traits for context-aware banter.
    -- Each contains Places (zone/subzone substrings) and Entities (target name/class/race substrings).
    -- Case-insensitive substring matching is used for all comparisons.
    -- Hates takes precedence over Likes when multiple traits match.
    -- Trait-specific dialogue is under Lines.<Polarity>.<Context>.<Trait> or Lines.<Polarity>.<Context>.Generic
    Likes = {
        Places = {
            "Dun Modir",
            "Coldridge",
            "Mountain",
            "Hill",
            "Forest",
            "Hunt",
            "Prey",
            "Wild",
            "Meadow",
            "Ridge",
        },
        Entities = {
            "Boar",
            "Wolf",
            "Bear",
            "Cat",
            "Beast",
            "Creature",
            "Pet",
            "Gorilla",
        },
    },
    Hates = {
        Places = {
            "Stormwind",
            "Night Elf",
            "Elven",
            "High Elf",
            "Darnassus",
            "Teldrassil",
            "Tree",
            "Tree-hugger",
            "Tree hugger",
        },
        Entities = {
            "Night Elf",
            "Night Elf",
            "Elven",
            "Elf",
            "Troll",
            "Scourge",
            "Undead",
            "Zombie",
        },
    },

    actions = {
        ["Auto Shot"] = {
            weight = 1/300,
            lines = {
                "Pew!",
                "Take that, ya scallywag!",
                "Just a little tickle!",
                "Bite the bullet!",
                "Pew pew pew!",
                "Just keeping them honest.",
                "Ticking away like a clock!",
            }
        },
        ["Aimed Shot"] = {
            weight = 1/300,
            lines = {
                "Bullseye!",
                "Right in the kisser!",
                "Couldn't miss if I tried!",
                "Hold still, will ya?",
                "Hold still, you beauty!",
                "Don't blink, or you'll miss it!",
            }
        },
        ["Hunters Mark"] = {
            weight = 1/10,
            lines = {
                "I've got my eye on you!",
                "Nowhere to hide!",
                "Marked for greatness (or death)!",
            }
        },
        ["Trap"] = {
            weight = 1/10,
            lines = {
                "Gotcha in a pinch!",
                "Nowhere to run now!",
                "Surprise!",
                "Stay put!",
            }
        },
        ["Pet Attack"] = {
            weight = 1/20,
            lines = {
                "Get 'em, you big hairy beast!",
                "Go on, Gorilla, smash them to bits!",
                "Show 'em what a real ape can do!",
                "Squeeze 'em, ya big lug!",
            }
        },
        ["Multishot"] = {
            weight = 1/50,
            lines = {
                "Rain 'em down!",
                "Too many for you?",
                "Spread the love!",
            }
        },
        ["Health Potion"] = {
            weight = 1,
            lines = {
                "Tastes like cherries and magic!",
                "A quick sip for the road.",
                "Refreshing!",
            }
        },
        ["Bandage"] = {
            weight = 1,
            lines = {
                "Hold still, I'm a professional!",
                "A bit of gauze and a lot of hope.",
                "Stop squirming!",
            }
        },
        ["Generic"] = {
            weight = 1,
            lines = {
                "What was I saying?",
                "Is it lunchtime yet?",
                "I love the smell of gunpowder in the morning!",
            }
        }
    },

    -- Trait-specific dialogue lines.
    -- Structure: Lines.<Polarity>.<Context>.<Trait> or Lines.<Polarity>.<Context>.Generic
    --   Polarity: "Likes" or "Hates"
    --   Context: "Places" or "Entities"
    --   Trait: matched trait string, or "Generic" for fallback
    -- Hates lines take precedence over Likes lines when multiple traits match.
    -- Entity lines are action-specific (use action key) or Generic fallback.
    Lines = {
        Likes = {
            Places = {
                ["Dun Modir"] = {
                    "Home sweet home! Smells like forge and ale.",
                    "Cold enough for ya? I love it!",
                    "Dun Modir... the heart of the mountain!",
                    "Best brew is right around the corner.",
                    "Who needs a coat when you've got Dwarf pride?",
                },
                ["Coldridge"] = {
                    "Plenty of boar to hunt here!",
                    "Coldridge is a bit drafty, isn't it?",
                    "Keep your eyes open, there's danger in the brush.",
                    "I could spend all day in these hills.",
                    "Fresh air and fresh prey!",
                },
                ["Mountain"] = {
                    "The mountains are calling! I must go.",
                    "Nothing like a good climb to clear the head.",
                },
                ["Hill"] = {
                    "Hills are perfect for a good hunt.",
                    "Nice rolling hills. Good visibility.",
                },
                ["Forest"] = {
                    "The forest is full of life today.",
                    "I love the trees. So majestic.",
                },
                ["Hunt"] = {
                    "Time to hunt! Let's get some practice.",
                    "The thrill of the hunt is unmatched.",
                },
                ["Prey"] = {
                    "There's prey nearby. I can smell it.",
                    "Stalk the prey. Be patient.",
                },
                ["Wild"] = {
                    "The wild is where I feel most at home.",
                    "Wild country. Perfect for a hunter.",
                },
                ["Meadow"] = {
                    "A peaceful meadow. Good place to rest.",
                },
                ["Ridge"] = {
                    "High ground. Always take the high ground.",
                },
            },
            Entities = {
                ["Boar"] = {
                    Generic = {
                        "A fine boar! Let's see how tough it is.",
                        "Boars are stubborn little beasts.",
                    },
                },
                ["Wolf"] = {
                    Generic = {
                        "A wolf! Let's test your reflexes.",
                        "Wolves are noble creatures.",
                    },
                },
                ["Bear"] = {
                    Generic = {
                        "A bear! This will be a good test.",
                        "Bears are strong, but we're stronger.",
                    },
                },
                ["Cat"] = {
                    Generic = {
                        "A cat! Quick and agile, just like me.",
                    },
                },
                ["Beast"] = {
                    Generic = {
                        "A beast to hunt! Let's go.",
                        "Beasts are always fun to track.",
                    },
                },
                ["Creature"] = {
                    Generic = {
                        "A creature in sight. Let's observe it.",
                    },
                },
                ["Pet"] = {
                    Generic = {
                        "Good boy! Good girl!",
                        "My pet is the best!",
                    },
                },
                ["Gorilla"] = {
                    Generic = {
                        "Gorilla, you big hairy beast!",
                        "Show 'em what a real ape can do!",
                    },
                },
            },
        },
        Hates = {
            Places = {
                ["Stormwind"] = {
                    "Stormwind's nobles think they're so fancy.",
                    "I'd rather be anywhere but Stormwind.",
                },
                ["Night Elf"] = {
                    "Night Elves are so arrogant.",
                    "Tree-huggers... they don't know a real hunter when they see one.",
                },
                ["Elven"] = {
                    "Elven arrogance is unbearable.",
                },
                ["High Elf"] = {
                    "High Elves think they're better than everyone.",
                },
                ["Darnassus"] = {
                    "Darnassus is full of tree-hugging nobles.",
                },
                ["Teldrassil"] = {
                    "A floating tree. The futility of trying to climb your way to the heavens.",
                },
                ["Tree"] = {
                    "Tree-huggers... they don't know a real hunter when they see one.",
                },
                ["Tree-hugger"] = {
                    "Tree-huggers... they don't know a real hunter when they see one.",
                },
                ["Tree hugger"] = {
                    "Tree-huggers... they don't know a real hunter when they see one.",
                },
            },
            Entities = {
                ["Night Elf"] = {
                    Generic = {
                        "Night Elves are so arrogant.",
                        "Tree-huggers... they don't know a real hunter when they see one.",
                    },
                },
                ["Elven"] = {
                    Generic = {
                        "Elven arrogance is unbearable.",
                    },
                },
                ["Elf"] = {
                    Generic = {
                        "Elves think they're better than everyone.",
                    },
                },
                ["Troll"] = {
                    Generic = {
                        "Trolls are ugly and smelly.",
                    },
                },
                ["Scourge"] = {
                    Generic = {
                        "Scourge are the worst kind of undead.",
                    },
                },
                ["Undead"] = {
                    Generic = {
                        "Undead are just walking corpses.",
                    },
                },
                ["Zombie"] = {
                    Generic = {
                        "Zombies are just rotting flesh.",
                    },
                },
            },
        },
    },

    zones = {
        ["Dun Modir"] = {
            lines = {
                "Home sweet home! Smells like forge and ale.",
                "Cold enough for ya? I love it!",
                "Dun Modir... the heart of the mountain!",
                "Best brew is right around the corner.",
                "Who needs a coat when you've got Dwarf pride?",
            }
        },
        ["Coldridge Valley"] = {
            lines = {
                "Plenty of boar to hunt here!",
                "Coldridge is a bit drafty, isn't it?",
                "Keep your eyes open, there's danger in the brush.",
                "I could spend all day in these hills.",
                "Fresh air and fresh prey!",
            }
        },
    }
}