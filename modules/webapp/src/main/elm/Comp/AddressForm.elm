{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Comp.AddressForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getAddress
    , update
    , view2
    )

import Api.Model.Address exposing (Address)
import Comp.Dropdown
import Data.DropdownStyle as DS
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.Comp.AddressForm exposing (Texts)
import Styles as S
import Util.List


type alias Model =
    { address : Address
    , street : String
    , zip : String
    , city : String
    , country : Comp.Dropdown.Model Country
    }


type alias Country =
    { code : String
    , label : String
    }


countries : List Country
countries =
    [ Country "DE" "Germany"
    , Country "CH" "Switzerland"
    , Country "GB" "Great Britain"
    , Country "ES" "Spain"
    , Country "AU" "Austria"
    ]


emptyModel : Model
emptyModel =
    { address = Api.Model.Address.empty
    , street = ""
    , zip = ""
    , city = ""
    , country =
        Comp.Dropdown.makeSingleList
            { options = countries
            , selected = Nothing
            }
    }


getAddress : Model -> Address
getAddress model =
    { street = model.street
    , zip = model.zip
    , city = model.city
    , country = Comp.Dropdown.getSelected model.country |> List.head |> Maybe.map .code |> Maybe.withDefault ""
    }


type Msg
    = SetStreet String
    | SetCity String
    | SetZip String
    | SetAddress Address
    | CountryMsg (Comp.Dropdown.Msg Country)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetAddress a ->
            let
                selection =
                    Util.List.find (\c -> c.code == a.country) countries
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                ( m2, c2 ) =
                    Comp.Dropdown.update (Comp.Dropdown.SetSelection selection) model.country
            in
            ( { model | address = a, street = a.street, city = a.city, zip = a.zip, country = m2 }, Cmd.map CountryMsg c2 )

        SetStreet n ->
            ( { model | street = n }, Cmd.none )

        SetCity c ->
            ( { model | city = c }, Cmd.none )

        SetZip z ->
            ( { model | zip = z }, Cmd.none )

        CountryMsg m ->
            let
                ( m1, c1 ) =
                    Comp.Dropdown.update m model.country
            in
            ( { model | country = m1 }, Cmd.map CountryMsg c1 )



--- View2


view2 : Texts -> UiSettings -> Model -> Html Msg
view2 texts settings model =
    let
        countryCfg =
            { makeOption = \c -> { text = c.label, additional = "" }
            , placeholder = texts.selectCountry
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }
    in
    div [ class "flex flex-col" ]
        [ div
            [ class "mb-2"
            ]
            [ label
                [ for "street"
                , class S.inputLabel
                ]
                [ text texts.street
                ]
            , input
                [ type_ "text"
                , onInput SetStreet
                , placeholder texts.street
                , value model.street
                , name "street"
                , class S.textInput
                ]
                []
            ]
        , div
            [ class "mb-2"
            ]
            [ label
                [ for "zip"
                , class S.inputLabel
                ]
                [ text texts.zipCode
                ]
            , input
                [ type_ "text"
                , onInput SetZip
                , placeholder texts.zipCode
                , value model.zip
                , name "zip"
                , class S.textInput
                ]
                []
            ]
        , div
            [ class "mb-2"
            ]
            [ label
                [ for "city"
                , class S.inputLabel
                ]
                [ text texts.city
                ]
            , input
                [ type_ "text"
                , onInput SetCity
                , placeholder texts.city
                , value model.city
                , name "city"
                , class S.textInput
                ]
                []
            ]
        , div [ class "" ]
            [ label [ class S.inputLabel ]
                [ text texts.country
                ]
            , Html.map CountryMsg
                (Comp.Dropdown.view2
                    countryCfg
                    settings
                    model.country
                )
            ]
        ]
