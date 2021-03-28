module Comp.UserForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getUser
    , isNewUser
    , isValid
    , update
    , view2
    )

import Api.Model.User exposing (User)
import Comp.Basic as B
import Comp.Dropdown
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Data.UserState exposing (UserState)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.UserFormComp exposing (Texts)
import Styles as S
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



--- View2


view2 : Texts -> UiSettings -> Model -> Html Msg
view2 texts settings model =
    div [ class "flex flex-col" ]
        [ div
            [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.login
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetLogin
                , placeholder texts.login
                , value model.login
                , class S.textInput
                , classList [ ( S.inputErrorBorder, model.login == "" ) ]
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.email
                ]
            , input
                [ onInput SetEmail
                , type_ "text"
                , model.email |> Maybe.withDefault "" |> value
                , placeholder texts.email
                , class S.textInput
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.state
                ]
            , Html.map StateMsg
                (Comp.Dropdown.view2
                    DS.mainStyle
                    settings
                    model.state
                )
            ]
        , div
            [ class "mb-4"
            , classList [ ( "hidden", model.user.login /= "" ) ]
            ]
            [ label [ class S.inputLabel ]
                [ text texts.password
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetPassword
                , placeholder texts.password
                , Maybe.withDefault "" model.password |> value
                , class S.textInput
                , classList [ ( S.inputErrorBorder, Util.Maybe.isEmpty model.password ) ]
                ]
                []
            ]
        ]
