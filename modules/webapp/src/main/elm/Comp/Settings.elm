module Comp.Settings exposing
    ( Model
    , Msg
    , getSettings
    , init
    , update
    , view
    )

import Api.Model.CollectiveSettings exposing (CollectiveSettings)
import Comp.Dropdown
import Data.Flags exposing (Flags)
import Data.Language exposing (Language)
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model =
    { langModel : Comp.Dropdown.Model Language
    , initSettings : CollectiveSettings
    }


init : CollectiveSettings -> Model
init settings =
    let
        lang =
            Data.Language.fromString settings.language
                |> Maybe.withDefault Data.Language.German
    in
    { langModel =
        Comp.Dropdown.makeSingleList
            { makeOption =
                \l ->
                    { value = Data.Language.toIso3 l
                    , text = Data.Language.toName l
                    }
            , placeholder = ""
            , options = Data.Language.all
            , selected = Just lang
            }
    , initSettings = settings
    }


getSettings : Model -> CollectiveSettings
getSettings model =
    CollectiveSettings
        (Comp.Dropdown.getSelected model.langModel
            |> List.head
            |> Maybe.map Data.Language.toIso3
            |> Maybe.withDefault model.initSettings.language
        )


type Msg
    = LangDropdownMsg (Comp.Dropdown.Msg Language)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe CollectiveSettings )
update _ msg model =
    case msg of
        LangDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.langModel

                nextModel =
                    { model | langModel = m2 }

                nextSettings =
                    if Comp.Dropdown.isDropdownChangeMsg m then
                        Just (getSettings nextModel)

                    else
                        Nothing
            in
            ( nextModel, Cmd.map LangDropdownMsg c2, nextSettings )


view : Model -> Html Msg
view model =
    div [ class "ui form" ]
        [ div [ class "field" ]
            [ label [] [ text "Document Language" ]
            , Html.map LangDropdownMsg (Comp.Dropdown.view model.langModel)
            ]
        ]
