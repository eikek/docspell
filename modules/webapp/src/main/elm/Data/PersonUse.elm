module Data.PersonUse exposing
    ( PersonUse(..)
    , all
    , asString
    , fromString
    , label
    , spanPersonList
    )

import Api.Model.Person exposing (Person)


type PersonUse
    = Correspondent
    | Concerning
    | Both


fromString : String -> Maybe PersonUse
fromString str =
    case String.toLower str of
        "concerning" ->
            Just Concerning

        "correspondent" ->
            Just Correspondent

        "both" ->
            Just Both

        _ ->
            Nothing


asString : PersonUse -> String
asString pu =
    case pu of
        Correspondent ->
            "correspondent"

        Concerning ->
            "concerning"

        Both ->
            "both"


label : PersonUse -> String
label pu =
    case pu of
        Correspondent ->
            "Correspondent"

        Concerning ->
            "Concerning"

        Both ->
            "Both"


all : List PersonUse
all =
    [ Correspondent, Concerning, Both ]


spanPersonList : List Person -> { concerning : List Person, correspondent : List Person }
spanPersonList input =
    let
        init =
            { concerning = [], correspondent = [] }

        parseUse p =
            fromString p.use
                |> Maybe.withDefault Both

        merge p res =
            case parseUse p of
                Concerning ->
                    { res | concerning = p :: res.concerning }

                Correspondent ->
                    { res | correspondent = p :: res.correspondent }

                Both ->
                    { res
                        | correspondent = p :: res.correspondent
                        , concerning = p :: res.concerning
                    }
    in
    List.foldl merge init input
