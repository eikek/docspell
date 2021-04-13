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
import Messages.Comp.UserTable exposing (Texts)
import Styles as S


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


view2 : Texts -> Model -> Html Msg
view2 texts model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "w-px whitespace-nowrap" ] []
                , th [ class "text-left" ] [ text texts.login ]
                , th [ class "text-center" ] [ text texts.state ]
                , th [ class "hidden md:table-cell text-left" ] [ text texts.email ]
                , th [ class "hidden md:table-cell text-center" ] [ text texts.login ]
                , th [ class "hidden sm:table-cell text-center" ] [ text texts.lastLogin ]
                , th [ class "hidden md:table-cell text-center" ]
                    [ text texts.basics.created
                    ]
                ]
            ]
        , tbody []
            (List.map (renderUserLine2 texts model) model.users)
        ]


renderUserLine2 : Texts -> Model -> User -> Html Msg
renderUserLine2 texts model user =
    tr
        [ classList [ ( "active", model.selected == Just user ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (Select user)
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
            [ Maybe.map texts.formatDateTime user.lastLogin |> Maybe.withDefault "" |> text
            ]
        , td [ class "hidden md:table-cell text-center" ]
            [ texts.formatDateTime user.created |> text
            ]
        ]
