module Comp.EmailInput exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.ContactList exposing (ContactList)
import Data.ContactType
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Util.Html exposing (onKeyUp)
import Util.List
import Util.Maybe


type alias Model =
    { input : String
    , menuOpen : Bool
    , candidates : List String
    , active : Maybe String
    }


init : Model
init =
    { input = ""
    , menuOpen = False
    , candidates = []
    , active = Nothing
    }


type Msg
    = SetInput String
    | ContactResp (Result Http.Error ContactList)
    | KeyPress Int
    | AddEmail String
    | RemoveEmail String


getCandidates : Flags -> Model -> Cmd Msg
getCandidates flags model =
    case Util.Maybe.fromString model.input of
        Just q ->
            Api.getContacts flags (Just Data.ContactType.Email) (Just q) ContactResp

        Nothing ->
            Cmd.none


update : Flags -> List String -> Msg -> Model -> ( Model, Cmd Msg, List String )
update flags current msg model =
    case msg of
        SetInput str ->
            let
                nm =
                    { model | input = str, menuOpen = str /= "" }
            in
            ( nm, getCandidates flags nm, current )

        ContactResp (Ok list) ->
            ( { model
                | candidates = List.map .value (List.take 10 list.items)
                , active = Nothing
                , menuOpen = list.items /= []
              }
            , Cmd.none
            , current
            )

        ContactResp (Err _) ->
            ( model, Cmd.none, current )

        KeyPress code ->
            let
                addCurrent =
                    let
                        email =
                            Maybe.withDefault model.input model.active
                    in
                    update flags current (AddEmail email) model
            in
            case Util.Html.intToKeyCode code of
                Just Util.Html.Up ->
                    let
                        prev =
                            case model.active of
                                Nothing ->
                                    List.reverse model.candidates
                                        |> List.head

                                Just act ->
                                    Util.List.findPrev (\e -> e == act) model.candidates
                    in
                    ( { model | active = prev }, Cmd.none, current )

                Just Util.Html.Down ->
                    let
                        next =
                            case model.active of
                                Nothing ->
                                    List.head model.candidates

                                Just act ->
                                    Util.List.findNext (\e -> e == act) model.candidates
                    in
                    ( { model | active = next }, Cmd.none, current )

                Just Util.Html.Enter ->
                    addCurrent

                Just Util.Html.Space ->
                    addCurrent

                _ ->
                    ( model, Cmd.none, current )

        AddEmail str ->
            ( { model | input = "", menuOpen = False }
            , Cmd.none
            , Util.List.distinct (current ++ [ String.trim str ])
            )

        RemoveEmail str ->
            ( model, Cmd.none, List.filter (\e -> e /= str) current )


view : List String -> Model -> Html Msg
view values model =
    div
        [ classList
            [ ( "ui search dropdown multiple selection", True )
            , ( "open", model.menuOpen )
            ]
        ]
        (List.map renderValue values
            ++ [ input
                    [ type_ "text"
                    , class "search"
                    , placeholder "Recipients…"
                    , onKeyUp KeyPress
                    , onInput SetInput
                    ]
                    [ text model.input
                    ]
               ]
            ++ [ renderMenu model ]
        )


renderValue : String -> Html Msg
renderValue str =
    a
        [ class "ui label"
        , href "#"
        , onClick (RemoveEmail str)
        ]
        [ text str
        , i [ class "delete icon" ] []
        ]


renderMenu : Model -> Html Msg
renderMenu model =
    let
        mkItem v =
            a
                [ classList
                    [ ( "item", True )
                    , ( "active", model.active == Just v )
                    ]
                , href "#"
                , onClick (AddEmail v)
                ]
                [ text v
                ]
    in
    div
        [ classList
            [ ( "menu", True )
            , ( "transition visible", model.menuOpen )
            ]
        ]
        (List.map mkItem model.candidates)
