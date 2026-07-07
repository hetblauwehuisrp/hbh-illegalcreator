return {

	['kniptang'] = {
		label = 'Kniptangetje',
		weight = 343,
		stack = true,
		close = true,
		description = 'Om dingen mee te knippen?',
	},

	['outfitbag'] = {
        label = 'outfitbag',
        weight = 0.05,
        stack = false,
        close = false,
    },

	['ring'] = {
		label = 'Ring',
		description = "Een mooie diamanten ring!",
		weight = 50,
		stack = true
	},
	
	['bracelet'] = {
		label = 'Armband',
		description = "Een prachtige armband!",
		weight = 100,
		stack = true
	},
	
	['watch'] = {
		label = 'Duur Horloge',
		description = "Een duur horloge!",
		weight = 200,
		stack = true
	},
	['hbw_vacature'] = {
    		label = 'HBW Vacature',
    		weight = 0,
    		stack = true,
    		close = true,
    		description = 'Actieve HBW vacature.'
	},
	['id'] = {
    		label = 'ID Kaart',
    		weight = 10,
    		stack = false,
    		close = true,
    		description = 'Officiële ID-kaart van HetBlauweHuisRP'
	},
	['monitor'] = {
		label = 'Monitor',
		description = "An used monitor",
		weight = 750,
		stack = true
	},
	
	['keyboard'] = {
		label = 'Keyboard',
		description = "An used keyboard",
		weight = 300,
		stack = true
	},
	
	['laptop'] = {
		label = 'Laptop',
		description = "An used laptop",
		weight = 1000,
		stack = true
	},
	
	['green_keycard'] = {
		label = 'Groene Keycard',
		weight = 125,
	},
	['blue_keycard'] = {
		label = 'Blauwe Keycard',
		weight = 125,
	},
	['red_keycard'] = {
		label = 'Rode Keycard',
		weight = 125,
	},
	
	['blueprint'] = {
		label = 'Blueprint',
		weight = 125,
		client = {
			export = "mtb-human-labs-heist-main.triggerBlueprintUI"
		}
	},

	-- ============= --
	-- === MONEY === --
	-- ============= --

	['black_money'] = {
		label = 'Zwart geld',
		weight = 0,
	},

	['money'] = {
		label = 'Contant geld',
		weight = 0,
	},

	-- ============= --
	-- === FOOD === --
	-- ============= --

	['pizza'] = {
		label = 'Pizza',
		description = 'In ieder geval is dit geen Hawai.',
		weight = 300,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'sandwich',
			usetime = 2000,
		},
	},

	['fries'] = {
		label = 'Friet',
		description = 'Het is patat, geen friet..',
		weight = 150,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = { bone = 18905, model = 'prop_food_bs_chips', pos = vec3(0.15, 0.005, 0.020), rot = vec3(290.0, 155.0, -10.0) },
			usetime = 2000,
		},
	},

	['burger'] = {
		label = 'Hamburger',
		description = 'Lekkere Hamburger.',
		weight = 175,
		client = {
			status = { hunger = 200000 },
			anim = 'eating2',
			prop = 'burger',
			usetime = 2000,
		},
	},

    ['cheeseburger'] = {
		label = 'Cheeseburger',
		description = 'Lekkere Cheeseburger.',
		weight = 175,
		client = {
			status = { hunger = 200000 },
			anim = 'eating2',
			prop = 'burger',
			usetime = 2000,
		},
	},

    ['hotdog'] = {
		label = 'Hotdog',
		description = 'Lekkere hotdog.',
		weight = 175,
		client = {
			status = { hunger = 200000 },
			anim = 'eating2',
			prop = 'burger',
			usetime = 2000,
		},
	},

['medische_tas'] = {
    label = 'Medische Tas',
    weight = 2500,
    stack = false,
    close = true,
    description = 'Benodigd om iemand te reanimeren.'
},


