Loudmouth = Loudmouth or {}
Loudmouth._RawPersonalities = Loudmouth._RawPersonalities or {}

Loudmouth._RawPersonalities["DwarfFemaleHunterQuirky"] = {
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