module Comp.AddressForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getAddress
    , update
    , view
    )

import Api.Model.Address exposing (Address)
import Comp.Dropdown
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
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
            { makeOption = \c -> { value = c.code, text = c.label }
            , placeholder = "Select Country"
            , options = countries
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


view : Model -> Html Msg
view model =
    div [ class "ui form" ]
        [ div
            [ class "field"
            ]
            [ label [] [ text "Street" ]
            , input
                [ type_ "text"
                , onInput SetStreet
                , placeholder "Street"
                , value model.street
                ]
                []
            ]
        , div
            [ class "field"
            ]
            [ label [] [ text "Zip Code" ]
            , input
                [ type_ "text"
                , onInput SetZip
                , placeholder "Zip"
                , value model.zip
                ]
                []
            ]
        , div
            [ class "field"
            ]
            [ label [] [ text "City" ]
            , input
                [ type_ "text"
                , onInput SetCity
                , placeholder "City"
                , value model.city
                ]
                []
            ]
        , div [ class "field" ]
            [ label [] [ text "Country" ]
            , Html.map CountryMsg (Comp.Dropdown.view model.country)
            ]
        ]
