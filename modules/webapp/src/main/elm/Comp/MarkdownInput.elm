module Comp.MarkdownInput exposing
    ( Model
    , Msg
    , init
    , update
    , view
    , viewCheatLink
    , viewContent
    , viewEditLink
    , viewPreviewLink
    , viewSplitLink
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Markdown


type Display
    = Edit
    | Preview
    | Split


type alias Model =
    { display : Display
    , cheatSheetUrl : String
    }


init : Model
init =
    { display = Edit
    , cheatSheetUrl = "https://www.markdownguide.org/cheat-sheet"
    }


type Msg
    = SetText String
    | SetDisplay Display


update : String -> Msg -> Model -> ( Model, String )
update txt msg model =
    case msg of
        SetText str ->
            ( model, str )

        SetDisplay dsp ->
            ( { model | display = dsp }, txt )


viewContent : String -> Model -> Html Msg
viewContent txt model =
    case model.display of
        Edit ->
            editDisplay txt

        Preview ->
            previewDisplay txt

        Split ->
            splitDisplay txt


viewEditLink : (Bool -> Attribute Msg) -> Model -> Html Msg
viewEditLink classes model =
    a
        [ onClick (SetDisplay Edit)
        , classes (model.display == Edit)
        , href "#"
        ]
        [ text "Edit"
        ]


viewPreviewLink : (Bool -> Attribute Msg) -> Model -> Html Msg
viewPreviewLink classes model =
    a
        [ onClick (SetDisplay Preview)
        , classes (model.display == Preview)
        , href "#"
        ]
        [ text "Preview"
        ]


viewSplitLink : (Bool -> Attribute Msg) -> Model -> Html Msg
viewSplitLink classes model =
    a
        [ onClick (SetDisplay Split)
        , classes (model.display == Split)
        , href "#"
        ]
        [ text "Split"
        ]


viewCheatLink : String -> Model -> Html msg
viewCheatLink classes model =
    a
        [ class classes
        , target "_new"
        , href model.cheatSheetUrl
        ]
        [ i [ class "ui help icon" ] []
        , text "Supports Markdown"
        ]


view : String -> Model -> Html Msg
view txt model =
    div []
        [ div [ class "ui top attached tabular mini menu" ]
            [ viewEditLink
                (\act ->
                    classList
                        [ ( "ui link item", True )
                        , ( "active", act )
                        ]
                )
                model
            , viewPreviewLink
                (\act ->
                    classList
                        [ ( "ui link item", True )
                        , ( "active", act )
                        ]
                )
                model
            , viewSplitLink
                (\act ->
                    classList
                        [ ( "ui link item", True )
                        , ( "active", act )
                        ]
                )
                model
            , viewCheatLink "ui right floated help-link link item" model
            ]
        , div [ class "ui bottom attached segment" ]
            [ viewContent txt model
            ]
        ]


editDisplay : String -> Html Msg
editDisplay txt =
    textarea
        [ class "markdown-editor"
        , onInput SetText
        , placeholder "Add notes here…"
        ]
        [ text txt ]


previewDisplay : String -> Html Msg
previewDisplay txt =
    Markdown.toHtml [ class "markdown-preview" ] txt


splitDisplay : String -> Html Msg
splitDisplay txt =
    div [ class "ui grid" ]
        [ div [ class "row" ]
            [ div [ class "eight wide column markdown-split" ]
                [ editDisplay txt
                ]
            , div [ class "eight wide column markdown-split" ]
                [ previewDisplay txt
                ]
            ]
        ]
