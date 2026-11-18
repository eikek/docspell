{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.MarkdownInput exposing
    ( Model
    , Msg
    , init
    , update
    , viewCheatLink2
    , viewContent2
    , viewEditLink2
    , viewPreviewLink2
    , viewSplitLink2
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Markdown
import Messages.Comp.MarkdownInput exposing (Texts)
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



--- View2


viewContent2 : Texts -> String -> Model -> Html Msg
viewContent2 texts txt model =
    case model.display of
        Edit ->
            editDisplay2 texts txt

        Preview ->
            previewDisplay2 txt

        Split ->
            splitDisplay2 texts txt


viewEditLink2 : String -> (Bool -> Attribute Msg) -> Model -> Html Msg
viewEditLink2 label classes model =
    a
        [ onClick (SetDisplay Edit)
        , classes (model.display == Edit)
        , href "#"
        ]
        [ text label
        ]


viewPreviewLink2 : String -> (Bool -> Attribute Msg) -> Model -> Html Msg
viewPreviewLink2 label classes model =
    a
        [ onClick (SetDisplay Preview)
        , classes (model.display == Preview)
        , href "#"
        ]
        [ text label
        ]


viewSplitLink2 : String -> (Bool -> Attribute Msg) -> Model -> Html Msg
viewSplitLink2 label classes model =
    a
        [ onClick (SetDisplay Split)
        , classes (model.display == Split)
        , href "#"
        ]
        [ text label
        ]


viewCheatLink2 : String -> String -> Model -> Html msg
viewCheatLink2 label classes model =
    a
        [ class classes
        , target "_new"
        , href model.cheatSheetUrl
        ]
        [ i [ class "fa fa-question mr-2" ] []
        , text label
        ]


editDisplay2 : Texts -> String -> Html Msg
editDisplay2 texts txt =
    textarea
        [ class S.textAreaInput
        , class "h-full"
        , onInput SetText
        , placeholder texts.placeholder
        , value txt
        ]
        []


previewDisplay2 : String -> Html Msg
previewDisplay2 txt =
    Markdown.toHtml [ class "markdown-preview" ] txt


splitDisplay2 : Texts -> String -> Html Msg
splitDisplay2 texts txt =
    div [ class "flex flex-row justify-evenly" ]
        [ div [ class "w-1/2" ]
            [ editDisplay2 texts txt
            ]
        , div [ class "w-1/2" ]
            [ previewDisplay2 txt
            ]
        ]
