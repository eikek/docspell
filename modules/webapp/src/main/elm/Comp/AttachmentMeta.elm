module Comp.AttachmentMeta exposing
    ( Model
    , Msg
    , init
    , update
    , view
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
import Styles as S
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



--- View


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



--- View2


view2 : Model -> Html Msg
view2 model =
    div []
        [ h3 [ class S.header3 ]
            [ text "Extracted Meta Data"
            ]
        , case model.meta of
            NotAvailable ->
                B.loadingDimmer True

            Failure msg ->
                div [ class S.errorMessage ]
                    [ text msg
                    ]

            Success data ->
                viewData2 data
        ]


viewData2 : AttachmentMeta -> Html Msg
viewData2 meta =
    div [ class "flex flex-col" ]
        [ div [ class "text-lg font-bold" ]
            [ text "Content"
            ]
        , div [ class "px-2 py-2 text-sm bg-yellow-50 dark:bg-warmgray-800 break-words whitespace-pre max-h-80 overflow-auto" ]
            [ text meta.content
            ]
        , div [ class "text-lg font-bold mt-2" ]
            [ text "Labels"
            ]
        , div [ class "flex fex-row flex-wrap space-x-2" ]
            (List.map renderLabelItem2 meta.labels)
        , div [ class "text-lg font-bold mt-2" ]
            [ text "Proposals"
            ]
        , viewProposals2 meta.proposals
        ]


viewProposals2 : ItemProposals -> Html Msg
viewProposals2 props =
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
                [ Util.Time.formatDateShort ms |> text
                ]
    in
    div [ class "flex flex-col" ]
        [ div [ class "font-bold mb-2" ]
            [ text "Correspondent Organization"
            ]
        , div [ class "flex flex-row flex-wrap space-x-2" ]
            (List.indexedMap mkItem props.corrOrg)
        , div [ class "font-bold mt-3 mb-2" ]
            [ text "Correspondent Person"
            ]
        , div [ class "flex flex-row flex-wrap space-x-2" ]
            (List.indexedMap mkItem props.corrPerson)
        , div [ class "font-bold mt-3 mb-2" ]
            [ text "Concerning Person"
            ]
        , div [ class "flex flex-row flex-wrap space-x-2" ]
            (List.indexedMap mkItem props.concPerson)
        , div [ class "font-bold mt-3 mb-2" ]
            [ text "Concerning Equipment"
            ]
        , div [ class "flex flex-row flex-wrap space-x-2" ]
            (List.indexedMap mkItem props.concEquipment)
        , div [ class "font-bold mb-2 mt-3" ]
            [ text "Item Date"
            ]
        , div [ class "flex flex-row flex-wrap space-x-2" ]
            (List.map mkTimeItem props.itemDate)
        , div [ class "font-bold mt-3 mb-2" ]
            [ text "Item Due Date"
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
                    "fa fa-external-alt"

                _ ->
                    "fa fa-tag"
    in
    div
        [ class S.basicLabel
        , class "mt-1 text-sm"
        , title label.labelType
        ]
        [ i [ class icon ] []
        , span [ class "ml-2" ]
            [ text label.label
            ]
        , div [ class "opacity-75 ml-3" ]
            [ String.fromInt label.beginPos |> text
            , text "-"
            , String.fromInt label.endPos |> text
            ]
        ]
