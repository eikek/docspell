module Comp.AttachmentMeta exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.AttachmentMeta exposing (AttachmentMeta)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.Label exposing (Label)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Util.Http
import Util.Time


type alias Model =
    { id : String
    , meta : DataResult AttachmentMeta
    }


type DataResult a
    = NotAvailable
    | Success a
    | Failure String


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
            { model | meta = Failure (Util.Http.errorToString err) }


view : Model -> Html Msg
view model =
    div []
        [ h3 [ class "ui header" ]
            [ text "Extracted Meta Data"
            ]
        , case model.meta of
            NotAvailable ->
                div [ class "ui active dimmer" ]
                    [ div [ class "ui loader" ]
                        []
                    ]

            Failure msg ->
                div [ class "ui error message" ]
                    [ text msg
                    ]

            Success data ->
                viewData data
        ]


viewData : AttachmentMeta -> Html Msg
viewData meta =
    div []
        [ div [ class "ui dividing header" ]
            [ text "Content"
            ]
        , div [ class "extracted-text" ]
            [ text meta.content
            ]
        , div [ class "ui dividing header" ]
            [ text "Labels"
            ]
        , div []
            [ div [ class "ui horizontal list" ]
                (List.map renderLabelItem meta.labels)
            ]
        , div [ class "ui dividing header" ]
            [ text "Proposals"
            ]
        , viewProposals meta.proposals
        ]


viewProposals : ItemProposals -> Html Msg
viewProposals props =
    let
        mkItem n lbl =
            div [ class "item" ]
                [ div [ class "ui label" ]
                    [ text lbl.name
                    , div [ class "detail" ]
                        [ (String.fromInt (n + 1) ++ ".")
                            |> text
                        ]
                    ]
                ]

        mkTimeItem ms =
            div [ class "item" ]
                [ div [ class "ui label" ]
                    [ Util.Time.formatDateShort ms |> text
                    ]
                ]
    in
    div []
        [ div [ class "ui small header" ]
            [ text "Correspondent Organization"
            ]
        , div [ class "ui horizontal list" ]
            (List.indexedMap mkItem props.corrOrg)
        , div [ class "ui small header" ]
            [ text "Correspondent Person"
            ]
        , div [ class "ui horizontal list" ]
            (List.indexedMap mkItem props.corrPerson)
        , div [ class "ui small header" ]
            [ text "Concerning Person"
            ]
        , div [ class "ui horizontal list" ]
            (List.indexedMap mkItem props.concPerson)
        , div [ class "ui small header" ]
            [ text "Concerning Equipment"
            ]
        , div [ class "ui horizontal list" ]
            (List.indexedMap mkItem props.concEquipment)
        , div [ class "ui small header" ]
            [ text "Item Date"
            ]
        , div [ class "ui horizontal list" ]
            (List.map mkTimeItem props.itemDate)
        , div [ class "ui small header" ]
            [ text "Item Due Date"
            ]
        , div [ class "ui horizontal list" ]
            (List.map mkTimeItem props.dueDate)
        ]


renderLabelItem : Label -> Html Msg
renderLabelItem label =
    div [ class "item" ]
        [ renderLabel label
        ]


renderLabel : Label -> Html Msg
renderLabel label =
    let
        icon =
            case label.labelType of
                "organization" ->
                    "factory icon"

                "person" ->
                    "user icon"

                "location" ->
                    "map marker icon"

                "date" ->
                    "calendar alternate icon"

                "misc" ->
                    "help icon"

                "email" ->
                    "at icon"

                "website" ->
                    "external alternate icon"

                _ ->
                    "tag icon"
    in
    div
        [ class "ui basic label"
        , title label.labelType
        ]
        [ i [ class icon ] []
        , text label.label
        , div [ class "detail" ]
            [ String.fromInt label.beginPos |> text
            , text "-"
            , String.fromInt label.endPos |> text
            ]
        ]
