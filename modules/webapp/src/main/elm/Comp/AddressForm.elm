{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
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
    [ Country "AF" "Afghanistan"
      , Country "AX" "Åland Islands"
      , Country "AL" "Albania"
      , Country "DZ" "Algeria"
      , Country "AS" "American Samoa"
      , Country "AD" "Andorra"
      , Country "AO" "Angola"
      , Country "AI" "Anguilla"
      , Country "AQ" "Antarctica"
      , Country "AG" "Antigua and Barbuda"
      , Country "AR" "Argentina"
      , Country "AM" "Armenia"
      , Country "AW" "Aruba"
      , Country "AU" "Australia"
      , Country "AT" "Austria"
      , Country "AZ" "Azerbaijan"
      , Country "BH" "Bahrain"
      , Country "BS" "Bahamas"
      , Country "BD" "Bangladesh"
      , Country "BB" "Barbados"
      , Country "BY" "Belarus"
      , Country "BE" "Belgium"
      , Country "BZ" "Belize"
      , Country "BJ" "Benin"
      , Country "BM" "Bermuda"
      , Country "BT" "Bhutan"
      , Country "BO" "Bolivia, Plurinational State of"
      , Country "BQ" "Bonaire, Sint Eustatius and Saba"
      , Country "BA" "Bosnia and Herzegovina"
      , Country "BW" "Botswana"
      , Country "BV" "Bouvet Island"
      , Country "BR" "Brazil"
      , Country "IO" "British Indian Ocean Territory"
      , Country "BN" "Brunei Darussalam"
      , Country "BG" "Bulgaria"
      , Country "BF" "Burkina Faso"
      , Country "BI" "Burundi"
      , Country "KH" "Cambodia"
      , Country "CM" "Cameroon"
      , Country "CA" "Canada"
      , Country "CV" "Cape Verde"
      , Country "KY" "Cayman Islands"
      , Country "CF" "Central African Republic"
      , Country "TD" "Chad"
      , Country "CL" "Chile"
      , Country "CN" "China"
      , Country "CX" "Christmas Island"
      , Country "CC" "Cocos (Keeling) Islands"
      , Country "CO" "Colombia"
      , Country "KM" "Comoros"
      , Country "CG" "Congo"
      , Country "CD" "Congo, the Democratic Republic of the"
      , Country "CK" "Cook Islands"
      , Country "CR" "Costa Rica"
      , Country "CI" "Côte d’Ivoire"
      , Country "HR" "Croatia"
      , Country "CU" "Cuba"
      , Country "CW" "Curaçao"
      , Country "CY" "Cyprus"
      , Country "CZ" "Czech Republic"
      , Country "DK" "Denmark"
      , Country "DJ" "Djibouti"
      , Country "DM" "Dominica"
      , Country "DO" "Dominican Republic"
      , Country "EC" "Ecuador"
      , Country "EG" "Egypt"
      , Country "SV" "El Salvador"
      , Country "GQ" "Equatorial Guinea"
      , Country "ER" "Eritrea"
      , Country "EE" "Estonia"
      , Country "ET" "Ethiopia"
      , Country "FK" "Falkland Islands (Malvinas)"
      , Country "FO" "Faroe Islands"
      , Country "FJ" "Fiji"
      , Country "FI" "Finland"
      , Country "FR" "France"
      , Country "GF" "French Guiana"
      , Country "PF" "French Polynesia"
      , Country "TF" "French Southern Territories"
      , Country "GA" "Gabon"
      , Country "GM" "Gambia"
      , Country "GE" "Georgia"
      , Country "DE" "Germany"
      , Country "GH" "Ghana"
      , Country "GI" "Gibraltar"
      , Country "GR" "Greece"
      , Country "GL" "Greenland"
      , Country "GD" "Grenada"
      , Country "GP" "Guadeloupe"
      , Country "GU" "Guam"
      , Country "GT" "Guatemala"
      , Country "GG" "Guernsey"
      , Country "GN" "Guinea"
      , Country "GW" "Guinea-Bissau"
      , Country "GY" "Guyana"
      , Country "HT" "Haiti"
      , Country "HM" "Heard Island and McDonald Islands"
      , Country "VA" "Holy See (Vatican City State)"
      , Country "HN" "Honduras"
      , Country "HK" "Hong Kong"
      , Country "HU" "Hungary"
      , Country "IS" "Iceland"
      , Country "IN" "India"
      , Country "ID" "Indonesia"
      , Country "IR" "Iran, Islamic Republic of"
      , Country "IQ" "Iraq"
      , Country "IE" "Ireland"
      , Country "IM" "Isle of Man"
      , Country "IL" "Israel"
      , Country "IT" "Italy"
      , Country "JM" "Jamaica"
      , Country "JP" "Japan"
      , Country "JE" "Jersey"
      , Country "JO" "Jordan"
      , Country "KZ" "Kazakhstan"
      , Country "KE" "Kenya"
      , Country "KI" "Kiribati"
      , Country "KP" "Korea, Democratic People’s Republic of"
      , Country "KR" "Korea, Republic of"
      , Country "KW" "Kuwait"
      , Country "KG" "Kyrgyzstan"
      , Country "LA" "Lao People’s Democratic Republic"
      , Country "LV" "Latvia"
      , Country "LB" "Lebanon"
      , Country "LS" "Lesotho"
      , Country "LR" "Liberia"
      , Country "LY" "Libya"
      , Country "LI" "Liechtenstein"
      , Country "LT" "Lithuania"
      , Country "LU" "Luxembourg"
      , Country "MO" "Macao"
      , Country "MK" "Macedonia, the Former Yugoslav Republic of"
      , Country "MG" "Madagascar"
      , Country "MW" "Malawi"
      , Country "MY" "Malaysia"
      , Country "MV" "Maldives"
      , Country "ML" "Mali"
      , Country "MT" "Malta"
      , Country "MH" "Marshall Islands"
      , Country "MQ" "Martinique"
      , Country "MR" "Mauritania"
      , Country "MU" "Mauritius"
      , Country "YT" "Mayotte"
      , Country "MX" "Mexico"
      , Country "FM" "Micronesia, Federated States of"
      , Country "MD" "Moldova, Republic of"
      , Country "MC" "Monaco"
      , Country "MN" "Mongolia"
      , Country "ME" "Montenegro"
      , Country "MS" "Montserrat"
      , Country "MA" "Morocco"
      , Country "MZ" "Mozambique"
      , Country "MM" "Myanmar"
      , Country "NA" "Namibia"
      , Country "NR" "Nauru"
      , Country "NP" "Nepal"
      , Country "NL" "Netherlands"
      , Country "NC" "New Caledonia"
      , Country "NZ" "New Zealand"
      , Country "NI" "Nicaragua"
      , Country "NE" "Niger"
      , Country "NG" "Nigeria"
      , Country "NU" "Niue"
      , Country "NF" "Norfolk Island"
      , Country "MP" "Northern Mariana Islands"
      , Country "NO" "Norway"
      , Country "OM" "Oman"
      , Country "PK" "Pakistan"
      , Country "PW" "Palau"
      , Country "PS" "Palestine, State of"
      , Country "PA" "Panama"
      , Country "PG" "Papua New Guinea"
      , Country "PY" "Paraguay"
      , Country "PE" "Peru"
      , Country "PH" "Philippines"
      , Country "PN" "Pitcairn"
      , Country "PL" "Poland"
      , Country "PT" "Portugal"
      , Country "PR" "Puerto Rico"
      , Country "QA" "Qatar"
      , Country "RE" "Réunion"
      , Country "RO" "Romania"
      , Country "RU" "Russian Federation"
      , Country "RW" "Rwanda"
      , Country "BL" "Saint Barthélemy"
      , Country "SH" "Saint Helena, Ascension and Tristan da Cunha"
      , Country "KN" "Saint Kitts and Nevis"
      , Country "LC" "Saint Lucia"
      , Country "MF" "Saint Martin (French part)"
      , Country "PM" "Saint Pierre and Miquelon"
      , Country "VC" "Saint Vincent and the Grenadines"
      , Country "WS" "Samoa"
      , Country "SM" "San Marino"
      , Country "ST" "Sao Tome and Principe"
      , Country "SA" "Saudi Arabia"
      , Country "SN" "Senegal"
      , Country "RS" "Serbia"
      , Country "SC" "Seychelles"
      , Country "SL" "Sierra Leone"
      , Country "SG" "Singapore"
      , Country "SX" "Sint Maarten (Dutch part)"
      , Country "SK" "Slovakia"
      , Country "SI" "Slovenia"
      , Country "SB" "Solomon Islands"
      , Country "SO" "Somalia"
      , Country "ZA" "South Africa"
      , Country "GS" "South Georgia and the South Sandwich Islands"
      , Country "SS" "South Sudan"
      , Country "ES" "Spain"
      , Country "LK" "Sri Lanka"
      , Country "SD" "Sudan"
      , Country "SR" "Suriname"
      , Country "SJ" "Svalbard and Jan Mayen"
      , Country "SZ" "Swaziland"
      , Country "SE" "Sweden"
      , Country "CH" "Switzerland"
      , Country "SY" "Syrian Arab Republic"
      , Country "TW" "Taiwan, Province of China"
      , Country "TJ" "Tajikistan"
      , Country "TZ" "Tanzania, United Republic of"
      , Country "TH" "Thailand"
      , Country "TL" "Timor-Leste"
      , Country "TG" "Togo"
      , Country "TK" "Tokelau"
      , Country "TO" "Tonga"
      , Country "TT" "Trinidad and Tobago"
      , Country "TN" "Tunisia"
      , Country "TR" "Turkey"
      , Country "TM" "Turkmenistan"
      , Country "TC" "Turks and Caicos Islands"
      , Country "TV" "Tuvalu"
      , Country "UG" "Uganda"
      , Country "UA" "Ukraine"
      , Country "AE" "United Arab Emirates"
      , Country "GB" "United Kingdom"
      , Country "US" "United States"
      , Country "UM" "United States Minor Outlying Islands"
      , Country "UY" "Uruguay"
      , Country "UZ" "Uzbekistan"
      , Country "VU" "Vanuatu"
      , Country "VE" "Venezuela, Bolivarian Republic of"
      , Country "VN" "Viet Nam"
      , Country "VG" "Virgin Islands, British"
      , Country "VI" "Virgin Islands, U.S."
      , Country "WF" "Wallis and Futuna"
      , Country "EH" "Western Sahara"
      , Country "YE" "Yemen"
      , Country "ZM" "Zambia"
      , Country "ZW" "Zimbabwe"
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
