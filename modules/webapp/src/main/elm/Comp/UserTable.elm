module Comp.UserTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api.Model.User exposing (User)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
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
