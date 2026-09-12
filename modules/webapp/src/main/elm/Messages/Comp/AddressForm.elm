{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.AddressForm exposing
    ( Texts
    , de
    , fr
    , ja
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
    , city = "Ort"
    , country = "Land"
    }


fr : Texts
fr =
    { selectCountry = "Choix pays"
    , street = "rue"
    , zipCode = "Code Postal"
    , city = "Ville"
    , country = "Pays"
    }


ja : Texts
ja =
    { selectCountry = "国を選択"
    , street = "通り"
    , zipCode = "郵便番号"
    , city = "市区町村"
    , country = "国"
    }
