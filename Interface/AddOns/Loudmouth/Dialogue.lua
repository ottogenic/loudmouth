Loudmouth = Loudmouth or {}
Loudmouth.Dialogue = {
    actions = {
        ["AUTO_SHOT"] = {
            weight = 1/300,
            lines = {
                "Pew!",
                "Take that, ya scallywag!",
                "Just a little tickle!",
                "Bite the bullet!",
            }
        },
        ["AIMED_SHOT"] = {
            weight = 1/300,
            lines = {
                "Bullseye!",
                "Right in the kisser!",
                "Couldn't miss if I tried!",
                "Hold still, will ya?",
            }
        },
        ["TRAP"] = {
            weight = 1/10,
            lines = {
                "Gotcha in a pinch!",
                "Nowhere to run now!",
                "Surprise!",
                "Stay put!",
            }
        },
        ["PET_ATTACK"] = {
            weight = 1/20,
            lines = {
                "Get 'em, you big hairy beast!",
                "Go on, Gorilla, smash them to bits!",
                "Show 'em what a real ape can do!",
                "Squeeze 'em, ya big lug!",
            }
        },
        ["MULTISHOT"] = {
            weight = 1/50,
            lines = {
                "Rain 'em down!",
                "Too many for you?",
                "Spread the love!",
            }
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
