module Comp.UserForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getUser
    , isNewUser
    , isValid
    , update
    , view
    )

import Api.Model.User exposing (User)
import Comp.Dropdown
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Data.UserState exposing (UserState)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Util.Maybe


type alias Model =
    { user : User
    , login : String
    , email : Maybe String
    , state : Comp.Dropdown.Model UserState
    , password : Maybe String
    }


emptyModel : Model
emptyModel =
    { user = Api.Model.User.empty
    , login = ""
    , email = Nothing
    , password = Nothing
    , state =
        Comp.Dropdown.makeSingleList
            { makeOption =
                \s ->
                    { value = Data.UserState.toString s
                    , text = Data.UserState.toString s
                    , additional = ""
                    }
            , placeholder = ""
            , options = Data.UserState.all
            , selected = List.head Data.UserState.all
            }
    }


isValid : Model -> Bool
isValid model =
    if model.user.login == "" then
        model.login /= "" && Util.Maybe.nonEmpty model.password

    else
        True


isNewUser : Model -> Bool
isNewUser model =
    model.user.login == ""


getUser : Model -> User
getUser model =
    let
        s =
            model.user

        state =
            Comp.Dropdown.getSelected model.state
                |> List.head
                |> Maybe.withDefault Data.UserState.Active
                |> Data.UserState.toString
    in
    { s
        | login = model.login
        , email = model.email
        , state = state
        , password = model.password
    }


type Msg
    = SetLogin String
    | SetUser User
    | SetEmail String
    | StateMsg (Comp.Dropdown.Msg UserState)
    | SetPassword String


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetUser t ->
            let
                state =
                    Comp.Dropdown.makeSingleList
                        { makeOption =
                            \s ->
                                { value = Data.UserState.toString s
                                , text = Data.UserState.toString s
                                , additional = ""
                                }
                        , placeholder = ""
                        , options = Data.UserState.all
                        , selected =
                            Data.UserState.fromString t.state
                                |> Maybe.map (\u -> List.filter ((==) u) Data.UserState.all)
                                |> Maybe.andThen List.head
                                |> Util.Maybe.withDefault (List.head Data.UserState.all)
                        }
            in
            ( { model
                | user = t
                , login = t.login
                , email = t.email
                , password = t.password
                , state = state
              }
            , Cmd.none
            )

        StateMsg m ->
            let
                ( m1, c1 ) =
                    Comp.Dropdown.update m model.state
            in
            ( { model | state = m1 }, Cmd.map StateMsg c1 )

        SetLogin n ->
            ( { model | login = n }, Cmd.none )

        SetEmail e ->
            ( { model
                | email =
                    if e == "" then
                        Nothing

                    else
                        Just e
              }
            , Cmd.none
            )

        SetPassword p ->
            ( { model
                | password =
                    if p == "" then
                        Nothing

                    else
                        Just p
              }
            , Cmd.none
            )


view : UiSettings -> Model -> Html Msg
view settings model =
    div [ class "ui form" ]
        [ div
            [ classList
                [ ( "field", True )
                , ( "error", model.login == "" )
                , ( "invisible", model.user.login /= "" )
                ]
            ]
            [ label [] [ text "Login*" ]
            , input
                [ type_ "text"
                , onInput SetLogin
                , placeholder "Login"
                , value model.login
                ]
                []
            ]
        , div [ class "field" ]
            [ label [] [ text "E-Mail" ]
            , input
                [ onInput SetEmail
                , model.email |> Maybe.withDefault "" |> value
                , placeholder "E-Mail"
                ]
                []
            ]
        , div [ class "field" ]
            [ label [] [ text "State" ]
            , Html.map StateMsg (Comp.Dropdown.view settings model.state)
            ]
        , div
            [ classList
                [ ( "field", True )
                , ( "invisible", model.user.login /= "" )
                , ( "error", Util.Maybe.isEmpty model.password )
                ]
            ]
            [ label [] [ text "Password*" ]
            , input
                [ type_ "text"
                , onInput SetPassword
                , placeholder "Password"
                , Maybe.withDefault "" model.password |> value
                ]
                []
            ]
        ]
