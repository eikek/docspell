{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.AddressForm exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { selectCountry : String
    , street : String
    , zipCode : String
    , city : String
    , country : String
    }


gb : Texts
gb =
    { selectCountry = "Select Country"
    , street = "Street"
    , zipCode = "Zip Code"
    , city = "City"
    , country = "Country"
    }


de : Texts
de =
    { selectCountry = "Land auswählen"
    , street = "Straße"
    , zipCode = "Postleitzahl"
    , city = "Stadt"
    , country = "Land"
    }
