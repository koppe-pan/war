defmodule War do
  @moduledoc """
  War keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @pirate_words [
    "ahoy",
    "matey",

    # Source: https://github.com/mikewesthad/pirate-speak/blob/master/lib/pirate-speak.js
    "helm",
    "grog",
    "vast",
    "coin",
    "coins",
    "admiral",
    "rum",
    "barrel",
    "lad",
    "mate",
    "parrot",
    "hornswaggle",
    "hails",
    "shipshape",
    "shanty",
    "keelhaul",
    "doubloon",
    "crew",
    "eyepatch",
    "debt",
    "wench",
    "wenches",
    "grub",
    "shipmate",
    "sail",
    "maties",
    "bluderbuss",
    "hook",
    "yoho",
    "yohoho",
    "yohohoho",
    "fleebag",
    "sunk",
    "isle",
    "brig",
    "lasses",
    "lass",
    "blimey",
    "parchment",
    "scallywags",
    "starboard",
    "cargo",
    "yarr",
    "puny",
    "swoggler",
    "booty",
    "beauties",
    "duty",
    "aye",
    "ye",
    "yer",

    # Source: https://gist.github.com/devlaers/1308006#file-pirate_phrases-txt
    "yo-ho-ho",
    "ahoy",
    "avast",
    "arrr",
    "blaggart",
    "foul",
    "whar",
    "comely",
    "broadside",
    "fleabag",
    "skull",
    "scuppers",
    "buried",
    "treasure"
  ]

  def generate_id() do
    words = @pirate_words |> Enum.shuffle() |> Enum.take(2)
    [random_number] = Enum.take_random(100..9999, 1)
    Enum.join(words, "-") <> "-" <> to_string(random_number)
  end
end
