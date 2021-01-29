module Comp.UserTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    , view2
    )

import Api.Model.User exposing (User)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S
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



--- View


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



--- View2


view2 : Model -> Html Msg
view2 model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "w-px whitespace-nowrap" ] []
                , th [ class "text-left" ] [ text "Login" ]
                , th [ class "text-center" ] [ text "State" ]
                , th [ class "hidden md:table-cell text-left" ] [ text "Email" ]
                , th [ class "hidden md:table-cell text-center" ] [ text "Logins" ]
                , th [ class "hidden sm:table-cell text-center" ] [ text "Last Login" ]
                , th [ class "hidden md:table-cell text-center" ] [ text "Created" ]
                ]
            ]
        , tbody []
            (List.map (renderUserLine2 model) model.users)
        ]


renderUserLine2 : Model -> User -> Html Msg
renderUserLine2 model user =
    tr
        [ classList [ ( "active", model.selected == Just user ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell (Select user)
        , td [ class "text-left" ]
            [ text user.login
            ]
        , td [ class "text-center" ]
            [ text user.state
            ]
        , td [ class "hidden md:table-cell text-left" ]
            [ Maybe.withDefault "" user.email |> text
            ]
        , td [ class "hidden md:table-cell text-center" ]
            [ String.fromInt user.loginCount |> text
            ]
        , td [ class "hidden sm:table-cell text-center" ]
            [ Maybe.map formatDateTime user.lastLogin |> Maybe.withDefault "" |> text
            ]
        , td [ class "hidden md:table-cell text-center" ]
            [ formatDateTime user.created |> text
            ]
        ]
