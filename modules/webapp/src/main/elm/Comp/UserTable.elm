module Comp.UserTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    )

import Api.Model.User exposing (User)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Time exposing (formatDateTime)


type alias Model =
    { users : List User
    , selected : Maybe User
    }


emptyModel : Model
emptyModel =
    { users = []
    , selected = Nothing
    }


type Msg
    = SetUsers (List User)
    | Select User
    | Deselect


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetUsers list ->
            ( { model | users = list, selected = Nothing }, Cmd.none )

        Select user ->
            ( { model | selected = Just user }, Cmd.none )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none )


view : Model -> Html Msg
view model =
    table [ class "ui selectable table" ]
        [ thead []
            [ tr []
                [ th [ class "collapsing" ] [ text "Login" ]
                , th [ class "collapsing" ] [ text "State" ]
                , th [ class "collapsing" ] [ text "Email" ]
                , th [ class "collapsing" ] [ text "Logins" ]
                , th [ class "collapsing" ] [ text "Last Login" ]
                , th [ class "collapsing" ] [ text "Created" ]
                ]
            ]
        , tbody []
            (List.map (renderUserLine model) model.users)
        ]


renderUserLine : Model -> User -> Html Msg
renderUserLine model user =
    tr
        [ classList [ ( "active", model.selected == Just user ) ]
        , onClick (Select user)
        ]
        [ td [ class "collapsing" ]
            [ text user.login
            ]
        , td [ class "collapsing" ]
            [ text user.state
            ]
        , td [ class "collapsing" ]
            [ Maybe.withDefault "" user.email |> text
            ]
        , td [ class "collapsing" ]
            [ String.fromInt user.loginCount |> text
            ]
        , td [ class "collapsing" ]
            [ Maybe.map formatDateTime user.lastLogin |> Maybe.withDefault "" |> text
            ]
        , td [ class "collapsing" ]
            [ formatDateTime user.created |> text
            ]
        ]
