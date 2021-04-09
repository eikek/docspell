module Comp.PersonManage exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.Person
import Api.Model.PersonList exposing (PersonList)
import Api.Model.ReferenceList exposing (ReferenceList)
import Comp.Basic as B
import Comp.MenuBar as MB
import Comp.PersonForm
import Comp.PersonTable
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onSubmit)
import Http
import Messages.PersonManageComp exposing (Texts)
import Styles as S
import Util.Http
import Util.Maybe


type alias Model =
    { tableModel : Comp.PersonTable.Model
    , formModel : Comp.PersonForm.Model
    , viewMode : ViewMode
    , formError : Maybe String
    , loading : Int
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
    , loading = 0
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
    | GetOrgResp (Result Http.Error ReferenceList)


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
            ( { model | loading = model.loading + 2 }
            , Cmd.batch
                [ Api.getPersons flags model.query PersonResp
                , Api.getOrgLight flags GetOrgResp
                ]
            )

        PersonResp (Ok persons) ->
            let
                m2 =
                    { model
                        | viewMode = Table
                        , loading = Basics.max 0 (model.loading - 1)
                    }
            in
            update flags (TableMsg (Comp.PersonTable.SetPersons persons.items)) m2

        PersonResp (Err _) ->
            ( { model | loading = Basics.max 0 (model.loading - 1) }, Cmd.none )

        GetOrgResp (Ok list) ->
            let
                m2 =
                    { model | loading = Basics.max 0 (model.loading - 1) }
            in
            update flags (FormMsg (Comp.PersonForm.SetOrgs list.items)) m2

        GetOrgResp (Err _) ->
            ( { model | loading = Basics.max 0 (model.loading - 1) }, Cmd.none )

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
                ( { model | loading = model.loading + 1 }
                , Api.postPerson flags person SubmitResp
                )

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
                ( { m3 | loading = Basics.max 0 (model.loading - 1) }, Cmd.batch [ c2, c3 ] )

            else
                ( { model
                    | formError = Just res.message
                    , loading = Basics.max 0 (model.loading - 1)
                  }
                , Cmd.none
                )

        SubmitResp (Err err) ->
            ( { model
                | formError = Just (Util.Http.errorToString err)
                , loading = Basics.max 0 (model.loading - 1)
              }
            , Cmd.none
            )

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


isLoading : Model -> Bool
isLoading model =
    model.loading /= 0



--- View2


view2 : Texts -> UiSettings -> Model -> Html Msg
view2 texts settings model =
    if model.viewMode == Table then
        viewTable2 texts model

    else
        viewForm2 texts settings model


viewTable2 : Texts -> Model -> Html Msg
viewTable2 texts model =
    div [ class "flex flex-col" ]
        [ MB.view
            { start =
                [ MB.TextInput
                    { tagger = SetQuery
                    , value = model.query
                    , placeholder = texts.basics.searchPlaceholder
                    , icon = Just "fa fa-search"
                    }
                ]
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewPerson
                    , title = texts.createNewPerson
                    , icon = Just "fa fa-plus"
                    , label = texts.newPerson
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg (Comp.PersonTable.view2 texts.personTable model.tableModel)
        , B.loadingDimmer
            { active = isLoading model
            , label = texts.basics.loading
            }
        ]


viewForm2 : Texts -> UiSettings -> Model -> Html Msg
viewForm2 texts settings model =
    let
        newPerson =
            model.formModel.person.id == ""

        dimmerSettings2 =
            Comp.YesNoDimmer.defaultSettings texts.reallyDeletePerson
                texts.basics.yes
                texts.basics.no
    in
    Html.form
        [ class "md:relative flex flex-col"
        , onSubmit Submit
        ]
        [ Html.map YesNoMsg
            (Comp.YesNoDimmer.viewN
                True
                dimmerSettings2
                model.deleteConfirm
            )
        , if newPerson then
            h3 [ class S.header2 ]
                [ text texts.createNewPerson
                ]

          else
            h3 [ class S.header2 ]
                [ text model.formModel.person.name
                , div [ class "opacity-50 text-sm" ]
                    [ text (texts.basics.id ++ ": ")
                    , text model.formModel.person.id
                    ]
                ]
        , MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , title = texts.basics.submitThisForm
                    , icon = Just "fa fa-save"
                    , label = texts.basics.submit
                    }
                , MB.SecondaryButton
                    { tagger = SetViewMode Table
                    , title = texts.basics.backToList
                    , icon = Just "fa fa-arrow-left"
                    , label = texts.basics.cancel
                    }
                ]
            , end =
                if not newPerson then
                    [ MB.DeleteButton
                        { tagger = RequestDelete
                        , title = texts.deleteThisPerson
                        , icon = Just "fa fa-trash"
                        , label = texts.basics.delete
                        }
                    ]

                else
                    []
            , rootClasses = "mb-4"
            }
        , div
            [ classList
                [ ( "hidden", Util.Maybe.isEmpty model.formError )
                ]
            , class S.errorMessage
            , class "my-2"
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , Html.map FormMsg
            (Comp.PersonForm.view2 texts.personForm
                False
                settings
                model.formModel
            )
        , B.loadingDimmer
            { active = isLoading model
            , label = texts.basics.loading
            }
        ]
