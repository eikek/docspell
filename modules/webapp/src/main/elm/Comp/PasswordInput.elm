module Comp.PasswordInput exposing
    ( Model
    , Msg
    , init
    , update
    , view
    , view2
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Styles as S
import Util.Maybe


type alias Model =
    { show : Bool
    }


init : Model
init =
    { show = False
    }


type Msg
    = ToggleShow (Maybe String)
    | SetPassword String


update : Msg -> Model -> ( Model, Maybe String )
update msg model =
    case msg of
        ToggleShow pw ->
            ( { model | show = not model.show }
            , pw
            )

        SetPassword str ->
            let
                pw =
                    Util.Maybe.fromString str
            in
            ( model, pw )


view : Maybe String -> Model -> Html Msg
view pw model =
    div [ class "ui  left action input" ]
        [ button
            [ class "ui icon button"
            , type_ "button"
            , onClick (ToggleShow pw)
            ]
            [ i
                [ classList
                    [ ( "ui eye icon", True )
                    , ( "slash", model.show )
                    ]
                ]
                []
            ]
        , input
            [ type_ <|
                if model.show then
                    "text"

                else
                    "password"
            , onInput SetPassword
            , Maybe.withDefault "" pw |> value
            ]
            []
        ]



--- View2


view2 : Maybe String -> Bool -> Model -> Html Msg
view2 pw isError model =
    div [ class "relative" ]
        [ div [ class S.inputIcon ]
            [ i
                [ class "fa"
                , if model.show then
                    class "fa-lock-open"

                  else
                    class "fa-lock"
                ]
                []
            ]
        , input
            [ type_ <|
                if model.show then
                    "text"

                else
                    "password"
            , name "passw1"
            , autocomplete False
            , onInput SetPassword
            , Maybe.withDefault "" pw |> value
            , class ("pl-10 pr-10 py-2 rounded" ++ S.textInput)
            , class <|
                if isError then
                    S.inputErrorBorder

                else
                    ""
            , placeholder "Password"
            ]
            []
        , a
            [ class S.inputLeftIconLink
            , class <|
                if isError then
                    S.inputErrorBorder

                else
                    ""
            , onClick (ToggleShow pw)
            , href "#"
            ]
            [ i [ class "fa fa-eye" ] []
            ]
        ]
