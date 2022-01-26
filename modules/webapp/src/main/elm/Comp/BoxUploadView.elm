module Comp.BoxUploadView exposing (..)

import Comp.UploadForm
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Messages.Comp.BoxUploadView exposing (Texts)


type alias Model =
    { uploadForm : Comp.UploadForm.Model
    , sourceId : Maybe String
    }


type Msg
    = UploadMsg Comp.UploadForm.Msg


init : Maybe String -> Model
init sourceId =
    { uploadForm = Comp.UploadForm.init
    , sourceId = sourceId
    }



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    case msg of
        UploadMsg lm ->
            let
                ( um, uc, us ) =
                    Comp.UploadForm.update model.sourceId flags lm model.uploadForm
            in
            ( { model | uploadForm = um }
            , Cmd.map UploadMsg uc
            , Sub.map UploadMsg us
            )



--- View


view : Texts -> Flags -> UiSettings -> Model -> Html Msg
view texts flags settings model =
    let
        viewCfg =
            { sourceId = model.sourceId
            , showForm = False
            , lightForm = True
            }
    in
    div [ class "" ]
        [ Html.map UploadMsg
            (Comp.UploadForm.view texts.uploadForm viewCfg flags settings model.uploadForm)
        ]
