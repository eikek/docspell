module Comp.ColorTagger exposing
    ( Model
    , Msg
    , ViewOpts
    , init
    , update
    , view
    )

import Comp.FixedDropdown
import Data.Color exposing (Color)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Maybe


type alias FormData =
    Dict String Color


type alias Model =
    { leftDropdown : Comp.FixedDropdown.Model String
    , colors : List Color
    , leftSelect : Maybe String
    }


type Msg
    = AddPair FormData Color
    | DeleteItem FormData String
    | EditItem String Color
    | LeftMsg (Comp.FixedDropdown.Msg String)


init : List String -> List Color -> Model
init leftSel colors =
    { leftDropdown = Comp.FixedDropdown.initString leftSel
    , colors = colors
    , leftSelect = Nothing
    }



--- Update


update : Msg -> Model -> ( Model, Maybe FormData )
update msg model =
    case msg of
        AddPair data color ->
            case model.leftSelect of
                Just l ->
                    ( model
                    , Just (Dict.insert l color data)
                    )

                _ ->
                    ( model, Nothing )

        DeleteItem data k ->
            ( model, Just (Dict.remove k data) )

        EditItem k _ ->
            ( { model
                | leftSelect = Just k
              }
            , Nothing
            )

        LeftMsg lm ->
            let
                ( m_, la ) =
                    Comp.FixedDropdown.update lm model.leftDropdown
            in
            ( { model
                | leftDropdown = m_
                , leftSelect = Util.Maybe.withDefault model.leftSelect la
              }
            , Nothing
            )



--- View


type alias ViewOpts =
    { renderItem : ( String, Color ) -> Html Msg
    , label : String
    , description : Maybe String
    }


view : FormData -> ViewOpts -> Model -> Html Msg
view data opts model =
    div [ class "field" ]
        [ label [] [ text opts.label ]
        , div [ class "inline field" ]
            [ Html.map LeftMsg
                (Comp.FixedDropdown.viewString
                    model.leftSelect
                    model.leftDropdown
                )
            ]
        , div [ class "field" ]
            [ chooseColor
                (AddPair data)
                Data.Color.all
                Nothing
            ]
        , renderFormData opts data
        , span
            [ classList
                [ ( "small-info", True )
                , ( "invisible hidden", opts.description == Nothing )
                ]
            ]
            [ Maybe.withDefault "" opts.description
                |> text
            ]
        ]


renderFormData : ViewOpts -> FormData -> Html Msg
renderFormData opts data =
    let
        values =
            Dict.toList data

        renderItem ( k, v ) =
            div [ class "item" ]
                [ a
                    [ class "link icon"
                    , href "#"
                    , onClick (DeleteItem data k)
                    ]
                    [ i [ class "trash icon" ] []
                    ]
                , a
                    [ class "link icon"
                    , href "#"
                    , onClick (EditItem k v)
                    ]
                    [ i [ class "edit icon" ] []
                    ]
                , opts.renderItem ( k, v )
                ]
    in
    div [ class "ui list" ]
        (List.map renderItem values)


chooseColor : (Color -> msg) -> List Color -> Maybe String -> Html msg
chooseColor tagger colors mtext =
    let
        renderLabel color =
            a
                [ class ("ui large label " ++ Data.Color.toString color)
                , href "#"
                , onClick (tagger color)
                ]
                [ Maybe.withDefault
                    (Data.Color.toString color)
                    mtext
                    |> text
                ]
    in
    div [ class "ui labels" ] <|
        List.map renderLabel colors
