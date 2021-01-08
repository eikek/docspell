module Comp.LinkTarget exposing
    ( LinkTarget(..)
    , makeConcLink
    , makeCorrLink
    , makeCustomFieldLink
    , makeFolderLink
    , makeTagLink
    )

import Api.Model.IdName exposing (IdName)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.CustomField


type LinkTarget
    = LinkCorrOrg IdName
    | LinkCorrPerson IdName
    | LinkConcPerson IdName
    | LinkConcEquip IdName
    | LinkFolder IdName
    | LinkTag IdName
    | LinkCustomField ItemFieldValue
    | LinkNone


makeCorrLink :
    { a | corrOrg : Maybe IdName, corrPerson : Maybe IdName }
    -> (LinkTarget -> msg)
    -> List (Html msg)
makeCorrLink item tagger =
    let
        makeOrg idname =
            makeLink [] (LinkCorrOrg >> tagger) idname

        makePerson idname =
            makeLink [] (LinkCorrPerson >> tagger) idname
    in
    combine (Maybe.map makeOrg item.corrOrg) (Maybe.map makePerson item.corrPerson)


makeConcLink :
    { a | concPerson : Maybe IdName, concEquipment : Maybe IdName }
    -> (LinkTarget -> msg)
    -> List (Html msg)
makeConcLink item tagger =
    let
        makePerson idname =
            makeLink [] (LinkConcPerson >> tagger) idname

        makeEquip idname =
            makeLink [] (LinkConcEquip >> tagger) idname
    in
    combine (Maybe.map makePerson item.concPerson) (Maybe.map makeEquip item.concEquipment)


makeFolderLink :
    { a | folder : Maybe IdName }
    -> (LinkTarget -> msg)
    -> Html msg
makeFolderLink item tagger =
    let
        makeFolder idname =
            makeLink [] (LinkFolder >> tagger) idname
    in
    Maybe.map makeFolder item.folder
        |> Maybe.withDefault (text "-")


makeTagLink :
    IdName
    -> List ( String, Bool )
    -> (LinkTarget -> msg)
    -> Html msg
makeTagLink tagId classes tagger =
    makeLink classes (LinkTag >> tagger) tagId


makeCustomFieldLink :
    ItemFieldValue
    -> List ( String, Bool )
    -> (LinkTarget -> msg)
    -> Html msg
makeCustomFieldLink cv classes tagger =
    Util.CustomField.renderValue1
        classes
        (tagger (LinkCustomField cv) |> Just)
        cv



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


makeLink : List ( String, Bool ) -> (IdName -> msg) -> IdName -> Html msg
makeLink classes tagger idname =
    a
        [ onClick (tagger idname)
        , href "#"
        , classList classes
        ]
        [ text idname.name
        ]
