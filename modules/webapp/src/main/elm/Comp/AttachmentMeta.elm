{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.AttachmentMeta exposing
    ( Model
    , Msg
    , init
    , update
    , view2
    )

import Api
import Api.Model.AttachmentMeta exposing (AttachmentMeta)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.Label exposing (Label)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.Comp.AttachmentMeta exposing (Texts)
import Styles as S


type alias Model =
    { id : String
    , meta : DataResult AttachmentMeta
    }


type DataResult a
    = NotAvailable
    | Success a
    | HttpFailure Http.Error


emptyModel : Model
emptyModel =
    { id = ""
    , meta = NotAvailable
    }


init : Flags -> String -> ( Model, Cmd Msg )
init flags id =
    ( { emptyModel | id = id }
    , Api.getAttachmentMeta flags id MetaResp
    )


type Msg
    = MetaResp (Result Http.Error AttachmentMeta)


update : Msg -> Model -> Model
update msg model =
    case msg of
        MetaResp (Ok am) ->
            { model | meta = Success am }

        MetaResp (Err err) ->
            { model | meta = HttpFailure err }



--- View2


view2 : Texts -> List (Attribute Msg) -> Model -> Html Msg
view2 texts attrs model =
    div attrs
        [ h3 [ class S.header3 ]
            [ text texts.extractedMetadata
            ]
        , case model.meta of
            NotAvailable ->
                B.loadingDimmer
                    { active = True
                    , label = texts.basics.loading
                    }

            HttpFailure err ->
                div [ class S.errorMessage ]
                    [ text (texts.httpError err)
                    ]

            Success data ->
                viewData2 texts data
        ]


viewData2 : Texts -> AttachmentMeta -> Html Msg
viewData2 texts meta =
    div [ class "flex flex-col" ]
        [ div [ class "text-lg font-bold" ]
            [ text texts.content
            ]
        , div [ class "px-2 py-2 text-sm bg-yellow-50 dark:bg-stone-800 break-words whitespace-pre max-h-80 overflow-auto" ]
            [ text meta.content
            ]
        , div [ class "text-lg font-bold mt-2" ]
            [ text texts.labels
            ]
        , div [ class "flex fex-row flex-wrap" ]
            (List.map renderLabelItem2 meta.labels)
        , div [ class "text-lg font-bold mt-2" ]
            [ text texts.proposals
            ]
        , viewProposals2 texts meta.proposals
        ]


viewProposals2 : Texts -> ItemProposals -> Html Msg
viewProposals2 texts props =
    let
        mkItem n lbl =
            div
                [ class S.basicLabel
                , class "text-sm"
                ]
                [ text lbl.name
                , div [ class "opacity-75 ml-2" ]
                    [ (String.fromInt (n + 1) ++ ".")
                        |> text
                    ]
                ]

        mkTimeItem ms =
            div
                [ class S.basicLabel
                , class "text-sm"
                ]
                [ texts.formatDateShort ms |> text
                ]
    in
    div [ class "flex flex-col" ]
        [ div [ class "font-bold mb-2" ]
            [ text texts.correspondentOrg
            ]
        , div [ class "flex flex-row flex-wrap space-x-2" ]
            (List.indexedMap mkItem props.corrOrg)
        , div [ class "font-bold mt-3 mb-2" ]
            [ text texts.correspondentPerson
            ]
        , div [ class "flex flex-row flex-wrap space-x-2" ]
            (List.indexedMap mkItem props.corrPerson)
        , div [ class "font-bold mt-3 mb-2" ]
            [ text texts.concerningPerson
            ]
        , div [ class "flex flex-row flex-wrap space-x-2" ]
            (List.indexedMap mkItem props.concPerson)
        , div [ class "font-bold mt-3 mb-2" ]
            [ text texts.concerningEquipment
            ]
        , div [ class "flex flex-row flex-wrap space-x-2" ]
            (List.indexedMap mkItem props.concEquipment)
        , div [ class "font-bold mb-2 mt-3" ]
            [ text texts.itemDate
            ]
        , div [ class "flex flex-row flex-wrap space-x-2" ]
            (List.map mkTimeItem props.itemDate)
        , div [ class "font-bold mt-3 mb-2" ]
            [ text texts.itemDueDate
            ]
        , div [ class "flex flex-row flex-wrap space-x-2 mb-2" ]
            (List.map mkTimeItem props.dueDate)
        ]


renderLabelItem2 : Label -> Html Msg
renderLabelItem2 label =
    renderLabel2 label


renderLabel2 : Label -> Html Msg
renderLabel2 label =
    let
        icon =
            case label.labelType of
                "organization" ->
                    "fa fa-industry"

                "person" ->
                    "fa fa-user"

                "location" ->
                    "fa fa-map-marker"

                "date" ->
                    "fa fa-calendar-alt"

                "misc" ->
                    "fa fa-question"

                "email" ->
                    "fa fa-at"

                "website" ->
                    "fa fa-external-link-alt"

                _ ->
                    "fa fa-tag"
    in
    div
        [ class S.basicLabel
        , class "mt-1 mr-2 text-sm"
        , title label.labelType
        ]
        [ i [ class icon ] []
        , span [ class "ml-2" ]
            [ text label.label
            ]
        , div [ class "opacity-75 ml-3 font-mono" ]
            [ String.fromInt label.beginPos |> text
            , text "-"
            , String.fromInt label.endPos |> text
            ]
        ]
