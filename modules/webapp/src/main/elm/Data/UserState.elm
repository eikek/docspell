module Data.UserState exposing
    ( UserState(..)
    , all
    , fromString
    , toString
    )


type UserState
    = Active
    | Disabled


fromString : String -> Maybe UserState
fromString str =
    case String.toLower str of
        "active" ->
            Just Active

        "disabled" ->
            Just Disabled

        _ ->
            Nothing


all : List UserState
all =
    [ Active
    , Disabled
    ]


toString : UserState -> String
toString dir =
    case dir of
        Active ->
            "Active"

        Disabled ->
            "Disabled"
