module Comp.UserManage exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.User
import Api.Model.UserList exposing (UserList)
import Comp.UserForm
import Comp.UserTable
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit)
import Http
import Util.Http
import Util.Maybe


type alias Model =
    { tableModel : Comp.UserTable.Model
    , formModel : Comp.UserForm.Model
    , viewMode : ViewMode
    , formError : Maybe String
    , loading : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    }


type ViewMode
    = Table
    | Form


emptyModel : Model
emptyModel =
    { tableModel = Comp.UserTable.emptyModel
    , formModel = Comp.UserForm.emptyModel
    , viewMode = Table
    , formError = Nothing
    , loading = False
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    }


type Msg
    = TableMsg Comp.UserTable.Msg
    | FormMsg Comp.UserForm.Msg
    | LoadUsers
    | UserResp (Result Http.Error UserList)
    | SetViewMode ViewMode
    | InitNewUser
    | Submit
    | SubmitResp (Result Http.Error BasicResult)
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg m ->
            let
                ( tm, tc ) =
                    Comp.UserTable.update flags m model.tableModel

                ( m2, c2 ) =
                    ( { model
                        | tableModel = tm
                        , viewMode = Maybe.map (\_ -> Form) tm.selected |> Maybe.withDefault Table
                        , formError =
                            if Util.Maybe.nonEmpty tm.selected then
                                Nothing

                            else
                                model.formError
                      }
                    , Cmd.map TableMsg tc
                    )

                ( m3, c3 ) =
                    case tm.selected of
                        Just user ->
                            update flags (FormMsg (Comp.UserForm.SetUser user)) m2

                        Nothing ->
                            ( m2, Cmd.none )
            in
            ( m3, Cmd.batch [ c2, c3 ] )

        FormMsg m ->
            let
                ( m2, c2 ) =
                    Comp.UserForm.update flags m model.formModel
            in
            ( { model | formModel = m2 }, Cmd.map FormMsg c2 )

        LoadUsers ->
            ( { model | loading = True }, Api.getUsers flags UserResp )

        UserResp (Ok users) ->
            let
                m2 =
                    { model | viewMode = Table, loading = False }
            in
            update flags (TableMsg (Comp.UserTable.SetUsers users.items)) m2

        UserResp (Err _) ->
            ( { model | loading = False }, Cmd.none )

        SetViewMode m ->
            let
                m2 =
                    { model | viewMode = m }
            in
            case m of
                Table ->
                    update flags (TableMsg Comp.UserTable.Deselect) m2

                Form ->
                    ( m2, Cmd.none )

        InitNewUser ->
            let
                nm =
                    { model | viewMode = Form, formError = Nothing }

                user =
                    Api.Model.User.empty
            in
            update flags (FormMsg (Comp.UserForm.SetUser user)) nm

        Submit ->
            let
                user =
                    Comp.UserForm.getUser model.formModel

                valid =
                    Comp.UserForm.isValid model.formModel

                cmd =
                    if Comp.UserForm.isNewUser model.formModel then
                        Api.postNewUser flags user SubmitResp

                    else
                        Api.putUser flags user SubmitResp
            in
            if valid then
                ( { model | loading = True }, cmd )

            else
                ( { model | formError = Just "Please correct the errors in the form." }, Cmd.none )

        SubmitResp (Ok res) ->
            if res.success then
                let
                    ( m2, c2 ) =
                        update flags (SetViewMode Table) model

                    ( m3, c3 ) =
                        update flags LoadUsers m2
                in
                ( { m3 | loading = False }, Cmd.batch [ c2, c3 ] )

            else
                ( { model | formError = Just res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model | formError = Just (Util.Http.errorToString err), loading = False }, Cmd.none )

        RequestDelete ->
            update flags (YesNoMsg Comp.YesNoDimmer.activate) model

        YesNoMsg m ->
            let
                ( cm, confirmed ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm

                user =
                    Comp.UserForm.getUser model.formModel

                cmd =
                    if confirmed then
                        Api.deleteUser flags user.login SubmitResp

                    else
                        Cmd.none
            in
            ( { model | deleteConfirm = cm }, cmd )


view : UiSettings -> Model -> Html Msg
view settings model =
    if model.viewMode == Table then
        viewTable model

    else
        viewForm settings model


viewTable : Model -> Html Msg
viewTable model =
    div []
        [ button [ class "ui basic button", onClick InitNewUser ]
            [ i [ class "plus icon" ] []
            , text "Create new"
            ]
        , Html.map TableMsg (Comp.UserTable.view model.tableModel)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]


viewForm : UiSettings -> Model -> Html Msg
viewForm settings model =
    let
        newUser =
            Comp.UserForm.isNewUser model.formModel
    in
    Html.form [ class "ui segment", onSubmit Submit ]
        [ Html.map YesNoMsg (Comp.YesNoDimmer.view model.deleteConfirm)
        , if newUser then
            h3 [ class "ui dividing header" ]
                [ text "Create new user"
                ]

          else
            h3 [ class "ui dividing header" ]
                [ text ("Edit user: " ++ model.formModel.user.login)
                ]
        , Html.map FormMsg (Comp.UserForm.view settings model.formModel)
        , div
            [ classList
                [ ( "ui error message", True )
                , ( "invisible", Util.Maybe.isEmpty model.formError )
                ]
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , div [ class "ui horizontal divider" ] []
        , button [ class "ui primary button", type_ "submit" ]
            [ text "Submit"
            ]
        , a [ class "ui secondary button", onClick (SetViewMode Table), href "#" ]
            [ text "Cancel"
            ]
        , if not newUser then
            a [ class "ui right floated red button", href "#", onClick RequestDelete ]
                [ text "Delete" ]

          else
            span [] []
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]
