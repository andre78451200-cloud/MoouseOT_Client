SpelllistSettings = {
    ['Default'] = {
        iconFile = '/images/game/spells/spell-icons-32x32',
        iconSize = {
            width = 32,
            height = 32
        },
        spellListWidth = 210,
        spellWindowWidth = 550,
        spellOrder = {'Animate Dead', 'Annihilation', "Apprentice's Strike", 'Arrow Call', 'Avalanche', 'Avatar of Balance', 'Balanced Brawl', 'Berserk',
                      'Blood Rage', 'Bruise Bane', 'Brutal Strike', 'Buzz', 'Cancel Invisibility', 'Challenge',
                      'Chained Penance', 'Chameleon', 'Charge', 'Chill Out', 'Conjure Arrow', 'Conjure Bolt', 'Conjure Explosive Arrow',
                      'Conjure Piercing Bolt', 'Conjure Poisoned Arrow', 'Conjure Power Bolt', 'Conjure Sniper Arrow',
                      'Convince Creature', 'Creature Illusion', 'Cure Bleeding', 'Cure Burning', 'Cure Curse',
                      'Cure Electrification', 'Cure Poison', 'Cure Poison Rune', 'Curse', 'Death Strike',
                      'Desintegrate', 'Destroy Field', 'Devastating Knockout', 'Divine Caldera', 'Divine Healing', 'Divine Missile', 'Double Jab',
                      'Electrify', 'Enchant Party', 'Enchant Spear', 'Enchant Staff', 'Enlighten Party', 'Energy Beam', 'Energy Field',
                      'Energy Strike', 'Energy Wall', 'Energy Wave', 'Energybomb', 'Envenom', 'Eternal Winter',
                      'Ethereal Spear', 'Explosion', 'Fierce Berserk', 'Find Person', 'Fire Field', 'Fire Wall',
                      'Fire Wave', 'Fireball', 'Firebomb', 'Flame Strike', 'Flurry of Blows', 'Focus Harmony', 'Focus Serenity', 'Food', 'Forceful Uppercut', 'Front Sweep', 'Great Energy Beam',
                      'Great Fireball', 'Great Light', 'Greater Flurry of Blows', 'Greater Tiger Clash', 'Groundshaker', 'Haste', 'Heal Friend', 'Heal Party',
                      'Heavy Magic Missile', 'Hells Core', 'Holy Flash', 'Holy Missile', 'Ice Strike', 'Ice Wave',
                      'Icicle', 'Ignite', 'Inflict Wound', 'Intense Healing', 'Intense Healing Rune', 'Intense Recovery',
                      'Intense Wound Cleansing', 'Invisibility', 'Levitate', 'Light', 'Light Healing',
                      'Light Magic Missile', 'Lightning', 'Magic Patch', 'Magic Rope', 'Magic Shield', 'Magic Wall',
                      'Mass Healing', 'Mass Spirit Mend', 'Mentor Other', 'Mud Attack', 'Mystic Repulse', 'Paralyze', 'Physical Strike', 'Poison Bomb', 'Poison Field',
                      'Poison Wall', 'Practise Fire Wave', 'Practise Healing', 'Practise Magic Missile', 'Protect Party',
                      'Protector', 'Rage of the Skies', 'Recovery', 'Restore Balance', 'Salvation', 'Scorch',
                      'Sharpshooter', 'Soulfire', 'Spirit Mend', 'Spiritual Outburst', 'Stalagmite', 'Stone Shower', 'Strong Energy Strike',
                      'Strong Ethereal Spear', 'Strong Flame Strike', 'Strong Haste', 'Strong Ice Strike',
                      'Strong Ice Wave', 'Strong Terra Strike', 'Sudden Death', 'Summon Creature', 'Summon Monk Familiar', 'Sweeping Takedown', 'Swift Foot', 'Swift Jab',
                      'Terra Strike', 'Terra Wave', 'Thunderstorm', 'Tiger Clash', 'Train Party', 'Ultimate Energy Strike',
                      'Ultimate Flame Strike', 'Ultimate Healing', 'Ultimate Healing Rune', 'Ultimate Ice Strike',
                      'Ultimate Light', 'Ultimate Terra Strike', 'Virtue of Harmony', 'Virtue of Justice', 'Virtue of Sustain', 'Whirlwind Throw', 'Wild Growth', 'Wound Cleansing',
                      'Wrath of Nature'}
    } --[[,
  ['Custom'] =  {
    iconFile = '/images/game/spells/custom',
    iconSize = {width = 32, height = 32},
    spellOrder = {
      'Chain Lighting'
      ,'Chain Healing'
      ,'Divine Chain'
      ,'Berserk Chain'
      ,'Cheat death'
      ,'Brutal Charge'
      ,'Empower Summons'
      ,'Summon Doppelganger'
    }
  }]]
}

