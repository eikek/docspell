module Messages.Data.AccountScope exposing (Texts, de, gb)

import Data.AccountScope exposing (AccountScope)


type alias Texts =
    AccountScope -> String


gb : Texts
gb =
    Data.AccountScope.fold "Personal" "Collective"


de : Texts
de =
    Data.AccountScope.fold "Persönlich" "Kollektiv"
