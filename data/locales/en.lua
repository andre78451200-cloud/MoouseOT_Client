locale = {
  name = "en",
  charset = "cp1252",
  languageName = "English",

  formatNumbers = true,
  decimalSeperator = '.',
  thousandsSeperator = ',',

  -- translations are not needed because everything is already in english
  translation = {
    ["Select monster"] = "Select monster",
    ["Select monster to proceed."] = "Select monster to proceed.",
    ["Select creature to proceed."] = "Select creature to proceed.",
    ["Manage control buttons"] = "Manage control buttons",
    ["Open QuestLog Tracker"] = "Open QuestLog Tracker",
    ["Only Capture Game Window"] = "Only Capture Game Window",
    ["Keep Blacklog of the Screenshots of the Last 5 Seconds"] = "Keep Blacklog of the Screenshots of the Last 5 Seconds",
    ["Enable Auto Screenshots"] = "Enable Auto Screenshots",
    ["Select all events that sould trigger auto Screenshots:"] = "Select all events that should trigger auto Screenshots:",
    ["Reset"] = "Reset",
    ["Open Screenshots Folder"] = "Open Screenshots Folder",
    ["General Stats"] = "General Stats",
    ["Highscores"] = "Highscores",
    ["Cyclopedia"] = "Cyclopedia",
    ["Open Boss Slots dialog"] = "Open Boss Slots dialog",
    ["Open Bosstiary dialog"] = "Open Bosstiary dialog",
    ["Bestiary Tracker"] = "Bestiary Tracker",
    ["Open rewardWall"] = "Open rewardWall",
    ["Customise Character"] = "Customise Character",
    ["Prey Dialog"] = "Prey Dialog",
    ["Bosstiary Tracker"] = "Bosstiary Tracker",
    ["Close read-only"] = "Close read-only",
    ["Open read-only"] = "Open read-only",
    ["Clear Messages"] = "Clear Messages",
    ["Save Messages"] = "Save Messages",
    ["Channel appended to %s"] = "Channel appended to %s",
  ["You need at least 5 Prey Wildcards to select a specific creature."] = "You need at least 5 Prey Wildcards to select a specific creature.",
  ["You have: "] = "You have: ",
  ["wildcards."] = "wildcards.",
  ["You don't have enough gold coins."] = "You don't have enough gold coins.",
  ["Required: "] = "Required: ",
  ["gold coins."] = "gold coins.",
  ["Bank: "] = "Bank: ",
  ["Backpack: "] = "Backpack: ",
  ["Total: "] = "Total: ",
  ["You need at least 1 Prey Wildcard to use bonus reroll."] = "You need at least 1 Prey Wildcard to use bonus reroll.",
  ["You need at least 1 Prey Wildcard to use automatic bonus reroll."] = "You need at least 1 Prey Wildcard to use automatic bonus reroll.",
  ["You need at least 5 Prey Wildcards to lock prey."] = "You need at least 5 Prey Wildcards to lock prey."
  }
}

modules.client_locales.installLocale(locale)
