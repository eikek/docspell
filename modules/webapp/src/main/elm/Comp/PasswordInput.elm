module Comp.PasswordInput exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
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