SpellInfo = {
    ['Default'] = {
        ['Death Strike'] = {
            id = 87,
            words = 'exori mort',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'deathstrike',
            mana = 20,
            level = 16,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Flame Strike'] = {
            id = 89,
            words = 'exori flam',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'flamestrike',
            mana = 20,
            level = 14,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Strong Flame Strike'] = {
            id = 150,
            words = 'exori gran flam',
            exhaustion = 8000,
            premium = true,
            type = 'Instant',
            icon = 'strongflamestrike',
            mana = 60,
            level = 70,
            soul = 0,
            group = {
                [1] = 2000,
                [4] = 8000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Ultimate Flame Strike'] = {
            id = 154,
            words = 'exori max flam',
            exhaustion = 30000,
            premium = true,
            type = 'Instant',
            icon = 'ultimateflamestrike',
            mana = 100,
            level = 90,
            soul = 0,
            group = {
                [1] = 4000,
                [7] = 30000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Energy Strike'] = {
            id = 88,
            words = 'exori vis',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'energystrike',
            mana = 20,
            level = 12,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Strong Energy Strike'] = {
            id = 151,
            words = 'exori gran vis',
            exhaustion = 8000,
            premium = true,
            type = 'Instant',
            icon = 'strongenergystrike',
            mana = 60,
            level = 80,
            soul = 0,
            group = {
                [1] = 2000,
                [4] = 8000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Ultimate Energy Strike'] = {
            id = 155,
            words = 'exori max vis',
            exhaustion = 30000,
            premium = true,
            type = 'Instant',
            icon = 'ultimateenergystrike',
            mana = 100,
            level = 100,
            soul = 0,
            group = {
                [1] = 4000,
                [7] = 30000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Whirlwind Throw'] = {
            id = 107,
            words = 'exori hur',
            exhaustion = 6000,
            premium = true,
            type = 'Instant',
            icon = 'whirlwindthrow',
            mana = 40,
            level = 28,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Fire Wave'] = {
            id = 19,
            words = 'exevo flam hur',
            exhaustion = 4000,
            premium = false,
            type = 'Instant',
            icon = 'firewave',
            mana = 25,
            level = 18,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Ethereal Spear'] = {
            id = 111,
            words = 'exori con',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'etherealspear',
            mana = 25,
            level = 23,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Strong Ethereal Spear'] = {
            id = 57,
            words = 'exori gran con',
            exhaustion = 8000,
            premium = true,
            type = 'Instant',
            icon = 'strongetherealspear',
            mana = 55,
            level = 90,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Energy Beam'] = {
            id = 22,
            words = 'exevo vis lux',
            exhaustion = 4000,
            premium = false,
            type = 'Instant',
            icon = 'energybeam',
            mana = 40,
            level = 23,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Great Energy Beam'] = {
            id = 23,
            words = 'exevo gran vis lux',
            exhaustion = 6000,
            premium = false,
            type = 'Instant',
            icon = 'greatenergybeam',
            mana = 110,
            level = 29,
            soul = 0,
            group = {
                [1] = 2000,
                [8] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Groundshaker'] = {
            id = 106,
            words = 'exori mas',
            exhaustion = 8000,
            premium = true,
            type = 'Instant',
            icon = 'groundshaker',
            mana = 160,
            level = 33,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Berserk'] = {
            id = 80,
            words = 'exori',
            exhaustion = 4000,
            premium = true,
            type = 'Instant',
            icon = 'berserk',
            mana = 115,
            level = 35,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Annihilation'] = {
            id = 62,
            words = 'exori gran ico',
            exhaustion = 30000,
            premium = true,
            type = 'Instant',
            icon = 'annihilation',
            mana = 300,
            level = 110,
            soul = 0,
            group = {
                [1] = 4000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Brutal Strike'] = {
            id = 61,
            words = 'exori ico',
            exhaustion = 6000,
            premium = true,
            type = 'Instant',
            icon = 'brutalstrike',
            mana = 30,
            level = 16,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Front Sweep'] = {
            id = 59,
            words = 'exori min',
            exhaustion = 6000,
            premium = true,
            type = 'Instant',
            icon = 'frontsweep',
            mana = 200,
            level = 70,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Inflict Wound'] = {
            id = 141,
            words = 'utori kor',
            exhaustion = 30000,
            premium = true,
            type = 'Instant',
            icon = 'inflictwound',
            mana = 30,
            level = 40,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Ignite'] = {
            id = 138,
            words = 'utori flam',
            exhaustion = 30000,
            premium = true,
            type = 'Instant',
            icon = 'ignite',
            mana = 30,
            level = 26,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Lightning'] = {
            id = 149,
            words = 'exori amp vis',
            exhaustion = 8000,
            premium = true,
            type = 'Instant',
            icon = 'lightning',
            mana = 60,
            level = 55,
            soul = 0,
            group = {
                [1] = 2000,
                [4] = 8000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Curse'] = {
            id = 139,
            words = 'utori mort',
            exhaustion = 50000,
            premium = true,
            type = 'Instant',
            icon = 'curse',
            mana = 30,
            level = 75,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Electrify'] = {
            id = 140,
            words = 'utori vis',
            exhaustion = 30000,
            premium = true,
            type = 'Instant',
            icon = 'electrify',
            mana = 30,
            level = 34,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Energy Wave'] = {
            id = 13,
            words = 'exevo vis hur',
            exhaustion = 8000,
            premium = false,
            type = 'Instant',
            icon = 'energywave',
            mana = 170,
            level = 38,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Rage of the Skies'] = {
            id = 119,
            words = 'exevo gran mas vis',
            exhaustion = 40000,
            premium = true,
            type = 'Instant',
            icon = 'rageoftheskies',
            mana = 600,
            level = 55,
            soul = 0,
            group = {
                [1] = 4000,
                [6] = 40000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Fierce Berserk'] = {
            id = 105,
            words = 'exori gran',
            exhaustion = 6000,
            premium = true,
            type = 'Instant',
            icon = 'fierceberserk',
            mana = 340,
            level = 90,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Hells Core'] = {
            id = 24,
            words = 'exevo gran mas flam',
            exhaustion = 40000,
            premium = true,
            type = 'Instant',
            icon = 'hellscore',
            mana = 1100,
            level = 60,
            soul = 0,
            group = {
                [1] = 4000,
                [6] = 40000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Holy Flash'] = {
            id = 143,
            words = 'utori san',
            exhaustion = 40000,
            premium = true,
            type = 'Instant',
            icon = 'holyflash',
            mana = 30,
            level = 70,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Divine Missile'] = {
            id = 122,
            words = 'exori san',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'divinemissile',
            mana = 20,
            level = 40,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Divine Caldera'] = {
            id = 124,
            words = 'exevo mas san',
            exhaustion = 4000,
            premium = true,
            type = 'Instant',
            icon = 'divinecaldera',
            mana = 160,
            level = 50,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Physical Strike'] = {
            id = 148,
            words = 'exori moe ico',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'physicalstrike',
            mana = 20,
            level = 16,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Eternal Winter'] = {
            id = 118,
            words = 'exevo gran mas frigo',
            exhaustion = 40000,
            premium = true,
            type = 'Instant',
            icon = 'eternalwinter',
            mana = 1050,
            level = 60,
            soul = 0,
            group = {
                [1] = 4000,
                [6] = 40000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Ice Strike'] = {
            id = 112,
            words = 'exori frigo',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'icestrike',
            mana = 20,
            level = 15,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 5, 2, 6}
        },
        ['Strong Ice Strike'] = {
            id = 152,
            words = 'exori gran frigo',
            exhaustion = 8000,
            premium = true,
            type = 'Instant',
            icon = 'strongicestrike',
            mana = 60,
            level = 80,
            soul = 0,
            group = {
                [1] = 2000,
                [4] = 8000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Ultimate Ice Strike'] = {
            id = 156,
            words = 'exori max frigo',
            exhaustion = 30000,
            premium = true,
            type = 'Instant',
            icon = 'ultimateicestrike',
            mana = 100,
            level = 100,
            soul = 0,
            group = {
                [1] = 4000,
                [7] = 30000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Ice Wave'] = {
            id = 121,
            words = 'exevo frigo hur',
            exhaustion = 4000,
            premium = false,
            type = 'Instant',
            icon = 'icewave',
            mana = 25,
            level = 18,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Strong Ice Wave'] = {
            id = 43,
            words = 'exevo gran frigo hur',
            exhaustion = 8000,
            premium = true,
            type = 'Instant',
            icon = 'strongicewave',
            mana = 170,
            level = 40,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Envenom'] = {
            id = 142,
            words = 'utori pox',
            exhaustion = 40000,
            premium = true,
            type = 'Instant',
            icon = 'envenom',
            mana = 30,
            level = 50,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Terra Strike'] = {
            id = 113,
            words = 'exori tera',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'terrastrike',
            mana = 20,
            level = 13,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {1, 5, 2, 6}
        },
        ['Strong Terra Strike'] = {
            id = 153,
            words = 'exori gran tera',
            exhaustion = 8000,
            premium = true,
            type = 'Instant',
            icon = 'strongterrastrike',
            mana = 60,
            level = 70,
            soul = 0,
            group = {
                [1] = 2000,
                [4] = 8000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Ultimate Terra Strike'] = {
            id = 157,
            words = 'exori max tera',
            exhaustion = 30000,
            premium = true,
            type = 'Instant',
            icon = 'ultimateterrastrike',
            mana = 100,
            level = 90,
            soul = 0,
            group = {
                [1] = 4000,
                [7] = 30000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Terra Wave'] = {
            id = 120,
            words = 'exevo tera hur',
            exhaustion = 4000,
            premium = false,
            type = 'Instant',
            icon = 'terrawave',
            mana = 210,
            level = 38,
            soul = 0,
            group = {
                [1] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Wrath of Nature'] = {
            id = 56,
            words = 'exevo gran mas tera',
            exhaustion = 40000,
            premium = true,
            type = 'Instant',
            icon = 'wrathofnature',
            mana = 700,
            level = 55,
            soul = 0,
            group = {
                [1] = 4000,
                [6] = 40000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Light Healing'] = {
            id = 1,
            words = 'exura',
            exhaustion = 1000,
            premium = false,
            type = 'Instant',
            icon = 'lighthealing',
            mana = 20,
            level = 9,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {1, 2, 3, 5, 6, 7}
        },
        ['Wound Cleansing'] = {
            id = 123,
            words = 'exura ico',
            exhaustion = 1000,
            premium = false,
            type = 'Instant',
            icon = 'woundcleansing',
            mana = 40,
            level = 10,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Intense Wound Cleansing'] = {
            id = 158,
            words = 'exura gran ico',
            exhaustion = 600000,
            premium = true,
            type = 'Instant',
            icon = 'intensewoundcleansing',
            mana = 200,
            level = 80,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Cure Bleeding'] = {
            id = 144,
            words = 'exana kor',
            exhaustion = 6000,
            premium = true,
            type = 'Instant',
            icon = 'curebleeding',
            mana = 30,
            level = 30,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Cure Electrification'] = {
            id = 146,
            words = 'exana vis',
            exhaustion = 6000,
            premium = true,
            type = 'Instant',
            icon = 'curseelectrification',
            mana = 30,
            level = 22,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Cure Poison'] = {
            id = 29,
            words = 'exana pox',
            exhaustion = 6000,
            premium = false,
            type = 'Instant',
            icon = 'curepoison',
            mana = 30,
            level = 10,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {1, 2, 3, 4, 5, 6, 7, 8}
        },
        ['Cure Burning'] = {
            id = 145,
            words = 'exana flam',
            exhaustion = 6000,
            premium = true,
            type = 'Instant',
            icon = 'cureburning',
            mana = 30,
            level = 30,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Cure Curse'] = {
            id = 147,
            words = 'exana mort',
            exhaustion = 6000,
            premium = true,
            type = 'Instant',
            icon = 'curecurse',
            mana = 40,
            level = 80,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Recovery'] = {
            id = 159,
            words = 'utura',
            exhaustion = 60000,
            premium = true,
            type = 'Instant',
            icon = 'recovery',
            mana = 75,
            level = 50,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {4, 8, 3, 7}
        },
        ['Intense Recovery'] = {
            id = 160,
            words = 'utura gran',
            exhaustion = 60000,
            premium = true,
            type = 'Instant',
            icon = 'intenserecovery',
            mana = 165,
            level = 100,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {4, 8, 3, 7}
        },
        ['Salvation'] = {
            id = 36,
            words = 'exura gran san',
            exhaustion = 1000,
            premium = true,
            type = 'Instant',
            icon = 'salvation',
            mana = 210,
            level = 60,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Intense Healing'] = {
            id = 2,
            words = 'exura gran',
            exhaustion = 1000,
            premium = false,
            type = 'Instant',
            icon = 'intensehealing',
            mana = 70,
            level = 20,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {1, 2, 3, 5, 6, 7}
        },
        ['Heal Friend'] = {
            id = 84,
            words = 'exura sio',
            exhaustion = 1000,
            premium = true,
            type = 'Instant',
            icon = 'healfriend',
            mana = 140,
            level = 18,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = true,
            vocations = {2, 6}
        },
        ['Ultimate Healing'] = {
            id = 3,
            words = 'exura vita',
            exhaustion = 1000,
            premium = false,
            type = 'Instant',
            icon = 'ultimatehealing',
            mana = 160,
            level = 30,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Mass Healing'] = {
            id = 82,
            words = 'exura gran mas res',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'masshealing',
            mana = 150,
            level = 36,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Divine Healing'] = {
            id = 125,
            words = 'exura san',
            exhaustion = 1000,
            premium = false,
            type = 'Instant',
            icon = 'divinehealing',
            mana = 160,
            level = 35,
            soul = 0,
            group = {
                [2] = 1000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Light'] = {
            id = 10,
            words = 'utevo lux',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'light',
            mana = 20,
            level = 8,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 3, 4, 5, 6, 7, 8}
        },
        ['Find Person'] = {
            id = 20,
            words = 'exiva',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'findperson',
            mana = 20,
            level = 8,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = true,
            vocations = {1, 2, 3, 4, 5, 6, 7, 8}
        },
        ['Magic Rope'] = {
            id = 76,
            words = 'exani tera',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'magicrope',
            mana = 20,
            level = 9,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 3, 4, 5, 6, 7, 8}
        },
        ['Levitate'] = {
            id = 81,
            words = 'exani hur',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'levitate',
            mana = 50,
            level = 12,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = true,
            vocations = {1, 2, 3, 4, 5, 6, 7, 8}
        },
        ['Great Light'] = {
            id = 11,
            words = 'utevo gran lux',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'greatlight',
            mana = 60,
            level = 13,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 3, 4, 5, 6, 7, 8}
        },
        ['Magic Shield'] = {
            id = 44,
            words = 'utamo vita',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'magicshield',
            mana = 50,
            level = 14,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Haste'] = {
            id = 6,
            words = 'utani hur',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'haste',
            mana = 60,
            level = 14,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 3, 4, 5, 6, 7, 8}
        },
        ['Charge'] = {
            id = 131,
            words = 'utani tempo hur',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'charge',
            mana = 100,
            level = 25,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Swift Foot'] = {
            id = 134,
            words = 'utamo tempo san',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'swiftfoot',
            mana = 400,
            level = 55,
            soul = 0,
            group = {
                [3] = 2000,
                [6] = 10000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Challenge'] = {
            id = 93,
            words = 'exeta res',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'challenge',
            mana = 30,
            level = 20,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {8}
        },
        ['Strong Haste'] = {
            id = 39,
            words = 'utani gran hur',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'stronghaste',
            mana = 100,
            level = 20,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Creature Illusion'] = {
            id = 38,
            words = 'utevo res ina',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'creatureillusion',
            mana = 100,
            level = 23,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = true,
            vocations = {1, 2, 5, 6}
        },
        ['Ultimate Light'] = {
            id = 75,
            words = 'utevo vis lux',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'ultimatelight',
            mana = 140,
            level = 26,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Cancel Invisibility'] = {
            id = 90,
            words = 'exana ina',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'cancelinvisibility',
            mana = 200,
            level = 26,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Invisibility'] = {
            id = 45,
            words = 'utana vid',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'invisible',
            mana = 440,
            level = 35,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Sharpshooter'] = {
            id = 135,
            words = 'utito tempo san',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'sharpshooter',
            mana = 450,
            level = 60,
            soul = 0,
            group = {
                [3] = 2000,
                [6] = 10000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Protector'] = {
            id = 132,
            words = 'utamo tempo',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'protector',
            mana = 200,
            level = 55,
            soul = 0,
            group = {
                [3] = 2000,
                [6] = 2000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Blood Rage'] = {
            id = 133,
            words = 'utito tempo',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'bloodrage',
            mana = 290,
            level = 60,
            soul = 0,
            group = {
                [3] = 2000,
                [6] = 2000
            },
            parameter = false,
            vocations = {4, 8}
        },
        ['Train Party'] = {
            id = 126,
            words = 'utito mas sio',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'trainparty',
            mana = 'Var.',
            level = 32,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {8}
        },
        ['Protect Party'] = {
            id = 127,
            words = 'utamo mas sio',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'protectparty',
            mana = 'Var.',
            level = 32,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {7}
        },
        ['Heal Party'] = {
            id = 128,
            words = 'utura mas sio',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'healparty',
            mana = 'Var.',
            level = 32,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {6}
        },
        ['Enchant Party'] = {
            id = 129,
            words = 'utori mas sio',
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'enchantparty',
            mana = 'Var.',
            level = 32,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {5}
        },
        ['Summon Creature'] = {
            id = 9,
            words = 'utevo res',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'summoncreature',
            mana = 'Var.',
            level = 25,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = true,
            vocations = {1, 2, 5, 6}
        },
        ['Conjure Arrow'] = {
            id = 51,
            words = 'exevo con',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'conjurearrow',
            mana = 100,
            level = 13,
            soul = 1,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Food'] = {
            id = 42,
            words = 'exevo pan',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'food',
            mana = 120,
            level = 14,
            soul = 1,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Conjure Poisoned Arrow'] = {
            id = 48,
            words = 'exevo con pox',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'poisonedarrow',
            mana = 130,
            level = 16,
            soul = 2,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Conjure Bolt'] = {
            id = 79,
            words = 'exevo con mort',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'conjurebolt',
            mana = 140,
            level = 17,
            soul = 2,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Conjure Sniper Arrow'] = {
            id = 108,
            words = 'exevo con hur',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'sniperarrow',
            mana = 160,
            level = 24,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Conjure Explosive Arrow'] = {
            id = 49,
            words = 'exevo con flam',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'explosivearrow',
            mana = 290,
            level = 25,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Conjure Piercing Bolt'] = {
            id = 109,
            words = 'exevo con grav',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'piercingbolt',
            mana = 180,
            level = 33,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Enchant Staff'] = {
            id = 92,
            words = 'exeta vis',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'enchantstaff',
            mana = 80,
            level = 41,
            soul = 0,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {5}
        },
        ['Enchant Spear'] = {
            id = 110,
            words = 'exeta con',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'enchantspear',
            mana = 350,
            level = 45,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },
        ['Conjure Power Bolt'] = {
            id = 95,
            words = 'exevo con vis',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'powerbolt',
            mana = 800,
            level = 59,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {7}
        },
        ['Poison Field'] = {
            id = 26,
            words = 'adevo grav pox',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'poisonfield',
            mana = 200,
            level = 14,
            soul = 1,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Light Magic Missile'] = {
            id = 7,
            words = 'adori min vis',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'lightmagicmissile',
            mana = 120,
            level = 15,
            soul = 1,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Fire Field'] = {
            id = 25,
            words = 'adevo grav flam',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'firefield',
            mana = 240,
            level = 15,
            soul = 1,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Fireball'] = {
            id = 15,
            words = 'adori flam',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'fireball',
            mana = 460,
            level = 27,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Energy Field'] = {
            id = 27,
            words = 'adevo grav vis',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'energyfield',
            mana = 320,
            level = 18,
            soul = 2,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Stalagmite'] = {
            id = 77,
            words = 'adori tera',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'stalagmite',
            mana = 400,
            level = 24,
            soul = 2,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 5, 2, 6}
        },
        ['Great Fireball'] = {
            id = 16,
            words = 'adori mas flam',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'greatfireball',
            mana = 530,
            level = 30,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Heavy Magic Missile'] = {
            id = 8,
            words = 'adori vis',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'heavymagicmissile',
            mana = 350,
            level = 25,
            soul = 2,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 5, 2, 6}
        },
        ['Poison Bomb'] = {
            id = 91,
            words = 'adevo mas pox',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'poisonbomb',
            mana = 520,
            level = 25,
            soul = 2,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Firebomb'] = {
            id = 17,
            words = 'adevo mas flam',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'firebomb',
            mana = 600,
            level = 27,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Soulfire'] = {
            id = 50,
            words = 'adevo res flam',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'soulfire',
            mana = 600,
            level = 27,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Poison Wall'] = {
            id = 32,
            words = 'adevo mas grav pox',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'poisonwall',
            mana = 640,
            level = 29,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Explosion'] = {
            id = 18,
            words = 'adevo mas hur',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'explosion',
            mana = 570,
            level = 31,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Fire Wall'] = {
            id = 28,
            words = 'adevo mas grav flam',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'firewall',
            mana = 780,
            level = 33,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Energybomb'] = {
            id = 55,
            words = 'adevo mas vis',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'energybomb',
            mana = 880,
            level = 37,
            soul = 5,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Energy Wall'] = {
            id = 33,
            words = 'adevo mas grav vis',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'energywall',
            mana = 1000,
            level = 41,
            soul = 5,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Sudden Death'] = {
            id = 21,
            words = 'adori gran mort',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'suddendeath',
            mana = 985,
            level = 45,
            soul = 5,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Cure Poison Rune'] = {
            id = 31,
            words = 'adana pox',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'antidote',
            mana = 200,
            level = 15,
            soul = 1,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Intense Healing Rune'] = {
            id = 4,
            words = 'adura gran',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'intensehealingrune',
            mana = 240,
            level = 15,
            soul = 2,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Ultimate Healing Rune'] = {
            id = 5,
            words = 'adura vita',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'ultimatehealingrune',
            mana = 400,
            level = 24,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Convince Creature'] = {
            id = 12,
            words = 'adeta sio',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'convincecreature',
            mana = 200,
            level = 16,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Animate Dead'] = {
            id = 83,
            words = 'adana mort',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'animatedead',
            mana = 600,
            level = 27,
            soul = 5,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 5, 6}
        },
        ['Chameleon'] = {
            id = 14,
            words = 'adevo ina',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'chameleon',
            mana = 600,
            level = 27,
            soul = 2,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Destroy Field'] = {
            id = 30,
            words = 'adito grav',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'destroyfield',
            mana = 120,
            level = 17,
            soul = 2,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 3, 5, 6, 7}
        },
        ['Desintegrate'] = {
            id = 78,
            words = 'adito tera',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'desintegrate',
            mana = 200,
            level = 21,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 2, 3, 5, 6, 7}
        },
        ['Magic Wall'] = {
            id = 86,
            words = 'adevo grav tera',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'magicwall',
            mana = 750,
            level = 32,
            soul = 5,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Wild Growth'] = {
            id = 94,
            words = 'adevo grav vita',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'wildgrowth',
            mana = 600,
            level = 27,
            soul = 5,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Paralyze'] = {
            id = 54,
            words = 'adana ani',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'paralyze',
            mana = 1400,
            level = 54,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Icicle'] = {
            id = 114,
            words = 'adori frigo',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'icicle',
            mana = 460,
            level = 28,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Avalanche'] = {
            id = 115,
            words = 'adori mas frigo',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'avalanche',
            mana = 530,
            level = 30,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Stone Shower'] = {
            id = 116,
            words = 'adori mas tera',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'stoneshower',
            mana = 430,
            level = 28,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {2, 6}
        },
        ['Thunderstorm'] = {
            id = 117,
            words = 'adori mas vis',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'thunderstorm',
            mana = 430,
            level = 28,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {1, 5}
        },
        ['Holy Missile'] = {
            id = 130,
            words = 'adori san',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'holymissile',
            mana = 350,
            level = 27,
            soul = 3,
            group = {
                [3] = 2000
            },
            parameter = false,
            vocations = {3, 7}
        },

    -- fixed spells from OTCv8, version 11.40.5
        ['Summon Paladin Familiar'] = {
            id = 195,
            words = 'utevo gran res sac',
            exhaustion = 1800000,
            premium = true,
            type = 'Instant',
            icon = 'summonpaladinfamiliar',
            mana = 2000,
            level = 200,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {3, 7}
        },
        ['Summon Knight Familiar'] = {
            id = 194,
            words = 'utevo gran res eq',
            exhaustion = 1800000,
            premium = true,
            type = 'Instant',
            icon = 'summonknightfamiliar',
            mana = 1000,
            level = 200,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {4, 8}
        },
        ['Summon Druid Familiar'] = {
            id = 197,
            words = 'utevo gran res dru',
            exhaustion = 1800000,
            premium = true,
            type = 'Instant',
            icon = 'summondruidfamiliar',
            mana = 3000,
            level = 200,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {2, 6}
        },
        ['Summon Sorcerer Familiar'] = {
            id = 196,
            words = 'utevo gran res ven',
            exhaustion = 1800000,
            premium = true,
            type = 'Instant',
            icon = 'summonsorcererfamiliar',
            mana = 3000,
            level = 200,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {1, 5}
        },
        ['Chivalrous Challenge'] = {
            id = 237,
            words = "exeta amp res",
            exhaustion = 2000,
            premium = true,
            type = 'Instant',
            icon = 'chivalrouschallange',
            mana = 80,
            level = 150,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {4, 8}
        },
        ['Fair Wound Cleansing'] = {
            id = 239,
            words = 'exura med ico',
            exhaustion = 1000,
            premium = true,
            type = 'Instant',
            icon = 'fairwoundcleansing',
            mana = 90,
            level = 300,
            soul = 0,
            group = {
                [2] = 1000
            },
            vocations = {4, 8}
        },
        ['Conjure Wand of Darkness'] = {
            id = 92,
            words = 'exevo gran mort',
            exhaustion = 1800000,
            premium = true,
            type = 'Conjure',
            icon = 'conjurewandofdarkness',
            mana = 250,
            level = 41,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {5}
        },
        ['Expose Weakness'] = {
            id = 243,
            words = 'exori moe',
            exhaustion = 12000,
            premium = true,
            type = 'Instant',
            icon = 'exposeweakness',
            mana = 400,
            level = 275,
            soul = 0,
            group = {
                [3] = 2000,
                [5] = 12000
            },
            vocations = {1, 5}
        },
        ['Sap Strenght'] = {
            id = 244,
            words = 'exori kor',
            exhaustion = 12000,
            premium = true,
            type = 'Instant',
            icon = 'sapstrenght',
            mana = 300,
            level = 175,
            soul = 0,
            group = {
                [3] = 2000,
                [5] = 12000
            },
            vocations = {1, 5}
        },
        ['Great Fire Wave'] = {
            id = 240,
            words = 'exevo gran flam hur',
            exhaustion = 4000,
            premium = true,
            type = 'Instant',
            icon = 'greatfirewave',
            mana = 120,
            level = 38,
            soul = 0,
            group = {
                [1] = 2000
            },
            vocations = {1, 5}
        },
        ['Restoration'] = {
            id = 241,
            words = "exura max vita",
            exhaustion = 6000,
            premium = true,
            type = 'Instant',
            icon = 'restoration',
            mana = 260,
            level = 300,
            soul = 0,
            group = {
                [2] = 1000
            },
            vocations = {1, 2, 5, 6}
        },
        ["Nature's Embrace"] = {
            id = 242,
            words = 'exura gran sio',
            exhaustion = 60000,
            premium = true,
            type = 'Instant',
            icon = 'naturesembrace',
            mana = 400,
            level = 275,
            soul = 0,
            group = {
                [2] = 1000
            },
            vocations = {2, 6},
            parameter = true
        },
        ['Divine Dazzle'] = {
            id = 238,
            words = 'exana amp res',
            exhaustion = 16000,
            premium = true,
            type = 'Instant',
            icon = 'divinedazzle',
            mana = 80,
            level = 250,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {7}
        },
    -- /fixed spells from OTCv8, version 11.40.5

    -- spells from version 9.80
        ["Practise Healing"] = {
            id = 166,
            words = 'exura dis',
            exhaustion = 1000,
            premium = false,
            type = 'Instant',
            icon = 'practisehealing',
            mana = 5,
            level = 1,
            soul = 0,
            group = {
                [2] = 1000
            },
            vocations = {0}
        },
        ["Practise Fire Wave"] = {
            id = 167,
            words = 'exevo dis flam hur',
            exhaustion = 4000,
            premium = false,
            type = 'Instant',
            icon = 'practisefirewave',
            mana = 5,
            level = 1,
            soul = 0,
            group = {
                [1] = 2000
            },
            vocations = {0}
        },
        ["Practise Magic Missile"] = {
            id = 168,
            words = 'adori dis min vis',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'practisemagicmissile',
            mana = 5,
            level = 1,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {0}
        },
        ["Apprentice's Strike"] = {
            id = 169,
            words = 'exori min flam',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'apprenticesstrike',
            mana = 6,
            level = 8,
            soul = 0,
            group = {
                [1] = 2000
            },
            vocations = {1, 2, 5, 6}
        },
 
    -- /spells from version 9.80

    -- spells from version 10.55
        ["Mud Attack"] = {
            id = 172,
            words = 'exori infir tera',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'mudattack',
            mana = 6,
            level = 1,
            soul = 0,
            group = {
                [1] = 2000
            },
            vocations = {2, 6}
        },
        ["Chill Out"] = {
            id = 173,
            words = 'exevo infir frigo hur',
            exhaustion = 4000,
            premium = false,
            type = 'Instant',
            icon = 'chillout',
            mana = 8,
            level = 1,
            soul = 0,
            group = {
                [1] = 2000
            },
            vocations = {2, 6}
        },
        ["Magic Patch"] = {
            id = 174,
            words = 'exura infir',
            exhaustion = 1000,
            premium = false,
            type = 'Instant',
            icon = 'magicpatch',
            mana = 6,
            level = 1,
            soul = 0,
            group = {
                [2] = 1000
            },
            vocations = {1,2, 3, 5, 6, 7}
        },
        ["Bruise Bane"] = {
            id = 175,
            words = 'exura infir ico',
            exhaustion = 1000,
            premium = false,
            type = 'Instant',
            icon = 'bruisebane',
            mana = 10,
            level = 1,
            soul = 0,
            group = {
                [2] = 1000
            },
            vocations = {4, 8}
        },
        ["Arrow Call"] = {
            id = 176,
            words = 'exevo infir con',
            exhaustion = 2000,
            premium = false,
            type = 'Conjure',
            icon = 'arrowcall',
            mana = 10,
            level = 1,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {3, 7}
        },
        ["Buzz"] = {
            id = 177,
            words = 'exori infir vis',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'buzz',
            mana = 6,
            level = 1,
            soul = 0,
            group = {
                [1] = 2000
            },
            vocations = {1, 5}
        },
        ["Scorch"] = {
            id = 178,
            words = 'exevo infir flam hur',
            exhaustion = 4000,
            premium = false,
            type = 'Instant',
            icon = 'scorch',
            mana = 8,
            level = 1,
            soul = 0,
            group = {
                [1] = 2000
            },
            vocations = {1, 5}
        },
    -- /spells from version 10.55


    -- spells from version 11.40.5.409 - removed in new version
        ["Conjure Diamond Arrow"] = {
            id = 192,
            words = 'exevo gran con hur',
            exhaustion = 600000,
            premium = true,
            type = 'Conjure',
            icon = 'conjurediamondarrow',
            mana = 1000,
            level = 150,
            soul = 0,
            group = {
                [3] = 2000
--                conjure = 600000
            },
            vocations = {7}
        },
        ["Conjure Spectral Bolt"] = {
            id = 193,
            words = 'exevo gran con vis',
            exhaustion = 600000,
            premium = true,
            type = 'Conjure',
            icon = 'conjurespectralbolt',
            mana = 1000,
            level = 150,
            soul = 0,
            group = {
                [3] = 2000
--                conjure = 600000
            },
            vocations = {7}
        },
 
    -- /spells from version 11.40.5.409 - removed in new version

    -- spells from version 12.80.11430
        ["Find Fiend"] = {
            id = 20,
            words = 'exiva moe res',
            exhaustion = 2000,
            premium = false,
            type = 'Instant',
            icon = 'findfiend',
            mana = 20,
            level = 25,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {1, 2, 3, 4, 5, 6, 7, 8}
        },
    -- /spells from version 12.80.11430

    -- spells from version 13.10.12852
--[[
        -- adjust tfs id
        ["Avatar of Light"] = {
            id = __TFS_ID__, -- fix me
            words = 'uteta res ven',
            exhaustion = 7200000,
            premium = true,
            type = 'Instant',
            icon = 'avataroflight',
            mana = 1500,
            level = 300,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {7}
        },
        ["Avatar of Nature"] = {
            id = __TFS_ID__, -- fix me
            words = 'uteta res dru',
            exhaustion = 7200000,
            premium = true,
            type = 'Instant',
            icon = 'avatarofnature',
            mana = 2200,
            level = 300,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {6}
        },
        ["Avatar of Steel"] = {
            id = __TFS_ID__, -- fix me
            words = 'uteta res eq',
            exhaustion = 7200000,
            premium = true,
            type = 'Instant',
            icon = 'avatarofsteel',
            mana = 800,
            level = 300,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {8}
        },
        ["Avatar of Storm"] = {
            id = __TFS_ID__, -- fix me
            words = 'uteta res ven',
            exhaustion = 7200000,
            premium = true,
            type = 'Instant',
            icon = 'avatarofstorm',
            mana = 2200,
            level = 300,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {5}
        },
        ["Divine Empowerment"] = {
            id = __TFS_ID__, -- fix me
            words = 'utevo grav san',
            exhaustion = 32000,
            premium = true,
            type = 'Instant',
            icon = 'divineempowerment',
            mana = 500,
            level = 300,
            soul = 0,
            group = {
                [3] = 2000
            },
            vocations = {7}
        },
        ["Divine Grenade"] = {
            id = __TFS_ID__, -- fix me
            words = 'exevo tempo mas san',
            exhaustion = 26000,
            premium = true,
            type = 'Instant',
            icon = 'divinegrenade',
            mana = 160,
            level = 300,
            soul = 0,
            group = {
                [1] = 2000
            },
            vocations = {7}
        },
        ["Executioner's Throw"] = {
            id = __TFS_ID__, -- fix me
            words = 'exori amp kor',
            exhaustion = 18000,
            premium = true,
            type = 'Instant',
            icon = 'executionersthrow',
            mana = 225,
            level = 300,
            soul = 0,
            group = {
                [1] = 2000
            },
            vocations = {8}
        },
        ["Gift of Life"] = {
            id = __TFS_ID__, -- fix me
            words = '? ? ?', -- there is no words
            exhaustion = 108000000,
            premium = true,
            type = 'Instant',
            icon = 'giftoflife',
            mana = 0,
            level = 300,
            soul = 0,
            group = {
                [2] = 0
            },
            vocations = {5, 6, 7, 8}
        },
        ["Great Death Beam"] = {
            id = __TFS_ID__, -- fix me
            words = 'exevo max mort',
            exhaustion = 10000,
            premium = true,
            type = 'Instant',
            icon = 'greatdeathbeam',
            mana = 140,
            level = 300,
            soul = 0,
            group = {
                [1] = 2000,
                [8] = 6000
            },
            vocations = {5}
        },
        ["Ice Burst"] = {
            id = __TFS_ID__, -- fix me
            words = 'exevo ulus frigo',
            exhaustion = 22000,
            premium = true,
            type = 'Instant',
            icon = 'iceburst',
            mana = 230,
            level = 300,
            soul = 0,
            group = {
                [1] = 2000,
                [9] = 6000
            },
            vocations = {6}
        },
        ["Terra Burst"] = {
            id = __TFS_ID__, -- fix me
            words = 'exevo ulus tera',
            exhaustion = 22000,
            premium = true,
            type = 'Instant',
            icon = 'terraburst',
            mana = 230,
            level = 300,
            soul = 0,
            group = {
                [1] = 2000,
                [9] = 6000
            },
            vocations = {6}
        },
    -- /spells from version 13.10.12852
]]
        -- Monk Spells (IDs based on otclient-main/TFS)
        ["Spirit Mend"] = {
            id = 273,
            words = "exura gran tio",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 1000,
            clientId = 161,
            icon = "spiritmend",
            mana = 210,
            level = 80,
            group = {
                [2] = 1000
            },
            vocations = {9, 10}
        },
        ["Virtue of Harmony"] = {
            id = 274,
            words = "utori virtu",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 2000,
            clientId = 162,
            icon = "virtueofharmony",
            mana = 210,
            level = 20,
            group = {
                [3] = 2000
            },
            vocations = {9, 10}
        },
        ["Virtue of Justice"] = {
            id = 275,
            words = "utito virtu",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 10000,
            clientId = 163,
            icon = "virtueofjustice",
            mana = 210,
            level = 20,
            group = {
                [3] = 2000
            },
            vocations = {9, 10}
        },
        ["Virtue of Sustain"] = {
            id = 276,
            words = "utura tio",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 2000,
            clientId = 164,
            icon = "virtueofsustain",
            mana = 210,
            level = 20,
            group = {
                [3] = 2000
            },
            vocations = {9, 10}
        },
        ["Mentor Other"] = {
            id = 277,
            words = "uteta tio",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 2000,
            clientId = 165,
            icon = "mentorother",
            mana = 110,
            level = 150,
            parameter = true,
            group = {
                [3] = 2000
            },
            vocations = {9, 10}
        },
        ["Enlighten Party"] = {
            id = 278,
            words = "utevo mas sio",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 300000,
            clientId = 166,
            icon = "enlightenparty",
            mana = 75,
            level = 32,
            group = {
                [3] = 1000
            },
            vocations = {9, 10}
        },
        ["Focus Harmony"] = {
            id = 279,
            words = "utevo nia",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 120000,
            clientId = 167,
            icon = "focusharmony",
            mana = 500,
            level = 275,
            group = {
                [3] = 2000
            },
            vocations = {9, 10}
        },
        ["Balanced Brawl"] = {
            id = 280,
            words = "exori mas res",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 10000,
            clientId = 168,
            icon = "balancedbrawl",
            mana = 80,
            level = 175,
            group = {
                [3] = 2000
            },
            vocations = {9, 10}
        },
        ["Focus Serenity"] = {
            id = 281,
            words = "utamo tio",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 600000,
            clientId = 169,
            icon = "focusserenity",
            mana = 500,
            level = 150,
            group = {
                [3] = 2000
            },
            vocations = {9, 10}
        },
        ["Summon Monk Familiar"] = {
            id = 282,
            words = "utevo gran res tio",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 0,
            clientId = 170,
            icon = "summonmonkfamiliar",
            mana = 1500,
            level = 200,
            group = {
                [3] = 2000
            },
            vocations = {9, 10}
        },
        ["Avatar of Balance"] = {
            id = 283,
            words = "uteta res tio",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 7200000,
            clientId = 171,
            icon = "avatarofbalance",
            mana = 1200,
            level = 300,
            group = {
                [3] = 2000
            },
            vocations = {9, 10}
        },
        ["Swift Jab"] = {
            id = 284,
            words = "exori infir pug",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 2000,
            clientId = 172,
            icon = "swiftjab",
            mana = 3,
            level = 1,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Double Jab"] = {
            id = 285,
            words = "exori pug",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 4000,
            clientId = 173,
            icon = "doublejab",
            mana = 30,
            level = 14,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Forceful Uppercut"] = {
            id = 286,
            words = "exori gran pug",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 40000,
            clientId = 174,
            icon = "forcefuluppercut",
            mana = 325,
            level = 110,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Flurry of Blows"] = {
            id = 287,
            words = "exori mas pug",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 4000,
            clientId = 175,
            icon = "flurryofblows",
            mana = 110,
            level = 35,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Chained Penance"] = {
            id = 288,
            words = "exori med pug",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 4000,
            clientId = 176,
            icon = "chainedpenance",
            mana = 180,
            level = 70,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Greater Flurry of Blows"] = {
            id = 289,
            words = "exori gran mas pug",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 10000,
            clientId = 177,
            icon = "greaterflurryofblows",
            mana = 300,
            level = 90,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Mystic Repulse"] = {
            id = 290,
            words = "exori amp pug",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 14000,
            clientId = 178,
            icon = "mysticrepulse",
            mana = 150,
            level = 30,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Tiger Clash"] = {
            id = 291,
            words = "exori infir nia",
            type = "Instant",
            premium = false,
            soul = 0,
            exhaustion = 8000,
            clientId = 179,
            icon = "tigerclash",
            mana = 18,
            level = 1,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Greater Tiger Clash"] = {
            id = 292,
            words = "exori nia",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 8000,
            clientId = 180,
            icon = "greatertigerclash",
            mana = 50,
            level = 18,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Devastating Knockout"] = {
            id = 293,
            words = "exori gran nia",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 24000,
            clientId = 181,
            icon = "devastatingknockout",
            mana = 210,
            level = 125,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Sweeping Takedown"] = {
            id = 294,
            words = "exori mas nia",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 8000,
            clientId = 182,
            icon = "sweepingtakedown",
            mana = 195,
            level = 60,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Spiritual Outburst"] = {
            id = 295,
            words = "exori gran mas nia",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 60000,
            clientId = 183,
            icon = "spiritualoutburst",
            mana = 425,
            level = 300,
            group = {
                [1] = 2000
            },
            vocations = {9, 10}
        },
        ["Mass Spirit Mend"] = {
            id = 296,
            words = "exura mas nia",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 8000,
            clientId = 184,
            icon = "massspiritmend",
            mana = 250,
            level = 150,
            group = {
                [2] = 2000
            },
            vocations = {9, 10}
        },
        ["Restore Balance"] = {
            id = 297,
            words = "exura tio sio",
            type = "Instant",
            premium = true,
            soul = 0,
            exhaustion = 2000,
            clientId = 185,
            icon = "restorebalance",
            mana = 120,
            level = 18,
            parameter = true,
            group = {
                [2] = 1000
            },
            vocations = {9, 10}
        }

    } --[[,
  ['Custom'] = {
    ['Chain Lighting'] =           {id = 1, words = 'exori chain vis',        description = 'Chained attack pattern lightning strike.',                     exhaustion = 2000,  premium = false, type = 'Instant', icon = 1,  mana = 650,  level = 90, soul = 0, group = {[1] = 2000}, vocations = {5}},
    ['Chain Healing'] =            {id = 2, words = 'exura chain frigo',      description = 'Chained healing that deals ice damage to adjacent creatures.', exhaustion = 2000,  premium = false, type = 'Instant', icon = 2,  mana = 160,  level = 60, soul = 0, group = {[1] = 2000}, vocations = {6}},
    ['Divine Chain'] =             {id = 3, words = 'exori chain san',        description = 'Chained attack pattern holy strike.',                          exhaustion = 2000,  premium = false, type = 'Instant', icon = 3,  mana = 160,  level = 60, soul = 0, group = {[1] = 2000}, vocations = {7}},
    ['Berserk Chain'] =            {id = 4, words = 'exori chain mas',        description = 'Bouncing exori that challenges creatures.',                    exhaustion = 2000,  premium = false, type = 'Instant', icon = 4,  mana = 160,  level = 60, soul = 0, group = {[1] = 2000}, vocations = {8}},
    ['Cheat death'] =              {id = 5, words = 'exura prohibere mortem', description = 'Recover from an otherwise fatal killing blow.',                exhaustion = 2000,  premium = false, type = 'Instant', icon = 5,  mana = 500,  level = 100, soul = 0, group = {[2] = 2000}, vocations = {6}},
    ['Brutal Charge'] =            {id = 6, words = 'exori tempo hur',        description = 'Quick charge attack that challenges target.',                  exhaustion = 2000,  premium = false, type = 'Instant', icon = 6,  mana = 80,   level = 60, soul = 0, group = {[1] = 2000}, vocations = {8}},
    ['Empower Summons'] =          {id = 7, words = 'utevo gran res',         description = 'Empower summons with extra strength and intelligence.',        exhaustion = 2000,  premium = false, type = 'Instant', icon = 7,  mana = 1800, level = 70, soul = 25, group = {[2] = 2000}, vocations = {6}},
    ['Summon Doppelganger'] =      {id = 8, words = 'utevo duplex res',       description = 'Summon a Doppelganger of yourself to assist you.',             exhaustion = 2000,  premium = false, type = 'Instant', icon = 8,  mana = 1105, level = 100, soul = 25, group = {[2] = 2000}, vocations = {7}}
  }]]
}

-- ['const_name'] =       {client_id, TFS_id}
-- Conversion from TFS icon id to the id used by client (icons.png order)
SpellIcons = {
--[[
    ['terraburst'] = {164, __TFS_ID__},
    ['iceburst'] = {163, __TFS_ID__},
    ['greatdeathbeam'] = {162, __TFS_ID__},
    ['giftoflife'] = {161, __TFS_ID__},
    ['executionersthrow'] = {160, __TFS_ID__},
    ['divinegrenade'] = {159, __TFS_ID__},
    ['divineempowerment'] = {158, __TFS_ID__},
    ['avatarofstorm'] = {157, __TFS_ID__},
    ['avatarofsteel'] = {156, __TFS_ID__},
    ['avatarofnature'] = {155, __TFS_ID__},
    ['avataroflight'] = {154, __TFS_ID__},
]]
    ['conjurewandofdarkness'] = {133, 92},
    ['findfiend'] = {153, 20},

    ['sapstrenght'] = {110, 244},
    ['exposeweakness'] = {109, 243},
    ["naturesembrace"] = {106, 242},
    ['restoration'] = {107, 241},
    ['greatfirewave'] = {102, 240},
    ['fairwoundcleansing'] = {4, 239},
    ['divinedazzle'] = {138, 238},
    ['chivalrouschallange'] = {111, 237},

    ['summondruidfamiliar'] = {143, 197},
    ['summonsorcererfamiliar'] = {145, 196},
    ['summonpaladinfamiliar'] = {144, 195},
    ['summonknightfamiliar'] = {142, 194},

    ['conjurespectralbolt'] = {152, 193},
    ['conjurediamondarrow'] = {151, 192},

    ['scorch'] = {131, 178},
    ['buzz'] = {132, 177},
    ['arrowcall'] = {137, 176},
    ['bruisebane'] = {134, 175},
    ['magicpatch'] = {133, 174},
    ['chillout'] = {135, 173},
    ['mudattack'] = {136, 172},

    ['apprenticesstrike'] = {126, 169},
    ['practisemagicmissile'] = {129, 168},
    ['practisefirewave'] = {128, 167},
    ['practisehealing'] = {127, 166},

    ['intenserecovery'] = {15, 160},
    ['recovery'] = {14, 159},
    ['intensewoundcleansing'] = {3, 158},
    ['ultimateterrastrike'] = {36, 157},
    ['ultimateicestrike'] = {33, 156},
    ['ultimateenergystrike'] = {30, 155},
    ['ultimateflamestrike'] = {27, 154},
    ['strongterrastrike'] = {35, 153},
    ['strongicestrike'] = {32, 152},
    ['strongenergystrike'] = {29, 151},
    ['strongflamestrike'] = {26, 150},
    ['lightning'] = {50, 149},
    ['physicalstrike'] = {16, 148},
    ['curecurse'] = {10, 147},
    ['curseelectrification'] = {13, 146},
    ['cureburning'] = {12, 145},
    ['curebleeding'] = {11, 144},
    ['holyflash'] = {52, 143},
    ['envenom'] = {57, 142},
    ['inflictwound'] = {56, 141},
    ['electrify'] = {55, 140},
    ['curse'] = {53, 139},
    ['ignite'] = {54, 138},
    -- [[ 136 / 137 Unknown ]]
    ['sharpshooter'] = {120, 135},
    ['swiftfoot'] = {118, 134},
    ['bloodrage'] = {95, 133},
    ['protector'] = {121, 132},
    ['charge'] = {97, 131},
    ['holymissile'] = {75, 130},
    ['enchantparty'] = {112, 129},
    ['healparty'] = {125, 128},
    ['protectparty'] = {122, 127},
    ['trainparty'] = {119, 126},
    ['divinehealing'] = {1, 125},
    ['divinecaldera'] = {39, 124},
    ['woundcleansing'] = {2, 123},
    ['divinemissile'] = {38, 122},
    ['icewave'] = {44, 121},
    ['terrawave'] = {46, 120},
    ['rageoftheskies'] = {51, 119},
    ['eternalwinter'] = {49, 118},
    ['thunderstorm'] = {62, 117},
    ['stoneshower'] = {64, 116},
    ['avalanche'] = {91, 115},
    ['icicle'] = {74, 114},
    ['terrastrike'] = {34, 113},
    ['icestrike'] = {31, 112},
    ['etherealspear'] = {17, 111},
    ['enchantspear'] = {103, 110},
    ['piercingbolt'] = {109, 109},
    ['sniperarrow'] = {111, 108},
    ['whirlwindthrow'] = {18, 107},
    ['groundshaker'] = {24, 106},
    ['fierceberserk'] = {21, 105},
    -- [[ 96 - 104 Unknown ]]
    ['powerbolt'] = {107, 95},
    ['wildgrowth'] = {60, 94},
    ['challenge'] = {96, 93},
    ['enchantstaff'] = {102, 92},
    ['poisonbomb'] = {69, 91},
    ['cancelinvisibility'] = {94, 90},
    ['flamestrike'] = {25, 89},
    ['energystrike'] = {28, 88},
    ['deathstrike'] = {37, 87},
    ['magicwall'] = {71, 86},
    ['healfriend'] = {7, 84},
    ['animatedead'] = {92, 83},
    ['masshealing'] = {8, 82},
    ['levitate'] = {124, 81},
    ['berserk'] = {20, 80},
    ['conjurebolt'] = {106, 79},
    ['desintegrate'] = {87, 78},
    ['stalagmite'] = {65, 77},
    ['magicrope'] = {104, 76},
    ['ultimatelight'] = {114, 75},
    -- [[ 71 - 64 TFS House Commands ]]
    -- [[ 63 - 70 Unknown ]]
    ['annihilation'] = {23, 62},
    ['brutalstrike'] = {22, 61},
    -- [[ 60 Unknown ]]
    ['frontsweep'] = {19, 59},
    -- [[ 58 Unknown ]]
    ['strongetherealspear'] = {58, 57},
    ['wrathofnature'] = {47, 56},
    ['energybomb'] = {85, 55},
    ['paralyze'] = {70, 54},
    --  [[ 53 Unknown ]]
    --  [[ 52 TFS Retrieve Friend ]]
    ['conjurearrow'] = {105, 51},
    ['soulfire'] = {66, 50},
    ['explosivearrow'] = {108, 49},
    ['poisonedarrow'] = {110, 48},
    -- [[ 46 / 47 Unknown ]]
    ['invisible'] = {93, 45},
    ['magicshield'] = {123, 44},
    ['strongicewave'] = {45, 43},
    ['food'] = {98, 42},
    -- [[ 40 / 41 Unknown ]]
    ['stronghaste'] = {101, 39},
    ['creatureillusion'] = {99, 38},
    -- [[ 37 TFS Move ]]
    ['salvation'] = {59, 36},
    -- [[ 34 / 35 Unknown ]]
    ['energywall'] = {83, 33},
    ['poisonwall'] = {67, 32},
    ['antidote'] = {9, 31},
    ['destroyfield'] = {86, 30},
    ['curepoison'] = {9, 29},
    ['firewall'] = {79, 28},
    ['energyfield'] = {84, 27},
    ['poisonfield'] = {68, 26},
    ['firefield'] = {80, 25},
    ['hellscore'] = {48, 24},
    ['greatenergybeam'] = {41, 23},
    ['energybeam'] = {40, 22},
    ['suddendeath'] = {63, 21},
    ['findperson'] = {113, 20},
    ['firewave'] = {43, 19},
    ['explosion'] = {82, 18},
    ['firebomb'] = {81, 17},
    ['greatfireball'] = {77, 16},
    ['fireball'] = {78, 15},
    ['chameleon'] = {90, 14},
    ['energywave'] = {42, 13},
    ['convincecreature'] = {89, 12},
    ['greatlight'] = {115, 11},
    ['light'] = {116, 10},
    ['summoncreature'] = {117, 9},
    ['heavymagicmissile'] = {76, 8},
    ['lightmagicmissile'] = {72, 7},
    ['haste'] = {100, 6},
    ['ultimatehealingrune'] = {61, 5},
    ['intensehealingrune'] = {73, 4},
    ['ultimatehealing'] = {0, 3},
    ['intensehealing'] = {6, 2},
    ['lighthealing'] = {5, 1},
    -- Monk Spells Icons (clientId based on otclient-main)
    ['spiritmend'] = {161, 273},
    ['virtueofharmony'] = {162, 274},
    ['virtueofjustice'] = {163, 275},
    ['virtueofsustain'] = {164, 276},
    ['mentorother'] = {165, 277},
    ['enlightenparty'] = {166, 278},
    ['focusharmony'] = {167, 279},
    ['balancedbrawl'] = {168, 280},
    ['focusserenity'] = {169, 281},
    ['summonmonkfamiliar'] = {170, 282},
    ['avatarofbalance'] = {171, 283},
    ['swiftjab'] = {172, 284},
    ['doublejab'] = {173, 285},
    ['forcefuluppercut'] = {174, 286},
    ['flurryofblows'] = {175, 287},
    ['chainedpenance'] = {176, 288},
    ['greaterflurryofblows'] = {177, 289},
    ['mysticrepulse'] = {178, 290},
    ['tigerclash'] = {179, 291},
    ['greatertigerclash'] = {180, 292},
    ['devastatingknockout'] = {181, 293},
    ['sweepingtakedown'] = {182, 294},
    ['spiritualoutburst'] = {183, 295},
    ['massspiritmend'] = {184, 296},
    ['restorebalance'] = {185, 297}
}

VocationNames = {
    [0] = 'None',
    [1] = 'Sorcerer',
    [2] = 'Druid',
    [3] = 'Paladin',
    [4] = 'Knight',
    [5] = 'Master Sorcerer',
    [6] = 'Elder Druid',
    [7] = 'Royal Paladin',
    [8] = 'Elite Knight',
    [9] = 'Monk',
    [10] = 'Exhalted Monk'
}

SpellGroups = {
    [1] = 'Attack',
    [2] = 'Healing',
    [3] = 'Support',
    [4] = 'Special',
    [5] = 'Crippling',
    [6] = 'Focus',
    [7] = 'UltimateStrike',
    [8] = 'GreatBeams',
    [9] = 'BurstOfNature',
    [10] = 'Virtue'
}

Spells = {}

function Spells.getClientId(spellName)
    if not spellName then
        return nil
    end
    local profile = Spells.getSpellProfileByName(spellName)
    if not profile then
        return nil
    end
    
    local spellData = SpellInfo[profile][spellName]
    if not spellData then
        return nil
    end

    -- If spell has explicit clientId, use it
    if spellData.clientId then
        return spellData.clientId
    end

    local id = spellData.icon
    if not tonumber(id) and SpellIcons[id] then
        return SpellIcons[id][1]
    end
    return tonumber(id)
end

function Spells.getSpellByClientId(id)
    for profile, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            if spell.id == id then
                return spell, profile, k
            end
        end
    end
    return nil
end

function Spells.getServerId(spellName)
    local profile = Spells.getSpellProfileByName(spellName)

    local id = SpellInfo[profile][spellName].icon
    if not tonumber(id) and SpellIcons[id] then
        return SpellIcons[id][2]
    end
    return tonumber(id)
end

function Spells.getSpellByName(name)
    return SpellInfo[Spells.getSpellProfileByName(name)][name]
end

function Spells.getSpellByWords(words)
    local words = words:lower():trim()
    for profile, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            if spell.words == words then
                return spell, profile, k
            end
        end
    end
    return nil
end

function Spells.getSpellByIcon(iconId)
    for profile, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            if spell.id == iconId then
                return spell, profile, k
            end
        end
    end
    return nil
end

function Spells.getSpellIconIds()
    local ids = {}
    for profile, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            table.insert(ids, spell.id)
        end
    end
    return ids
end

function Spells.getSpellProfileById(id)
    for profile, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            if spell.id == id then
                return profile
            end
        end
    end
    return nil
end

function Spells.getSpellProfileByWords(words)
    for profile, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            if spell.words == words then
                return profile
            end
        end
    end
    return nil
end

function Spells.getSpellProfileByName(spellName)
    if not spellName then
        return nil
    end
    for profile, data in pairs(SpellInfo) do
        if table.findbykey(data, spellName:trim(), true) then
            return profile
        end
    end
    return nil
end

function Spells.getSpellsByVocationId(vocId)
    local spells = {}
    for profile, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            if table.contains(spell.vocations, vocId) then
                table.insert(spells, spell)
            end
        end
    end
    return spells
end

function Spells.filterSpellsByGroups(spells, groups)
    local filtered = {}
    for v, spell in pairs(spells) do
        local spellGroups = Spells.getGroupIds(spell)
        if table.equals(spellGroups, groups) then
            table.insert(filtered, spell)
        end
    end
    return filtered
end

function Spells.getGroupIds(spell)
    local groups = {}
    for k, _ in pairs(spell.group) do
        table.insert(groups, k)
    end
    return groups
end

function Spells.getImageClip(id, profile)
    if not id or not profile or not SpelllistSettings[profile] then
        return nil
    end
    -- For horizontal sprite sheets (like spell-icons-32x32.png which is 5984x32)
    -- Simply multiply the index by icon width, Y is always 0
    return (id * SpelllistSettings[profile].iconSize.width) .. ' 0 ' ..
               SpelllistSettings[profile].iconSize.width .. ' ' .. SpelllistSettings[profile].iconSize.height
end

function Spells.getIconFileByProfile(profile)
    if not profile or not SpelllistSettings[profile] then
        return nil
    end
    return SpelllistSettings[profile]['iconFile']
end

-- ========================
-- Multi Action Bar Functions
-- ========================

SpellRunesData = {
    [3148] = {id = 3, group = 1, name = 'convince creature rune', exhaustion = 2000},
    [3149] = {id = 10, group = 1, name = 'soulfire rune', exhaustion = 2000},
    [3150] = {id = 2, group = 1, name = 'poison bomb rune', exhaustion = 2000},
    [3151] = {id = 6, group = 1, name = 'great fireball rune', exhaustion = 2000},
    [3152] = {id = 15, group = 1, name = 'energy bomb rune', exhaustion = 2000},
    [3153] = {id = 23, group = 1, name = 'destroy field rune', exhaustion = 2000},
    [3154] = {id = 16, group = 1, name = 'fire field rune', exhaustion = 2000},
    [3155] = {id = 13, group = 1, name = 'poison field rune', exhaustion = 2000},
    [3156] = {id = 14, group = 1, name = 'energy field rune', exhaustion = 2000},
    [3160] = {id = 24, group = 1, name = 'disintegrate rune', exhaustion = 2000},
    [3161] = {id = 4, group = 1, name = 'chameleon rune', exhaustion = 2000},
    [3164] = {id = 5, group = 1, name = 'desintegrate rune', exhaustion = 2000},
    [3165] = {id = 9, group = 1, name = 'intense healing rune', exhaustion = 1000},
    [3166] = {id = 8, group = 1, name = 'ultimate healing rune', exhaustion = 1000},
    [3174] = {id = 18, group = 1, name = 'sudden death rune', exhaustion = 2000},
    [3175] = {id = 22, group = 1, name = 'magic wall rune', exhaustion = 2000},
    [3176] = {id = 11, group = 1, name = 'explosion rune', exhaustion = 2000},
    [3177] = {id = 21, group = 1, name = 'fire wall rune', exhaustion = 2000},
    [3178] = {id = 19, group = 1, name = 'paralyse rune', exhaustion = 2000},
    [3179] = {id = 17, group = 1, name = 'energy wall rune', exhaustion = 2000},
    [3180] = {id = 20, group = 1, name = 'poison wall rune', exhaustion = 2000},
    [3188] = {id = 1, group = 1, name = 'heavy magic missile rune', exhaustion = 2000},
    [3189] = {id = 12, group = 1, name = 'light magic missile rune', exhaustion = 2000},
    [3190] = {id = 25, group = 1, name = 'fireball rune', exhaustion = 2000},
    [3191] = {id = 26, group = 1, name = 'stalagmite rune', exhaustion = 2000},
    [3192] = {id = 27, group = 1, name = 'icicle rune', exhaustion = 2000},
    [3193] = {id = 28, group = 1, name = 'avalanche rune', exhaustion = 2000},
    [3194] = {id = 29, group = 1, name = 'stone shower rune', exhaustion = 2000},
    [3195] = {id = 30, group = 1, name = 'thunderstorm rune', exhaustion = 2000},
    [3196] = {id = 31, group = 1, name = 'wild growth rune', exhaustion = 2000},
    [3197] = {id = 32, group = 1, name = 'cure poison rune', exhaustion = 1000},
    [3198] = {id = 33, group = 1, name = 'animate dead rune', exhaustion = 2000},
    [7588] = {id = 117, group = 1, name = 'ultimate energy rune', exhaustion = 2000},
    [7589] = {id = 120, group = 1, name = 'ultimate ice rune', exhaustion = 2000},
    [7590] = {id = 119, group = 1, name = 'ultimate earth rune', exhaustion = 2000},
    [7591] = {id = 118, group = 1, name = 'ultimate terror rune', exhaustion = 2000},
    [17512] = {id = 7, group = 1, name = 'lightest magic missile rune', exhaustion = 2000},
    [21351] = {id = 116, group = 1, name = 'light stone shower rune', exhaustion = 2000},
    [21352] = {id = 7, group = 1, name = 'lightest missile rune', exhaustion = 2000}
}

function Spells.getSpellList()
    local spells = {}
    for k, spell in pairs(SpellInfo["Default"]) do
        table.insert(spells, spell)
    end
    return spells
end

function Spells.getSpellDataByParamWords(words)
    for profile, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            local inputWords = words:lower()
            local spellWords = spell.words:lower()
            local quoteStartIndex = inputWords:find('%%"')
            if not spell.parameter then
                if inputWords == spellWords then
                    return spell, nil
                end
            else
                if quoteStartIndex then
                    local spellPart = inputWords:sub(1, quoteStartIndex - 1):match("^%%s*(.-)%%s*$")
                    local parameter = inputWords:sub(quoteStartIndex + 1)
                    if spellPart == spellWords then
                        return spell, parameter
                    end
                else
                    if inputWords == spellWords then
                        return spell, nil
                    end
                end
            end
        end
    end
    return nil, nil
end

function Spells.getSpellFormatedName(words)
    for profile, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            local inputWords = words:lower()
            local spellWords = spell.words:lower()
            if not spell.parameter then
                if inputWords == spellWords then
                    return spellWords
                end
            else
                if string.sub(inputWords, 1, string.len(spellWords)) == spellWords then
                    local extraText = string.sub(inputWords, string.len(spellWords) + 1)
                    if extraText ~= "" then
                        if string.sub(extraText, 1, 1) == " " then
                            local firstChar = string.sub(extraText, 2, 2)
                            if firstChar == '"' then
                                local fomated = extraText:gsub('"', '')
                                fomated = '"' .. string.sub(fomated, 2) .. '"'
                                return spellWords .. " " .. fomated
                            else
                                return spellWords .. extraText
                            end
                        end
                    else
                        return spellWords
                    end
                end
            end
        end
    end
    return words
end

function Spells.getSpellNameByWords(words)
    for profile, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            if spell.words == words then
                return k
            end
        end
    end
    return nil
end

function Spells.getSpellDataById(spellId)
    for _, data in pairs(SpellInfo) do
        for k, spell in pairs(data) do
            if spell.id == spellId then
                return spell
            end
        end
    end
    return nil
end

function Spells.getRuneSpellByItem(itemId)
    local data = SpellRunesData[itemId]
    if data then
        return data
    end
    return nil
end

function Spells.isRuneSpell(spellId)
    for _, data in pairs(SpellRunesData) do
        if data.id == spellId then
            return true
        end
    end
    return false
end

function Spells.getCooldownByGroup(spellData, groupId)
    local keys = {}
    for k in pairs(spellData.group) do
        table.insert(keys, k)
    end
    table.sort(keys)
    local index = 1
    for _, k in ipairs(keys) do
        if index == 1 and k == groupId then
            return spellData.group[k]
        end
        index = index + 1
    end
    return nil
end

function Spells.getCooldownBySecondaryGroup(spellData, groupId)
    local keys = {}
    for k in pairs(spellData.group) do
        table.insert(keys, k)
    end
    table.sort(keys)
    local index = 1
    for _, k in ipairs(keys) do
        if index == 2 and k == groupId then
            return spellData.group[k]
        end
        index = index + 1
    end
    return nil
end

function Spells.getPrimaryGroup(spell)
    local indexes = {}
    for k in pairs(spell.group) do
        table.insert(indexes, k)
    end
    table.sort(indexes)
    return indexes[1] or -1
end
