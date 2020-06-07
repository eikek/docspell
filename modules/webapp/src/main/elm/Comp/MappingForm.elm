module Comp.MappingForm exposing
    ( FormData
    , Model
    , Msg
    , ViewOpts
    , init
    , update
    , view
    )

import Comp.FixedDropdown
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Maybe


type alias FormData =
    Dict String String


type alias Model =
    { leftDropdown : Comp.FixedDropdown.Model String
    , rightDropdown : Comp.FixedDropdown.Model String
    , leftSelect : Maybe String
    , rightSelect : Maybe String
    }


type Msg
    = AddPair FormData
    | DeleteItem FormData String
    | EditItem String String
    | LeftMsg (Comp.FixedDropdown.Msg String)
    | RightMsg (Comp.FixedDropdown.Msg String)


init : List String -> List String -> Model
init leftSel rightSel =
    { leftDropdown = Comp.FixedDropdown.initString leftSel
    , rightDropdown = Comp.FixedDropdown.initString rightSel
    , leftSelect = Nothing
    , rightSelect = Nothing
    }



--- Update


update : Msg -> Model -> ( Model, Maybe FormData )
update msg model =
    case msg of
        AddPair data ->
            case ( model.leftSelect, model.rightSelect ) of
                ( Just l, Just r ) ->
                    ( { model
                        | leftSelect = Nothing
                        , rightSelect = Nothing
                      }
                    , Just (Dict.insert l r data)
                    )

                _ ->
                    ( model, Nothing )

        DeleteItem data k ->
            ( model, Just (Dict.remove k data) )

        EditItem k v ->
            ( { model
                | leftSelect = Just k
                , rightSelect = Just v
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

        RightMsg lm ->
            let
                ( m_, la ) =
                    Comp.FixedDropdown.update lm model.rightDropdown
            in
            ( { model
                | rightDropdown = m_
                , rightSelect = Util.Maybe.withDefault model.rightSelect la
              }
            , Nothing
            )



--- View


type alias ViewOpts =
    { renderItem : ( String, String ) -> Html Msg
    , label : String
    , description : Maybe String
    }


view : FormData -> ViewOpts -> Model -> Html Msg
view data opts model =
    div [ class "field" ]
        [ label [] [ text opts.label ]
        , div [ class "fields" ]
            [ div [ class "inline field" ]
                [ Html.map LeftMsg
                    (Comp.FixedDropdown.viewString
                        model.leftSelect
                        model.leftDropdown
                    )
                ]
            , div [ class "inline field" ]
                [ Html.map RightMsg
                    (Comp.FixedDropdown.viewString
                        model.rightSelect
                        model.rightDropdown
                    )
                ]
            , button
                [ class "ui icon button"
                , onClick (AddPair data)
                , href "#"
                ]
                [ i [ class "add icon" ] []
                ]
            ]
        , span
            [ classList
                [ ( "small-info", True )
                , ( "invisible hidden", opts.description == Nothing )
                ]
            ]
            [ Maybe.withDefault "" opts.description
                |> text
            ]
        , renderFormData opts data
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