['bread'] = {
    label = 'Brood',
    weight = 10,
    stack = true,
    consume = 1,
    close = true,
    client = {
        status = { hunger = 200000 },
        usetime = 2500,
        anim = {
            dict = 'mp_player_inteat@burger',
            clip = 'mp_player_int_eat_burger'
        },
        prop = {
            model = `prop_cs_burger_01`,
            pos = vec3(0.02, 0.02, -0.02),
            rot = vec3(0.0, 0.0, 0.0)
        }
    }
},

['water'] = {
    label = 'Water',
    weight = 10,
    stack = true,
    consume = 1,
    close = true,
    client = {
        status = { thirst = 200000 },
        usetime = 2500,
        anim = {
            dict = 'mp_player_intdrink',
            clip = 'loop_bottle'
        },
        prop = {
            model = `prop_ld_flow_bottle`,
            pos = vec3(0.03, 0.03, 0.02),
            rot = vec3(0.0, 0.0, -1.5)
        }
    }
},

    ['sausageroll'] = {
		label = 'Worstenbroodje',
		description = 'Iets lekkers om te eten.',
		weight = 70,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'sandwich',
			usetime = 2000,
		}
	},
    
   	['bewijszakje'] = {
		label = 'Bewijszakje',
		weight = 220,
		stack = false,
		consume = 0,
		client = {
			export = 'rtx-bewijszakje.openBackpack'
		}
	},
    
	['chips'] = {
		label = 'Chips',
		description = 'Lekker knapperig.',
		weight = 175,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'sandwich',
			usetime = 2000,
		},
	},

    ['appleflap'] = {
		label = 'Appelflap',
		description = 'Lekker warm nog!',
		weight = 175,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'sandwich',
			usetime = 2000,
		},
	},

    ['fruitdoughnut'] = {
		label = 'Fruit Donut',
		description = 'Lekker gezond!',
		weight = 175,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'sandwich',
			usetime = 2000,
		},
	},

    ['chocolatebar'] = {
		label = 'Chocolatebar',
		description = 'Lekkere chocola.',
		weight = 175,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'sandwich',
			usetime = 2000,
		},
	},

    ['taco'] = {
		label = 'Taco',
		description = 'Lekker taco.',
		weight = 175,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'sandwich',
			usetime = 2000,
		},
	},

    ['burrito'] = {
		label = 'Burrito',
		description = 'Lekker burrito.',
		weight = 175,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'sandwich',
			usetime = 2000,
		},
	},

	['donut'] = {
		label = 'Donut',
		description = 'Voor de Politie mensen..',
		weight = 55,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'donut',
			usetime = 2000,
		},
	},


	-- ============= --
	-- === DRINKS === --
	-- ============= --

	['kola'] = {
		label = 'Kola',
		description = 'De echte kleur is groen!',
		weight = 330,
		client = {
			status = { thirst = 200000 },
			anim = 'drinking',
			prop = 'cola',
			usetime = 2000,
		},
	},
	
	['sinas'] = {
		label = 'Sinas',
		description = 'Dit is echt Sintastisch.',
		weight = 330,
		client = {
			status = { thirst = 200000 },
			anim = 'drinking',
			prop = 'cola',
			usetime = 2000,
		},
	},

    ['sprite'] = {
		label = 'Sprite',
		description = 'No comment.',
		weight = 330,
		client = {
			status = { thirst = 200000 },
			anim = 'drinking',
			prop = 'cola',
			usetime = 2000,
		},
	},

	['sprunk'] = {
		label = 'Sprunk',
		description = 'Dit is geen sprite.',
		weight = 330,
		client = {
			status = { thirst = 200000 },
			anim = 'drinking',
			prop = 'cola',
			usetime = 2000,
		},
	},

    ['icetea'] = {
		label = 'Ice Tea',
		description = 'Lekker voor in de zomer!',
		weight = 150,
		client = {
			status = { thirst = 200000 },
			anim = 'drinking2',
			prop = 'water',
			usetime = 2000,
		},
	},

    ['coffee'] = {
		label = 'Koffie',
		description = 'Lekker bakke plur!',
		weight = 150,
		client = {
			status = { thirst = 200000 },
			anim = 'drinking2',
			prop = 'water',
			usetime = 2000,
		},
	},
    
    ['beer'] = {
		label = 'Bier',
		description = 'Dronken?',
		weight = 150,
		client = {
			status = { drunk = 200000 },
			anim = 'drinking2',
			prop = 'water',
			usetime = 2000,
		},
	},

	['chocomel'] = {
		label = 'Chocomelk',
		description = 'Van de appie!',
		weight = 150,
		client = {
			status = { thirst = 200000 },
			anim = 'drinking2',
			prop = 'water',
			usetime = 2000,
		},
	},

	['energy'] = {
		label = 'Energy',
		description = 'Voor de skere rakkers!',
		weight = 150,
		client = {
			status = { thirst = 200000 },
			anim = 'drinking2',
			prop = 'water',
			usetime = 2000,
		},
	},

	['drinkyoghurt'] = {
		label = 'Drinkyoghurt Framboos',
		description = 'Voor de knapen die melk niet lusten!',
		weight = 150,
		client = {
			status = { thirst = 200000 },
			anim = 'drinking2',
			prop = 'water',
			usetime = 2000,
		},
	},


	-- ============= --
	-- === GADGETS === --
	-- ============= --

	['dsischild'] = {
		label = 'SO Schild',
		description = 'Een Schild alleen voor de Dienst Speciale Interventies..',
		weight = 950,
		allowArmed = true,
	},

	['handcuffs'] = {
		label = 'Handboeien',
		description = 'Lijkt wel iets waarmee je iemand vast kan binden..',
		weight = 80,
	},

	['tiewraps'] = {
		label = 'Tiewraps',
		description = 'Lijkt wel iets waarmee je iemand vast kan binden..',
		weight = 90,
	},

	['lockpick'] = {
		label = 'Lockpick',
		description = 'Misschien kan je hiermee iets openen?',
		weight = 60,
	},

	["phone"] = {
		label = "Telefoon",
		weight = 300,
		consume = 0,
	},

	["WEAPON_STICKYBOMB"] = {
		label = "Sticky bom",
		weight = 300,
		consume = 0,
	},

	["heistpack_grinder"] = {
		label = "Sticky bom",
		weight = 300,
		consume = 0,
	},


	['radio'] = {
		label = 'Portofoon',
		description = 'Iets om mee te communiceren in bepaalde kanalen ofzo.',
		weight = 150,
	},



	['repairkit'] = {
		label = 'Reparatieset',
		description = 'Als je dit gebruikt, weet je dat je niet kan rijden..',
		weight = 2500,
	},

	["vishengel"] = {
		label = "Vishengel",
		weight = 300,
		stack = false,
		close = false,
		description = 'Een vishengel om mee te vissen.'
	},


	["vis"] = {
		label = "Vis",
		weight = 300,
		stack = true,
		close = true,
		description = 'Een normale vis.'
	},

	["grote_vis"] = {
		label = "Grote Vis",
		weight = 500,
		stack = true,
		close = true,
		description = 'Een grote waardevolle vis.'
	},

    ['lsd'] = {
		label = 'LSD',
		weight = 513,
		stack = true,
		close = true,
	},

	['meth'] = {
		label = 'Meth',
		weight = 616,
		stack = true,
		close = true,
	},

	['coca_leaf'] = {
		label = 'Coca bladeren',
		weight = 344,
		stack = true,
		close = true,
	},

	['cocainepoeder'] = {
		label = 'Cocaine Zakje',
		weight = 322,
		stack = true,
		close = true,
	},

	['cannabis'] = {
		label = 'Onverpakte Wiet',
		weight = 395,
		stack = true,
		close = true,
	},

	['weed_packed'] = {
		label = 'Verpakte Wiet',
		weight = 297,
		stack = true,
		close = true,
	},
	
	-- ============= --
	-- === OVERVALLEN === --
	-- ============= --

	['jewels'] = {
		label = 'Juwelen',
		weight = 125,
		stack = true,
		close = true,
	},

	['jachtkey'] = {
		label = 'Jacht Key',
		weight = 125,
		stack = true,
		close = true,
	},

	['laptop'] = {
		label = 'Laptop',
		weight = 1000,
		stack = true,
		close = true,
	},

	['drill'] = {
		label = 'Boor',
		weight = 2000,
		stack = true,
		close = true,
	},

	['thermiet'] = {
		label = 'Thermiet',
		weight = 250,
		stack = true,
		close = true,
	},

	['gasmask'] = {
		label = 'Gasmasker',
		weight = 250,
		stack = true,
		close = true,
	},
    
	['heavy_rope'] = {
		label = 'Touw',
		weight = 250,
		stack = true,
		close = true,
	},

	['onderdeel1'] = {
		label = 'Wapen Frame',
		weight = 250,
		stack = true,
		close = true,
	},

	['onderdeel2'] = {
		label = 'Wapen Clip',
		weight = 250,
		stack = true,
		close = true,
	},

	['onderdeel3'] = {
		label = 'Wapen Trigger',
		weight = 250,
		stack = true,
		close = true,
	},

	['onderdeel4'] = {
		label = 'Wapen Loop',
		weight = 250,
		stack = true,
		close = true,
	},

	['heistpack_anchor'] = {
		label = 'Anker',
		weight = 250,
		stack = true,
		close = true,
	},

	['heistpack_drill'] = {
		label = 'Gevaarlijke Boor',
		weight = 250,
		stack = true,
		close = true,
	},

	['heistpack_drill'] = {
		label = 'Gevaarlijke Boor',
		weight = 250,
		stack = true,
		close = true,
	},

	['illegal_tablet'] = {
		label = 'Heist Tablet',
		weight = 250,
		stack = true,
		close = true,
	},

	['illegal_tablet'] = {
		label = 'Heist Tablet',
		weight = 250,
		stack = true,
		close = true,
	},

	['weapon_hackingdevice'] = {
		label = 'Hack Apparaat',
		weight = 250,
		stack = true,
		close = true,
	},

	["hacking_device"] = {
		label = "Hack Apparaat",
		weight = 233,
		stack = true,
		close = true,
	},

	["sample"] = {
		label = "Serum",
		weight = 500,
		stack = true,
		close = true,
	},

	["accesscard"] = {
		label = "Access Card",
		weight = 10,
		stack = true,
		close = true,
	},

	["alive_chicken"] = {
		label = "Living chicken",
		weight = 1,
		stack = true,
		close = true,
	},

	["bandage"] = {
		label = "Bandage",
		weight = 2,
		stack = true,
		close = true,
	},

	["black_phone"] = {
		label = "Black Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["blowpipe"] = {
		label = "Blowtorch",
		weight = 2,
		stack = true,
		close = true,
	},

	["blue_phone"] = {
		label = "Blue Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["burncream"] = {
		label = "Burn Cream",
		weight = 1,
		stack = true,
		close = true,
	},

	["carokit"] = {
		label = "Body Kit",
		weight = 3,
		stack = true,
		close = true,
	},

	["carotool"] = {
		label = "Tools",
		weight = 2,
		stack = true,
		close = true,
	},

	["classic_phone"] = {
		label = "Classic Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["clothe"] = {
		label = "Cloth",
		weight = 1,
		stack = true,
		close = true,
	},

	["copper"] = {
		label = "Copper",
		weight = 1,
		stack = true,
		close = true,
	},

	["cutted_wood"] = {
		label = "Cut wood",
		weight = 1,
		stack = true,
		close = true,
	},

	["defib"] = {
		label = "Defibrillator",
		weight = 1,
		stack = true,
		close = true,
	},

	["diamond"] = {
		label = "Diamond",
		weight = 1,
		stack = true,
		close = true,
	},

	["diamonds_box"] = {
		label = "Diamonds box",
		weight = 1,
		stack = true,
		close = true,
	},

	["essence"] = {
		label = "Gas",
		weight = 1,
		stack = true,
		close = true,
	},

	["fabric"] = {
		label = "Fabric",
		weight = 1,
		stack = true,
		close = true,
	},

	["fish"] = {
		label = "Fish",
		weight = 1,
		stack = true,
		close = true,
	},

	["fixkit"] = {
		label = "Repair Kit",
		weight = 3,
		stack = true,
		close = true,
	},

	["fixtool"] = {
		label = "Repair Tools",
		weight = 2,
		stack = true,
		close = true,
	},

	["gas_mask"] = {
		label = "Gas mask",
		weight = 1,
		stack = true,
		close = true,
	},

	["gazbottle"] = {
		label = "Gas Bottle",
		weight = 2,
		stack = true,
		close = true,
	},

	["gold"] = {
		label = "Gold",
		weight = 1,
		stack = true,
		close = true,
	},

	["goldbar"] = {
		label = "Gold Bar",
		weight = 1,
		stack = true,
		close = true,
	},

	["goldnecklace"] = {
		label = "Gold Necklace",
		weight = 1,
		stack = true,
		close = true,
	},

	["goldwatch"] = {
		label = "Gold Watch",
		weight = 1,
		stack = true,
		close = true,
	},

	["gold_ingot"] = {
		label = "Gold Stukje",
		weight = 200,
		stack = true,
		close = true,
	},

	["diamond"] = {
		label = "Diamant",
		weight = 200,
		stack = true,
		close = true,
	},

	["gold_phone"] = {
		label = "Gold Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["gps"] = {
		label = "GPS",
		weight = 1,
		stack = true,
		close = true,
	},

	["greenlight_phone"] = {
		label = "Green Light Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["green_phone"] = {
		label = "Green Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["hackerDevice"] = {
		label = "Hacker Device",
		weight = 10,
		stack = true,
		close = true,
	},

	["hacking_computer"] = {
		label = "Hacking computer",
		weight = 1,
		stack = true,
		close = true,
	},

	["hammerwirecutter"] = {
		label = "Hammer And Wire Cutter",
		weight = 10,
		stack = true,
		close = true,
	},

	["icepack"] = {
		label = "Ice Pack",
		weight = 1,
		stack = true,
		close = true,
	},

	["iron"] = {
		label = "Iron",
		weight = 1,
		stack = true,
		close = true,
	},

	["kq_airdrop_flare"] = {
		label = "Airdrop flare",
		weight = 2,
		stack = true,
		close = true,
	},

	["kq_outfitbag"] = {
		label = "Outfit bag",
		weight = 4,
		stack = true,
		close = true,
	},

	["marijuana"] = {
		label = "Marijuana",
		weight = 2,
		stack = true,
		close = true,
	},

	["medbag"] = {
		label = "Medical Bag",
		weight = 1,
		stack = true,
		close = true,
	},

	["medikit"] = {
		label = "Medkit",
		weight = 1,
		stack = true,
		close = true,
	},

	["packaged_chicken"] = {
		label = "Chicken fillet",
		weight = 1,
		stack = true,
		close = true,
	},

	["packaged_plank"] = {
		label = "Packaged wood",
		weight = 1,
		stack = true,
		close = true,
	},

	["painting"] = {
		label = "Painting",
		weight = 1,
		stack = true,
		close = true,
	},

	["petrol"] = {
		label = "Oil",
		weight = 1,
		stack = true,
		close = true,
	},

	["petrol_raffin"] = {
		label = "Processed oil",
		weight = 1,
		stack = true,
		close = true,
	},

	["phone_hack"] = {
		label = "Phone Hack",
		weight = 10,
		stack = true,
		close = true,
	},

	["phone_module"] = {
		label = "Phone Module",
		weight = 10,
		stack = true,
		close = true,
	},

	["pink_phone"] = {
		label = "Pink Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["powerbank"] = {
		label = "Power Bank",
		weight = 10,
		stack = true,
		close = true,
	},

	["red_phone"] = {
		label = "Red Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["rope"] = {
		label = "Rope",
		weight = 1,
		stack = true,
		close = true,
	},

	["sedative"] = {
		label = "Sedative",
		weight = 1,
		stack = true,
		close = true,
	},

	["slaughtered_chicken"] = {
		label = "Slaughtered chicken",
		weight = 1,
		stack = true,
		close = true,
	},

	["stone"] = {
		label = "Stone",
		weight = 1,
		stack = true,
		close = true,
	},

	["suturekit"] = {
		label = "Suture Kit",
		weight = 1,
		stack = true,
		close = true,
	},

	["thermal_charge"] = {
		label = "Thermal charge",
		weight = 1,
		stack = true,
		close = true,
	},

	["tweezers"] = {
		label = "Tweezers",
		weight = 1,
		stack = true,
		close = true,
	},

	["washed_stone"] = {
		label = "Washed stone",
		weight = 1,
		stack = true,
		close = true,
	},

	["wet_black_phone"] = {
		label = "Wet Black Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["wet_blue_phone"] = {
		label = "Wet Blue Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["wet_classic_phone"] = {
		label = "Wet Classic Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["wet_gold_phone"] = {
		label = "Wet Gold Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["wet_greenlight_phone"] = {
		label = "Wet Green Light Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["wet_green_phone"] = {
		label = "Wet Green Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["wet_pink_phone"] = {
		label = "Wet Pink Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["wet_red_phone"] = {
		label = "Wet Red Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["wet_white_phone"] = {
		label = "Wet White Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["white_phone"] = {
		label = "White Phone",
		weight = 10,
		stack = true,
		close = true,
	},

	["wood"] = {
		label = "Wood",
		weight = 1,
		stack = true,
		close = true,
	},

	["wool"] = {
		label = "Wool",
		weight = 1,
		stack = true,
		close = true,
	},

	["gold_piece"] = {
		label = "Stukje goud",
		weight = 1,
		stack = true,
		close = true,
	},

	["pickaxe"] = {
		label = "Pickaxe",
		weight = 1,
		stack = true,
		close = true,
	},
	  ["engine_oil"] = {
    label = "Engine Oil",
    weight = 1000,
  },
  ["tyre_replacement"] = {
    label = "Tyre Replacement",
    weight = 1000,
  },
  ["clutch_replacement"] = {
    label = "Clutch Replacement",
    weight = 1000,
  },
  ["air_filter"] = {
    label = "Air Filter",
    weight = 100,
  },
  ["spark_plug"] = {
    label = "Spark Plug",
    weight = 1000,
  },
  ["brakepad_replacement"] = {
    label = "Brakepad Replacement",
    weight = 1000,
  },
  ["suspension_parts"] = {
    label = "Suspension Parts",
    weight = 1000,
  },
  -- Engine Items
  ["i4_engine"] = {
    label = "I4 Engine",
    weight = 1000,
  },
  ["v6_engine"] = {
    label = "V6 Engine",
    weight = 1000,
  },
  ["v8_engine"] = {
    label = "V8 Engine",
    weight = 1000,
  },
  ["v12_engine"] = {
    label = "V12 Engine",
    weight = 1000,
  },
  ["turbocharger"] = {
    label = "Turbocharger",
    weight = 1000,
  },
  -- Electric Engines
  ["ev_motor"] = {
    label = "EV Motor",
    weight = 1000,
  },
  ["ev_battery"] = {
    label = "EV Battery",
    weight = 1000,
  },
  ["ev_coolant"] = {
    label = "EV Coolant",
    weight = 1000,
  },
  -- Drivetrain Items
  ["awd_drivetrain"] = {
    label = "AWD Drivetrain",
    weight = 1000,
  },
  ["rwd_drivetrain"] = {
    label = "RWD Drivetrain",
    weight = 1000,
  },
  ["fwd_drivetrain"] = {
    label = "FWD Drivetrain",
    weight = 1000,
  },
  -- Tuning Items
  ["slick_tyres"] = {
    label = "Slick Tyres",
    weight = 1000,
  },
  ["semi_slick_tyres"] = {
    label = "Semi Slick Tyres",
    weight = 1000,
  },
  ["offroad_tyres"] = {
    label = "Offroad Tyres",
    weight = 1000,
  },
  ["drift_tuning_kit"] = {
    label = "Drift Tuning Kit",
    weight = 1000,
  },
  ["ceramic_brakes"] = {
    label = "Ceramic Brakes",
    weight = 1000,
  },
  -- Cosmetic Items
  ["lighting_controller"] = {
    label = "Lighting Controller",
    weight = 100,
    client = {
      event = "jg-mechanic:client:show-lighting-controller",
    }
  },
  ["stancing_kit"] = {
    label = "Stancer Kit",
    weight = 100,
    client = {
      event = "jg-mechanic:client:show-stancer-kit",
    }
  },
  ["cosmetic_part"] = {
    label = "Cosmetic Parts",
    weight = 100,
  },
  ["respray_kit"] = {
    label = "Respray Kit",
    weight = 1000,
  },
  ["vehicle_wheels"] = {
    label = "Vehicle Wheels Set",
    weight = 1000,
  },
  ["tyre_smoke_kit"] = {
    label = "Tyre Smoke Kit",
    weight = 1000,
  },
  ["bulletproof_tyres"] = {
    label = "Bulletproof Tyres",
    weight = 1000,
  },
  ["extras_kit"] = {
    label = "Extras Kit",
    weight = 1000,
  },
  -- Nitrous & Cleaning Items
  ["nitrous_bottle"] = {
    label = "Nitrous Bottle",
    weight = 1000,
    client = {
      event = "jg-mechanic:client:use-nitrous-bottle",
    }
  },
  ["empty_nitrous_bottle"] = {
    label = "Empty Nitrous Bottle",
    weight = 1000,
  },
  ["nitrous_install_kit"] = {
    label = "Nitrous Install Kit",
    weight = 1000,
  },
  ["cleaning_kit"] = {
    label = "Cleaning Kit",
    weight = 1000,
    client = {
      event = "jg-mechanic:client:clean-vehicle",
    }
  },
  ["repair_kit"] = {
    label = "Repair Kit",
    weight = 1000,
    client = {
      event = "jg-mechanic:client:repair-vehicle",
    }
  },
  ["duct_tape"] = {
    label = "Duct Tape",
    weight = 1000,
    client = {
      event = "jg-mechanic:client:use-duct-tape",
    }
  },
  -- Performance Item
  ["performance_part"] = {
    label = "Performance Parts",
    weight = 1000,
  },
  -- Mechanic Tablet Item
  ["mechanic_tablet"] = {
    label = "Mechanic Tablet",
    weight = 1000,
    client = {
      event = "jg-mechanic:client:use-tablet",
    }
  },
  -- Gearbox
  ["manual_gearbox"] = {
    label = "Manual Gearbox",
    weight = 1000,
  },

	-- =============================== --
	-- === HBH ILLEGALCREATOR DRUGS === --
	-- =============================== --

	['coke_leaf'] = {
		label = 'Coca bladeren',
		weight = 250,
		stack = true,
		close = true,
		description = 'Coca bladeren voor hbh-illegalcreator.',
	},

	['coke_powder'] = {
		label = 'Coke poeder',
		weight = 200,
		stack = true,
		close = true,
		description = 'Coke poeder voor hbh-illegalcreator.',
	},

	['coke_bag'] = {
		label = 'Coke zakje',
		weight = 120,
		stack = true,
		close = true,
		description = 'Coke zakje voor hbh-illegalcreator.',
	},

	['weed_leaf'] = {
		label = 'Wiet bladeren',
		weight = 250,
		stack = true,
		close = true,
		description = 'Wiet bladeren voor hbh-illegalcreator.',
	},

	['weed_dried'] = {
		label = 'Gedroogde wiet',
		weight = 200,
		stack = true,
		close = true,
		description = 'Gedroogde wiet voor hbh-illegalcreator.',
	},

	['weed_bag'] = {
		label = 'Wiet zakje',
		weight = 120,
		stack = true,
		close = true,
		description = 'Wiet zakje voor hbh-illegalcreator.',
	},

	['meth_ingredient'] = {
		label = 'Meth grondstof',
		weight = 250,
		stack = true,
		close = true,
		description = 'Meth grondstof voor hbh-illegalcreator.',
	},

	['meth_crystal'] = {
		label = 'Meth kristal',
		weight = 200,
		stack = true,
		close = true,
		description = 'Meth kristal voor hbh-illegalcreator.',
	},

	['meth_bag'] = {
		label = 'Meth zakje',
		weight = 120,
		stack = true,
		close = true,
		description = 'Meth zakje voor hbh-illegalcreator.',
	},

	['xtc_powder'] = {
		label = 'MDMA poeder',
		weight = 250,
		stack = true,
		close = true,
		description = 'MDMA poeder voor hbh-illegalcreator.',
	},

	['xtc_pill'] = {
		label = 'XTC pillen',
		weight = 200,
		stack = true,
		close = true,
		description = 'XTC pillen voor hbh-illegalcreator.',
	},

	['xtc_bag'] = {
		label = 'XTC zakje',
		weight = 120,
		stack = true,
		close = true,
		description = 'XTC zakje voor hbh-illegalcreator.',
	},

	['lsd_liquid'] = {
		label = 'LSD vloeistof',
		weight = 250,
		stack = true,
		close = true,
		description = 'LSD vloeistof voor hbh-illegalcreator.',
	},

	['lsd_sheet'] = {
		label = 'LSD zegels',
		weight = 200,
		stack = true,
		close = true,
		description = 'LSD zegels voor hbh-illegalcreator.',
	},

	['lsd_bag'] = {
		label = 'LSD zakje',
		weight = 120,
		stack = true,
		close = true,
		description = 'LSD zakje voor hbh-illegalcreator.',
	},

	['heroin_poppy'] = {
		label = 'Papaver',
		weight = 250,
		stack = true,
		close = true,
		description = 'Papaver voor hbh-illegalcreator.',
	},

	['heroin_powder'] = {
		label = 'Heroïne poeder',
		weight = 200,
		stack = true,
		close = true,
		description = 'Heroïne poeder voor hbh-illegalcreator.',
	},

	['heroin_bag'] = {
		label = 'Heroïne zakje',
		weight = 120,
		stack = true,
		close = true,
		description = 'Heroïne zakje voor hbh-illegalcreator.',
	},

	['ketamine_liquid'] = {
		label = 'Ketamine vloeistof',
		weight = 250,
		stack = true,
		close = true,
		description = 'Ketamine vloeistof voor hbh-illegalcreator.',
	},

	['ketamine_crystal'] = {
		label = 'Ketamine kristal',
		weight = 200,
		stack = true,
		close = true,
		description = 'Ketamine kristal voor hbh-illegalcreator.',
	},

	['ketamine_bag'] = {
		label = 'Ketamine zakje',
		weight = 120,
		stack = true,
		close = true,
		description = 'Ketamine zakje voor hbh-illegalcreator.',
	},

}
