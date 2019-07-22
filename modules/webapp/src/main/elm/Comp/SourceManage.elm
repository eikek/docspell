module Comp.SourceManage exposing ( Model
                               , emptyModel
                               , Msg(..)
                               , view
                               , update)

import Http
import Api
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit)
import Data.Flags exposing (Flags)
import Comp.SourceTable
import Comp.SourceForm
import Comp.YesNoDimmer
import Api.Model.Source
import Api.Model.SourceList exposing (SourceList)
import Api.Model.BasicResult exposing (BasicResult)
import Util.Maybe
import Util.Http

type alias Model =
    { tableModel: Comp.SourceTable.Model
    , formModel: Comp.SourceForm.Model
    , viewMode: ViewMode
    , formError: Maybe String
    , loading: Bool
    , deleteConfirm: Comp.YesNoDimmer.Model
    }

type ViewMode = Table | Form

emptyModel: Model
emptyModel =
    { tableModel = Comp.SourceTable.emptyModel
    , formModel = Comp.SourceForm.emptyModel
    , viewMode = Table
    , formError = Nothing
    , loading = False
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    }

type Msg
    = TableMsg Comp.SourceTable.Msg
    | FormMsg Comp.SourceForm.Msg
    | LoadSources
    | SourceResp (Result Http.Error SourceList)
    | SetViewMode ViewMode
    | InitNewSource
    | Submit
    | SubmitResp (Result Http.Error BasicResult)
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete

update: Flags -> Msg -> Model -> (Model, Cmd Msg)
update flags msg model =
    case msg of
        TableMsg m ->
            let
                (tm, tc) = Comp.SourceTable.update flags m model.tableModel
                (m2, c2) = ({model | tableModel = tm
                            , viewMode = Maybe.map (\_ -> Form) tm.selected |> Maybe.withDefault Table
                            , formError = if Util.Maybe.nonEmpty tm.selected then Nothing else model.formError
                            }
                           , Cmd.map TableMsg tc
                           )
                (m3, c3) = case tm.selected of
                        Just source ->
                            update flags (FormMsg (Comp.SourceForm.SetSource source)) m2
                        Nothing ->
                            (m2, Cmd.none)
            in
                (m3, Cmd.batch [c2, c3])

        FormMsg m ->
            let
                (m2, c2) = Comp.SourceForm.update flags m model.formModel
            in
                ({model | formModel = m2}, Cmd.map FormMsg c2)

        LoadSources ->
            ({model| loading = True}, Api.getSources flags SourceResp)

        SourceResp (Ok sources) ->
            let
                m2 = {model|viewMode = Table, loading = False}
            in
                update flags (TableMsg (Comp.SourceTable.SetSources sources.items)) m2

        SourceResp (Err err) ->
            ({model|loading = False}, Cmd.none)

        SetViewMode m ->
            let
                m2 = {model | viewMode = m }
            in
                case m of
                    Table ->
                        update flags (TableMsg Comp.SourceTable.Deselect) m2
                    Form ->
                        (m2, Cmd.none)

        InitNewSource ->
            let
                nm = {model | viewMode = Form, formError = Nothing }
                source = Api.Model.Source.empty
            in
                update flags (FormMsg (Comp.SourceForm.SetSource source)) nm

        Submit ->
            let
                source = Comp.SourceForm.getSource model.formModel
                valid = Comp.SourceForm.isValid model.formModel
            in if valid then
                   ({model|loading = True}, Api.postSource flags source SubmitResp)
               else
                   ({model|formError = Just "Please correct the errors in the form."}, Cmd.none)

        SubmitResp (Ok res) ->
            if res.success then
                let
                    (m2, c2) = update flags (SetViewMode Table) model
                    (m3, c3) = update flags LoadSources m2
                in
                    ({m3|loading = False}, Cmd.batch [c2,c3])
            else
                ({model | formError = Just res.message, loading = False }, Cmd.none)

        SubmitResp (Err err) ->
            ({model | formError = Just (Util.Http.errorToString err), loading = False}, Cmd.none)

        RequestDelete ->
            update flags (YesNoMsg Comp.YesNoDimmer.activate) model

        YesNoMsg m ->
            let
                (cm, confirmed) = Comp.YesNoDimmer.update m model.deleteConfirm
                src = Comp.SourceForm.getSource model.formModel
                cmd = if confirmed then Api.deleteSource flags src.id SubmitResp else Cmd.none
            in
                ({model | deleteConfirm = cm}, cmd)

view: Flags -> Model -> Html Msg
view flags model =
    if model.viewMode == Table then viewTable model
    else div [](viewForm flags model)

viewTable: Model -> Html Msg
viewTable model =
    div []
        [button [class "ui basic button", onClick InitNewSource]
             [i [class "plus icon"][]
             ,text "Create new"
             ]
        ,Html.map TableMsg (Comp.SourceTable.view model.tableModel)
        ,div [classList [("ui dimmer", True)
                        ,("active", model.loading)
                        ]]
            [div [class "ui loader"][]
            ]
        ]

viewForm: Flags -> Model -> List (Html Msg)
viewForm flags model =
    let
        newSource = model.formModel.source.id == ""
    in
        [if newSource then
                 h3 [class "ui top attached header"]
                    [text "Create new source"
                    ]
             else
                 h3 [class "ui top attached header"]
                    [text ("Edit: " ++ model.formModel.source.abbrev)
                    ,div [class "sub header"]
                         [text "Id: "
                         ,text model.formModel.source.id
                         ]
                    ]
        ,Html.form [class "ui attached segment", onSubmit Submit]
            [Html.map YesNoMsg (Comp.YesNoDimmer.view model.deleteConfirm)
            ,Html.map FormMsg (Comp.SourceForm.view flags model.formModel)
            ,div [classList [("ui error message", True)
                            ,("invisible", Util.Maybe.isEmpty model.formError)
                            ]
                 ]
                 [Maybe.withDefault "" model.formError |> text
                 ]
            ,div [class "ui horizontal divider"][]
            ,button [class "ui primary button", type_ "submit"]
                [text "Submit"
                ]
            ,a [class "ui secondary button", onClick (SetViewMode Table), href ""]
                [text "Cancel"
                ]
            ,if not newSource then
                 a [class "ui right floated red button", href "", onClick RequestDelete]
                     [text "Delete"]
             else
                 span[][]
            ,div [classList [("ui dimmer", True)
                            ,("active", model.loading)
                            ]]
                 [div [class "ui loader"][]
                 ]
            ]
        ]
