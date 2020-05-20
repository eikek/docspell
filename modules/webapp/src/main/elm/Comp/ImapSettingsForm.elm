module Comp.ImapSettingsForm exposing
    ( Model
    , Msg
    , emptyModel
    , getSettings
    , init
    , isValid
    , update
    , view
    )

import Api.Model.ImapSettings exposing (ImapSettings)
import Comp.Dropdown
import Comp.IntField
import Comp.PasswordInput
import Data.SSLType exposing (SSLType)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput)
import Util.Maybe


type alias Model =
    { settings : ImapSettings
    , name : String
    , host : String
    , portField : Comp.IntField.Model
    , portNum : Maybe Int
    , user : Maybe String
    , passField : Comp.PasswordInput.Model
    , password : Maybe String
    , sslType : Comp.Dropdown.Model SSLType
    , ignoreCertificates : Bool
    }


emptyModel : Model
emptyModel =
    { settings = Api.Model.ImapSettings.empty
    , name = ""
    , host = ""
    , portField = Comp.IntField.init (Just 0) Nothing True "IMAP Port"
    , portNum = Nothing
    , user = Nothing
    , passField = Comp.PasswordInput.init
    , password = Nothing
    , sslType =
        Comp.Dropdown.makeSingleList
            { makeOption = \s -> { value = Data.SSLType.toString s, text = Data.SSLType.label s }
            , placeholder = ""
            , options = Data.SSLType.all
            , selected = Just Data.SSLType.None
            }
    , ignoreCertificates = False
    }


init : ImapSettings -> Model
init ems =
    { settings = ems
    , name = ems.name
    , host = ems.imapHost
    , portField = Comp.IntField.init (Just 0) Nothing True "IMAP Port"
    , portNum = ems.imapPort
    , user = ems.imapUser
    , passField = Comp.PasswordInput.init
    , password = ems.imapPassword
    , sslType =
        Comp.Dropdown.makeSingleList
            { makeOption = \s -> { value = Data.SSLType.toString s, text = Data.SSLType.label s }
            , placeholder = ""
            , options = Data.SSLType.all
            , selected =
                Data.SSLType.fromString ems.sslType
                    |> Maybe.withDefault Data.SSLType.None
                    |> Just
            }
    , ignoreCertificates = ems.ignoreCertificates
    }


getSettings : Model -> ( Maybe String, ImapSettings )
getSettings model =
    ( Util.Maybe.fromString model.settings.name
    , { name = model.name
      , imapHost = model.host
      , imapUser = model.user
      , imapPort = model.portNum
      , imapPassword = model.password
      , sslType =
            Comp.Dropdown.getSelected model.sslType
                |> List.head
                |> Maybe.withDefault Data.SSLType.None
                |> Data.SSLType.toString
      , ignoreCertificates = model.ignoreCertificates
      }
    )


type Msg
    = SetName String
    | SetHost String
    | PortMsg Comp.IntField.Msg
    | SetUser String
    | PassMsg Comp.PasswordInput.Msg
    | SSLTypeMsg (Comp.Dropdown.Msg SSLType)
    | ToggleCheckCert


isValid : Model -> Bool
isValid model =
    model.host /= "" && model.name /= ""


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetName str ->
            ( { model | name = str }, Cmd.none )

        SetHost str ->
            ( { model | host = str }, Cmd.none )

        PortMsg m ->
            let
                ( pm, val ) =
                    Comp.IntField.update m model.portField
            in
            ( { model | portField = pm, portNum = val }, Cmd.none )

        SetUser str ->
            ( { model | user = Util.Maybe.fromString str }, Cmd.none )

        PassMsg m ->
            let
                ( pm, val ) =
                    Comp.PasswordInput.update m model.passField
            in
            ( { model | passField = pm, password = val }, Cmd.none )

        SSLTypeMsg m ->
            let
                ( sm, sc ) =
                    Comp.Dropdown.update m model.sslType
            in
            ( { model | sslType = sm }, Cmd.map SSLTypeMsg sc )

        ToggleCheckCert ->
            ( { model | ignoreCertificates = not model.ignoreCertificates }, Cmd.none )


view : Model -> Html Msg
view model =
    div
        [ classList
            [ ( "ui form", True )
            , ( "error", not (isValid model) )
            , ( "success", isValid model )
            ]
        ]
        [ div [ class "required field" ]
            [ label [] [ text "Name" ]
            , input
                [ type_ "text"
                , value model.name
                , onInput SetName
                , placeholder "Connection name, e.g. 'gmail.com'"
                ]
                []
            , div [ class "ui info message" ]
                [ text "The connection name must not contain whitespace or special characters."
                ]
            ]
        , div [ class "fields" ]
            [ div [ class "thirteen wide required field" ]
                [ label [] [ text "IMAP Host" ]
                , input
                    [ type_ "text"
                    , placeholder "IMAP host name, e.g. 'mail.gmail.com'"
                    , value model.host
                    , onInput SetHost
                    ]
                    []
                ]
            , Html.map PortMsg
                (Comp.IntField.view model.portNum
                    "three wide field"
                    model.portField
                )
            ]
        , div [ class "two fields" ]
            [ div [ class "field" ]
                [ label [] [ text "IMAP User" ]
                , input
                    [ type_ "text"
                    , placeholder "IMAP Username, e.g. 'your.name@gmail.com'"
                    , Maybe.withDefault "" model.user |> value
                    , onInput SetUser
                    ]
                    []
                ]
            , div [ class "field" ]
                [ label [] [ text "IMAP Password" ]
                , Html.map PassMsg (Comp.PasswordInput.view model.password model.passField)
                ]
            ]
        , div [ class "two fields" ]
            [ div [ class "inline field" ]
                [ div [ class "ui checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , checked model.ignoreCertificates
                        , onCheck (\_ -> ToggleCheckCert)
                        ]
                        []
                    , label [] [ text "Ignore certificate check" ]
                    ]
                ]
            ]
        , div [ class "two fields" ]
            [ div [ class "field" ]
                [ label [] [ text "SSL" ]
                , Html.map SSLTypeMsg (Comp.Dropdown.view model.sslType)
                ]
            ]
        ]
