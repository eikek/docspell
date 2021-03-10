module Data.OrgUse exposing
    ( OrgUse(..)
    , all
    , asString
    , fromString
    , label
    )


type OrgUse
    = Correspondent
    | Disabled


fromString : String -> Maybe OrgUse
fromString str =
    case String.toLower str of
        "correspondent" ->
            Just Correspondent

        "disabled" ->
            Just Disabled

        _ ->
            Nothing


asString : OrgUse -> String
asString pu =
    case pu of
        Correspondent ->
            "correspondent"

        Disabled ->
            "disabled"


label : OrgUse -> String
label pu =
    case pu of
        Correspondent ->
            "Correspondent"

        Disabled ->
            "Disabled"


all : List OrgUse
all =
    [ Correspondent, Disabled ]
