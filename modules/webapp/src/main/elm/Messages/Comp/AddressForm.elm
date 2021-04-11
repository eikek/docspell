module Messages.Comp.AddressForm exposing (Texts, gb)


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
