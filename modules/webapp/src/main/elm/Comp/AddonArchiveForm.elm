{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.AddonArchiveForm exposing (Model, Msg, get, init, initWith, update, view)

import Api.Model.Addon exposing (Addon)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.Comp.AddonArchiveForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { addon : Addon
    , url : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    ( { addon = Api.Model.Addon.empty
      , url = Nothing
      }
    , Cmd.none
    )


initWith : Addon -> ( Model, Cmd Msg )
initWith a =
    ( { addon = a
      , url = a.url
      }
    , Cmd.none
    )


isValid : Model -> Bool
isValid model =
    model.url /= Nothing


get : Model -> Maybe Addon
get model =
    let
        a =
            model.addon
    in
    if isValid model then
        Just
            { a
                | url = model.url
            }

    else
        Nothing


type Msg
    = SetUrl String


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetUrl url ->
            ( { model | url = Util.Maybe.fromString url }, Cmd.none )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div
        [ class "flex flex-col" ]
        [ div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text texts.addonUrl
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , placeholder texts.addonUrlPlaceholder
                , class S.textInput
                , classList [ ( "disabled", model.addon.id /= "" ) ]
                , value (model.url |> Maybe.withDefault "")
                , onInput SetUrl
                , disabled (model.addon.id /= "")
                ]
                []
            , span [ class "text-sm opacity-75" ]
                [ text texts.installInfoText
                ]
            ]
        ]
