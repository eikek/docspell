module Comp.LinkTarget exposing
    ( LinkTarget(..)
    , makeConcLink
    , makeCorrLink
    , makeFolderLink
    )

import Api.Model.IdName exposing (IdName)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


type LinkTarget
    = LinkCorrOrg IdName
    | LinkCorrPerson IdName
    | LinkConcPerson IdName
    | LinkConcEquip IdName
    | LinkFolder IdName
    | LinkNone


makeCorrLink :
    { a | corrOrg : Maybe IdName, corrPerson : Maybe IdName }
    -> (LinkTarget -> msg)
    -> List (Html msg)
makeCorrLink item tagger =
    let
        makeOrg idname =
            makeLink (LinkCorrOrg >> tagger) idname

        makePerson idname =
            makeLink (LinkCorrPerson >> tagger) idname
    in
    combine (Maybe.map makeOrg item.corrOrg) (Maybe.map makePerson item.corrPerson)


makeConcLink :
    { a | concPerson : Maybe IdName, concEquipment : Maybe IdName }
    -> (LinkTarget -> msg)
    -> List (Html msg)
makeConcLink item tagger =
    let
        makePerson idname =
            makeLink (LinkConcPerson >> tagger) idname

        makeEquip idname =
            makeLink (LinkConcEquip >> tagger) idname
    in
    combine (Maybe.map makePerson item.concPerson) (Maybe.map makeEquip item.concEquipment)


makeFolderLink :
    { a | folder : Maybe IdName }
    -> (LinkTarget -> msg)
    -> Html msg
makeFolderLink item tagger =
    let
        makeFolder idname =
            makeLink (LinkFolder >> tagger) idname
    in
    Maybe.map makeFolder item.folder
        |> Maybe.withDefault (text "-")



--- Helpers


combine : Maybe (Html msg) -> Maybe (Html msg) -> List (Html msg)
combine ma mb =
    case ( ma, mb ) of
        ( Just a, Just b ) ->
            [ a, text ", ", b ]

        ( Just a, Nothing ) ->
            [ a ]

        ( Nothing, Just b ) ->
            [ b ]

        ( Nothing, Nothing ) ->
            [ text "-" ]


makeLink : (IdName -> msg) -> IdName -> Html msg
makeLink tagger idname =
    a
        [ onClick (tagger idname)
        , href "#"
        ]
        [ text idname.name
        ]
