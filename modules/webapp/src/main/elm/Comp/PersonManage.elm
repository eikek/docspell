module Comp.PersonManage exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.Person
import Api.Model.PersonList exposing (PersonList)
import Comp.PersonForm
import Comp.PersonTable
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Util.Http
import Util.Maybe


type alias Model =
    { tableModel : Comp.PersonTable.Model
    , formModel : Comp.PersonForm.Model
    , viewMode : ViewMode
    , formError : Maybe String
    , loading : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    , query : String
    }


type ViewMode
    = Table
    | Form


emptyModel : Model
emptyModel =
    { tableModel = Comp.PersonTable.emptyModel
    , formModel = Comp.PersonForm.emptyModel
    , viewMode = Table
    , formError = Nothing
    , loading = False
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    , query = ""
    }


type Msg
    = TableMsg Comp.PersonTable.Msg
    | FormMsg Comp.PersonForm.Msg
    | LoadPersons
    | PersonResp (Result Http.Error PersonList)
    | SetViewMode ViewMode
    | InitNewPerson
    | Submit
    | SubmitResp (Result Http.Error BasicResult)
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete
    | SetQuery String


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg m ->
            let
                ( tm, tc ) =
                    Comp.PersonTable.update flags m model.tableModel

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
                        Just org ->
                            update flags (FormMsg (Comp.PersonForm.SetPerson org)) m2

                        Nothing ->
                            ( m2, Cmd.none )
            in
            ( m3, Cmd.batch [ c2, c3 ] )

        FormMsg m ->
            let
                ( m2, c2 ) =
                    Comp.PersonForm.update flags m model.formModel
            in
            ( { model | formModel = m2 }, Cmd.map FormMsg c2 )

        LoadPersons ->
            ( { model | loading = True }, Api.getPersons flags model.query PersonResp )

        PersonResp (Ok orgs) ->
            let
                m2 =
                    { model | viewMode = Table, loading = False }
            in
            update flags (TableMsg (Comp.PersonTable.SetPersons orgs.items)) m2

        PersonResp (Err _) ->
            ( { model | loading = False }, Cmd.none )

        SetViewMode m ->
            let
                m2 =
                    { model | viewMode = m }
            in
            case m of
                Table ->
                    update flags (TableMsg Comp.PersonTable.Deselect) m2

                Form ->
                    ( m2, Cmd.none )

        InitNewPerson ->
            let
                nm =
                    { model | viewMode = Form, formError = Nothing }

                org =
                    Api.Model.Person.empty
            in
            update flags (FormMsg (Comp.PersonForm.SetPerson org)) nm

        Submit ->
            let
                person =
                    Comp.PersonForm.getPerson model.formModel

                valid =
                    Comp.PersonForm.isValid model.formModel
            in
            if valid then
                ( { model | loading = True }, Api.postPerson flags person SubmitResp )

            else
                ( { model | formError = Just "Please correct the errors in the form." }, Cmd.none )

        SubmitResp (Ok res) ->
            if res.success then
                let
                    ( m2, c2 ) =
                        update flags (SetViewMode Table) model

                    ( m3, c3 ) =
                        update flags LoadPersons m2
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

                person =
                    Comp.PersonForm.getPerson model.formModel

                cmd =
                    if confirmed then
                        Api.deletePerson flags person.id SubmitResp

                    else
                        Cmd.none
            in
            ( { model | deleteConfirm = cm }, cmd )

        SetQuery str ->
            let
                m =
                    { model | query = str }
            in
            ( m, Api.getPersons flags str PersonResp )


view : Model -> Html Msg
view model =
    if model.viewMode == Table then
        viewTable model

    else
        viewForm model


viewTable : Model -> Html Msg
viewTable model =
    div []
        [ div [ class "ui secondary menu" ]
            [ div [ class "horizontally fitted item" ]
                [ div [ class "ui icon input" ]
                    [ input
                        [ type_ "text"
                        , onInput SetQuery
                        , value model.query
                        , placeholder "Search…"
                        ]
                        []
                    , i [ class "ui search icon" ]
                        []
                    ]
                ]
            , div [ class "right menu" ]
                [ div [ class "item" ]
                    [ a
                        [ class "ui primary button"
                        , href "#"
                        , onClick InitNewPerson
                        ]
                        [ i [ class "plus icon" ] []
                        , text "New Person"
                        ]
                    ]
                ]
            ]
        , Html.map TableMsg (Comp.PersonTable.view model.tableModel)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]


viewForm : Model -> Html Msg
viewForm model =
    let
        newPerson =
            model.formModel.org.id == ""
    in
    Html.form [ class "ui segment", onSubmit Submit ]
        [ Html.map YesNoMsg (Comp.YesNoDimmer.view model.deleteConfirm)
        , if newPerson then
            h3 [ class "ui dividing header" ]
                [ text "Create new person"
                ]

          else
            h3 [ class "ui dividing header" ]
                [ text ("Edit org: " ++ model.formModel.org.name)
                , div [ class "sub header" ]
                    [ text "Id: "
                    , text model.formModel.org.id
                    ]
                ]
        , Html.map FormMsg (Comp.PersonForm.view model.formModel)
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
        , a [ class "ui secondary button", onClick (SetViewMode Table), href "" ]
            [ text "Cancel"
            ]
        , if not newPerson then
            a [ class "ui right floated red button", href "", onClick RequestDelete ]
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
