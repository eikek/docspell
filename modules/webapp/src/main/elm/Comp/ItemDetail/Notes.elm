module Comp.ItemDetail.Notes exposing (view)

import Comp.ItemDetail.Model
    exposing
        ( Model
        , Msg(..)
        , NotesField(..)
        , SaveNameState(..)
        )
import Comp.MarkdownInput
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
import Page exposing (Page(..))
import Styles as S
import Util.String


view : Model -> Html Msg
view model =
    case model.notesField of
        ViewNotes ->
            div [ class "flex flex-col ds-item-detail-notes" ]
                [ div [ class "flex flex-row items-center border-b dark:border-bluegray-600" ]
                    [ div [ class "flex-grow font-bold text-lg" ]
                        [ text "Notes"
                        ]
                    , div [ class "" ]
                        [ a
                            [ class S.link
                            , onClick ToggleEditNotes
                            , href "#"
                            ]
                            [ i [ class "fa fa-edit mr-2" ] []
                            , text "Edit"
                            ]
                        ]
                    ]
                , div [ class "" ]
                    [ Markdown.toHtml [ class "markdown-preview" ]
                        (Maybe.withDefault "" model.item.notes)
                    ]
                ]

        EditNotes mm ->
            let
                classes act =
                    classList
                        [ ( "opacity-100", act )
                        , ( "opacity-50", not act )
                        ]
            in
            div [ class "flex flex-col ds-item-detail-notes" ]
                [ div [ class "flex flex-col" ]
                    [ div [ class "flex flex-row items-center" ]
                        [ div [ class "font-bold text-lg" ]
                            [ text "Notes"
                            ]
                        , div [ class "flex flex-grow justify-end text-sm" ]
                            [ Html.map NotesEditMsg
                                (Comp.MarkdownInput.viewEditLink2 classes mm)
                            , span [ class "px-3" ] [ text "•" ]
                            , Html.map NotesEditMsg
                                (Comp.MarkdownInput.viewPreviewLink2 classes mm)
                            ]
                        ]
                    ]
                , div [ class "flex flex-col h-64" ]
                    [ Html.map NotesEditMsg
                        (Comp.MarkdownInput.viewContent2
                            (Maybe.withDefault "" model.notesModel)
                            mm
                        )
                    , div [ class "text-sm flex justify-end" ]
                        [ Comp.MarkdownInput.viewCheatLink2 S.link mm
                        ]
                    , div [ class "flex flex-row mt-1" ]
                        [ a
                            [ class S.primaryButton
                            , href "#"
                            , onClick SaveNotes
                            ]
                            [ i [ class "fa fa-save font-thin mr-2" ] []
                            , text "Save"
                            ]
                        , a
                            [ classList
                                [ ( "invisible hidden", Util.String.isNothingOrBlank model.item.notes )
                                ]
                            , class S.secondaryButton
                            , class "ml-2"
                            , href "#"
                            , onClick ToggleEditNotes
                            ]
                            [ i [ class "fa fa-times mr-2" ] []
                            , text "Cancel"
                            ]
                        ]
                    ]
                ]
