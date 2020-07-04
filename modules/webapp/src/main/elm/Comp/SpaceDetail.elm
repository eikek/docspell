module Comp.SpaceDetail exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.IdName exposing (IdName)
import Api.Model.SpaceDetail exposing (SpaceDetail)
import Api.Model.User exposing (User)
import Api.Model.UserList exposing (UserList)
import Comp.FixedDropdown
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Util.Http
import Util.Maybe


type alias Model =
    { result : Maybe BasicResult
    , name : Maybe String
    , members : List IdName
    , users : List User
    , memberDropdown : Comp.FixedDropdown.Model IdName
    , selectedMember : Maybe IdName
    }


type Msg
    = SetName String
    | MemberDropdownMsg (Comp.FixedDropdown.Msg IdName)


init : List User -> SpaceDetail -> Model
init users space =
    { result = Nothing
    , name = Util.Maybe.fromString space.name
    , members = space.members
    , users = users
    , memberDropdown =
        Comp.FixedDropdown.initMap .name
            (makeOptions users space.members)
    , selectedMember = Nothing
    }


makeOptions : List User -> List IdName -> List IdName
makeOptions users members =
    let
        toIdName u =
            IdName u.id u.login

        notMember idn =
            List.member idn members |> not
    in
    List.map toIdName users
        |> List.filter notMember



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetName str ->
            ( { model | name = Util.Maybe.fromString str }
            , Cmd.none
            )

        MemberDropdownMsg lmsg ->
            let
                ( mm, sel ) =
                    Comp.FixedDropdown.update lmsg model.memberDropdown
            in
            ( { model
                | memberDropdown = mm
                , selectedMember = sel
              }
            , Cmd.none
            )



--- View


view : Model -> Html Msg
view model =
    div []
        [ div [ class "ui header" ]
            [ text "Name"
            ]
        , div [ class "ui action input" ]
            [ input
                [ type_ "text"
                , onInput SetName
                , Maybe.withDefault "" model.name
                    |> value
                ]
                []
            , button
                [ class "ui icon button"
                ]
                [ i [ class "save icon" ] []
                ]
            ]
        , div [ class "ui header" ]
            [ text "Members"
            ]
        , div [ class "ui form" ]
            [ div [ class "inline field" ]
                [ Html.map MemberDropdownMsg
                    (Comp.FixedDropdown.view
                        (Maybe.map makeItem model.selectedMember)
                        model.memberDropdown
                    )
                , button
                    [ class "ui primary button"
                    ]
                    [ text "Add"
                    ]
                ]
            ]
        , div
            [ class "ui list"
            ]
            (List.map viewMember model.members)
        ]


makeItem : IdName -> Comp.FixedDropdown.Item IdName
makeItem idn =
    Comp.FixedDropdown.Item idn idn.name


viewMember : IdName -> Html Msg
viewMember member =
    div
        [ class "item"
        ]
        [ button
            [ class "ui primary icon button"
            ]
            [ i [ class "delete icon" ] []
            ]
        ]
