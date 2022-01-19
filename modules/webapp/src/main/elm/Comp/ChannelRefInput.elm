{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ChannelRefInput exposing (Model, Msg, getSelected, init, initSelected, initWith, setOptions, setSelected, update, view)

import Api
import Api.Model.NotificationChannelRef exposing (NotificationChannelRef)
import Comp.Dropdown exposing (Option)
import Data.ChannelType
import Data.DropdownStyle
import Data.Flags exposing (Flags)
import Data.NotificationChannel
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html)
import Messages.Comp.ChannelRefInput exposing (Texts)
import Util.String


type alias Model =
    { ddm : Comp.Dropdown.Model NotificationChannelRef
    , all : List NotificationChannelRef
    }


type Msg
    = DropdownMsg (Comp.Dropdown.Msg NotificationChannelRef)
    | LoadChannelsResp (List NotificationChannelRef)


emptyModel : Model
emptyModel =
    { ddm = makeDropdownModel
    , all = []
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel, getOptions flags )


getOptions : Flags -> Cmd Msg
getOptions flags =
    Api.getChannelsIgnoreError flags (List.map Data.NotificationChannel.getRef >> LoadChannelsResp)


setOptions : List NotificationChannelRef -> Msg
setOptions refs =
    LoadChannelsResp refs


initSelected : Flags -> List NotificationChannelRef -> ( Model, Cmd Msg )
initSelected flags selected =
    ( update (setSelected selected) emptyModel
        |> Tuple.first
    , getOptions flags
    )


initWith : List NotificationChannelRef -> List NotificationChannelRef -> Model
initWith options selected =
    update (setSelected selected) emptyModel
        |> Tuple.first
        |> update (setOptions options)
        |> Tuple.first


getSelected : Model -> List NotificationChannelRef
getSelected model =
    Comp.Dropdown.getSelected model.ddm


setSelected : List NotificationChannelRef -> Msg
setSelected refs =
    DropdownMsg (Comp.Dropdown.SetSelection refs)



--- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DropdownMsg lm ->
            let
                ( dm, dc ) =
                    Comp.Dropdown.update lm model.ddm
            in
            ( { model | ddm = dm }
            , Cmd.map DropdownMsg dc
            )

        LoadChannelsResp refs ->
            let
                ( dm, dc ) =
                    Comp.Dropdown.update (Comp.Dropdown.SetOptions refs) model.ddm
            in
            ( { model
                | all = refs
                , ddm = dm
              }
            , Cmd.map DropdownMsg dc
            )



--- View


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        idShort id =
            String.slice 0 6 id

        joinName name ct =
            Option (ct ++ " (" ++ name ++ ")") ""

        mkName ref =
            Data.ChannelType.fromString ref.channelType
                |> Maybe.map texts.channelType
                |> Maybe.withDefault ref.channelType
                |> joinName (Maybe.withDefault (idShort ref.id) ref.name)

        viewCfg =
            { makeOption = mkName
            , placeholder = texts.placeholder
            , labelColor = \_ -> \_ -> ""
            , style = Data.DropdownStyle.mainStyle
            }
    in
    Html.map DropdownMsg
        (Comp.Dropdown.view2 viewCfg settings model.ddm)



--- Helpers


makeDropdownModel : Comp.Dropdown.Model NotificationChannelRef
makeDropdownModel =
    let
        m =
            Comp.Dropdown.makeModel
                { multiple = True
                , searchable = \n -> n > 0
                }
    in
    { m | searchWithAdditional = True }
