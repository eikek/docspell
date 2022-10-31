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
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.Label exposing (Label)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Messages.Comp.AttachmentMeta exposing (Texts)
import Styles as S


type alias Model =
    { id : String
    , meta : DataResult
    }


type alias EditModel =
    { meta : AttachmentMeta
    , text : String
    }


type DataResult
    = NotAvailable
    | Success AttachmentMeta
    | Editing EditModel
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
    | SaveResp String (Result Http.Error BasicResult)
    | ToggleEdit
    | SaveExtractedText
    | SetExtractedText String


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        MetaResp (Ok am) ->
            ( { model | meta = Success am }, Cmd.none )

        MetaResp (Err err) ->
            ( { model | meta = HttpFailure err }, Cmd.none )

        SaveResp newText (Ok result) ->
            if result.success then
                case model.meta of
                    Editing { meta } ->
                        ( { model | meta = Success { meta | content = newText } }, Cmd.none )

                    _ ->
                        ( model, Cmd.none )

            else
                ( model, Cmd.none )

        SaveResp _ (Err err) ->
            ( { model | meta = HttpFailure err }, Cmd.none )

        ToggleEdit ->
            case model.meta of
                Editing m ->
                    ( { model | meta = Success m.meta }, Cmd.none )

                Success m ->
                    ( { model | meta = Editing { meta = m, text = m.content } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SaveExtractedText ->
            case model.meta of
                Editing em ->
                    ( model
                    , Api.setAttachmentExtractedText flags model.id (Just em.text) (SaveResp em.text)
                    )

                _ ->
                    ( model, Cmd.none )

        SetExtractedText txt ->
            case model.meta of
                Editing em ->
                    ( { model | meta = Editing { em | text = txt } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )



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
                viewData2 texts data Nothing

            Editing em ->
                viewData2 texts em.meta (Just em.text)
        ]


viewData2 : Texts -> AttachmentMeta -> Maybe String -> Html Msg
viewData2 texts meta maybeText =
    div [ class "flex flex-col" ]
        [ div [ class "flex flex-row items-center" ]
            [ div [ class "text-lg font-bold flex flex-grow" ]
                [ text texts.content
                ]
            , case maybeText of
                Nothing ->
                    div [ class "flex text-sm" ]
                        [ a [ href "#", class S.link, onClick ToggleEdit ]
                            [ i [ class "fa fa-edit pr-1" ] []
                            , text texts.basics.edit
                            ]
                        ]

                Just _ ->
                    div [ class "flex text-sm" ]
                        [ a [ href "#", class S.link, onClick ToggleEdit ]
                            [ text texts.basics.cancel
                            ]
                        , span [ class "px-2" ] [ text "•" ]
                        , a [ href "#", class S.link, onClick SaveExtractedText ]
                            [ i [ class "fa fa-save pr-1" ] []
                            , text texts.basics.submit
                            ]
                        ]
            ]
        , case maybeText of
            Nothing ->
                div [ class "px-2 py-2 text-sm bg-yellow-50 dark:bg-stone-800 break-words whitespace-pre max-h-80 overflow-auto" ]
                    [ text meta.content
                    ]

            Just em ->
                textarea
                    [ class "px-2 py-2 text-sm bg-yellow-50 dark:bg-stone-800 break-words whitespace-pre h-80 overflow-auto"
                    , value em
                    , onInput SetExtractedText
                    , rows 10
                    ]
                    []
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
