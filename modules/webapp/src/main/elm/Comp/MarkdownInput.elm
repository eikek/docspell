module Comp.MarkdownInput exposing
    ( Model
    , Msg
    , init
    , update
    , view
    , viewCheatLink
    , viewCheatLink2
    , viewContent
    , viewContent2
    , viewEditLink
    , viewEditLink2
    , viewPreviewLink
    , viewPreviewLink2
    , viewSplitLink
    , viewSplitLink2
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Markdown
import Styles as S


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



--- View


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



--- View2


viewContent2 : String -> Model -> Html Msg
viewContent2 txt model =
    case model.display of
        Edit ->
            editDisplay2 txt

        Preview ->
            previewDisplay2 txt

        Split ->
            splitDisplay2 txt


viewEditLink2 : (Bool -> Attribute Msg) -> Model -> Html Msg
viewEditLink2 classes model =
    a
        [ onClick (SetDisplay Edit)
        , classes (model.display == Edit)
        , href "#"
        ]
        [ text "Edit"
        ]


viewPreviewLink2 : (Bool -> Attribute Msg) -> Model -> Html Msg
viewPreviewLink2 classes model =
    a
        [ onClick (SetDisplay Preview)
        , classes (model.display == Preview)
        , href "#"
        ]
        [ text "Preview"
        ]


viewSplitLink2 : (Bool -> Attribute Msg) -> Model -> Html Msg
viewSplitLink2 classes model =
    a
        [ onClick (SetDisplay Split)
        , classes (model.display == Split)
        , href "#"
        ]
        [ text "Split"
        ]


viewCheatLink2 : String -> Model -> Html msg
viewCheatLink2 classes model =
    a
        [ class classes
        , target "_new"
        , href model.cheatSheetUrl
        ]
        [ i [ class "fa fa-question mr-2" ] []
        , text "Supports Markdown"
        ]


editDisplay2 : String -> Html Msg
editDisplay2 txt =
    textarea
        [ class S.textAreaInput
        , class "h-full"
        , onInput SetText
        , placeholder "Add notes here…"
        , value txt
        ]
        []


previewDisplay2 : String -> Html Msg
previewDisplay2 txt =
    Markdown.toHtml [ class "markdown-preview" ] txt


splitDisplay2 : String -> Html Msg
splitDisplay2 txt =
    div [ class "flex flex-row justify-evenly" ]
        [ div [ class "w-1/2" ]
            [ editDisplay2 txt
            ]
        , div [ class "w-1/2" ]
            [ previewDisplay2 txt
            ]
        ]
