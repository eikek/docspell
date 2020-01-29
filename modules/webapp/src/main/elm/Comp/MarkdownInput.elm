module Comp.MarkdownInput exposing
    ( Model
    , Msg
    , init
    , update
    , view
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
    { display = Split
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


view : String -> Model -> Html Msg
view txt model =
    div []
        [ div [ class "ui top attached tabular mini menu" ]
            [ a
                [ classList
                    [ ( "ui link item", True )
                    , ( "active", model.display == Edit )
                    ]
                , onClick (SetDisplay Edit)
                , href "#"
                ]
                [ text "Edit"
                ]
            , a
                [ classList
                    [ ( "ui link item", True )
                    , ( "active", model.display == Preview )
                    ]
                , onClick (SetDisplay Preview)
                , href "#"
                ]
                [ text "Preview"
                ]
            , a
                [ classList
                    [ ( "ui link item", True )
                    , ( "active", model.display == Split )
                    ]
                , onClick (SetDisplay Split)
                , href "#"
                ]
                [ text "Split"
                ]
            , a
                [ class "ui right floated help-link link item"
                , target "_new"
                , href model.cheatSheetUrl
                ]
                [ i [ class "ui help icon" ] []
                , text "Supports Markdown"
                ]
            ]
        , div [ class "ui bottom attached segment" ]
            [ case model.display of
                Edit ->
                    editDisplay txt

                Preview ->
                    previewDisplay txt

                Split ->
                    splitDisplay txt
            ]
        ]


editDisplay : String -> Html Msg
editDisplay txt =
    textarea
        [ class "markdown-editor"
        , onInput SetText
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
