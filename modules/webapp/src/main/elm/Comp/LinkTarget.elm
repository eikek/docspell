{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.LinkTarget exposing
    ( LinkTarget(..)
    , makeConcLink
    , makeCorrLink
    , makeCustomFieldLink
    , makeCustomFieldLink2
    , makeFolderLink
    , makeSourceLink
    , makeTagIconLink
    , makeTagLink
    )

import Api.Model.IdName exposing (IdName)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Api.Model.Tag exposing (Tag)
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
    | LinkSource String
    | LinkBookmark String
    | LinkRelatedItems (List String)
    | LinkNone


makeCorrLink :
    { a | corrOrg : Maybe IdName, corrPerson : Maybe IdName }
    -> List ( String, Bool )
    -> (LinkTarget -> msg)
    -> List (Html msg)
makeCorrLink item linkClasses tagger =
    let
        makeOrg idname =
            makeLink linkClasses (LinkCorrOrg >> tagger) idname

        makePerson idname =
            makeLink linkClasses (LinkCorrPerson >> tagger) idname
    in
    combine (Maybe.map makeOrg item.corrOrg) (Maybe.map makePerson item.corrPerson)


makeConcLink :
    { a | concPerson : Maybe IdName, concEquipment : Maybe IdName }
    -> List ( String, Bool )
    -> (LinkTarget -> msg)
    -> List (Html msg)
makeConcLink item linkClasses tagger =
    let
        makePerson idname =
            makeLink linkClasses (LinkConcPerson >> tagger) idname

        makeEquip idname =
            makeLink linkClasses (LinkConcEquip >> tagger) idname
    in
    combine (Maybe.map makePerson item.concPerson) (Maybe.map makeEquip item.concEquipment)


makeFolderLink :
    { a | folder : Maybe IdName }
    -> List ( String, Bool )
    -> (LinkTarget -> msg)
    -> Html msg
makeFolderLink item linkClasses tagger =
    let
        makeFolder idname =
            makeLink linkClasses (LinkFolder >> tagger) idname
    in
    Maybe.map makeFolder item.folder
        |> Maybe.withDefault (text "-")


makeTagLink :
    IdName
    -> List ( String, Bool )
    -> (LinkTarget -> msg)
    -> Html msg
makeTagLink tagId classes tagger =
    makeIconLink (i [ class "fa fa-tag mr-2" ] []) classes (LinkTag >> tagger) tagId


makeTagIconLink :
    Tag
    -> Html msg
    -> List ( String, Bool )
    -> (LinkTarget -> msg)
    -> Html msg
makeTagIconLink tagId icon classes tagger =
    makeIconLink icon classes (LinkTag >> tagger) tagId


makeCustomFieldLink :
    ItemFieldValue
    -> List ( String, Bool )
    -> (LinkTarget -> msg)
    -> Html msg
makeCustomFieldLink cv classes tagger =
    Util.CustomField.renderValue2
        classes
        (tagger (LinkCustomField cv) |> Just)
        cv


makeCustomFieldLink2 :
    ItemFieldValue
    -> List ( String, Bool )
    -> (LinkTarget -> msg)
    -> Html msg
makeCustomFieldLink2 cv classes tagger =
    Util.CustomField.renderValue2
        classes
        (tagger (LinkCustomField cv) |> Just)
        cv


makeSourceLink :
    List ( String, Bool )
    -> (LinkTarget -> msg)
    -> String
    -> Html msg
makeSourceLink classes tagger str =
    makeLink classes (.name >> LinkSource >> tagger) (IdName "" str)



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


makeIconLink :
    Html msg
    -> List ( String, Bool )
    -> (IdName -> msg)
    -> { x | id : String, name : String }
    -> Html msg
makeIconLink icon classes tagger tag =
    a
        [ onClick (tagger (IdName tag.id tag.name))
        , href "#"
        , classList classes
        ]
        [ icon
        , span []
            [ text tag.name
            ]
        ]
