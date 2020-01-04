module Comp.EmailSettingsManage exposing
    ( Model
    , Msg
    , emptyModel
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.EmailSettings exposing (EmailSettings)
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Comp.EmailSettingsForm
import Comp.EmailSettingsTable
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model =
    { tableModel : Comp.EmailSettingsTable.Model
    , formModel : Comp.EmailSettingsForm.Model
    , viewMode : ViewMode
    , formError : Maybe String
    , loading : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    }


emptyModel : Model
emptyModel =
    { tableModel = Comp.EmailSettingsTable.emptyModel
    , formModel = Comp.EmailSettingsForm.emptyModel
    , viewMode = Table
    , formError = Nothing
    , loading = False
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    }


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )


type ViewMode
    = Table
    | Form


type Msg
    = TableMsg Comp.EmailSettingsTable.Msg
    | FormMsg Comp.EmailSettingsForm.Msg


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    case model.viewMode of
        Table ->
            Html.map TableMsg (Comp.EmailSettingsTable.view model.tableModel)

        Form ->
            Html.map FormMsg (Comp.EmailSettingsForm.view model.formModel)
