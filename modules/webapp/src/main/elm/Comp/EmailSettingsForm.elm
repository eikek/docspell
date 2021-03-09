module Comp.EmailSettingsForm exposing
    ( Model
    , Msg
    , emptyModel
    , getSettings
    , init
    , isValid
    , update
    , view2
    )

import Api.Model.EmailSettings exposing (EmailSettings)
import Comp.Basic as B
import Comp.Dropdown
import Comp.IntField
import Comp.MenuBar as MB
import Comp.PasswordInput
import Data.DropdownStyle as DS
import Data.SSLType exposing (SSLType)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Styles as S
import Util.Maybe


type alias Model =
    { settings : EmailSettings
    , name : String
    , host : String
    , portField : Comp.IntField.Model
    , portNum : Maybe Int
    , user : Maybe String
    , passField : Comp.PasswordInput.Model
    , password : Maybe String
    , from : String
    , replyTo : Maybe String
    , sslType : Comp.Dropdown.Model SSLType
    , ignoreCertificates : Bool
    }


emptyModel : Model
emptyModel =
    { settings = Api.Model.EmailSettings.empty
    , name = ""
    , host = ""
    , portField = Comp.IntField.init (Just 0) Nothing True "SMTP Port"
    , portNum = Nothing
    , user = Nothing
    , passField = Comp.PasswordInput.init
    , password = Nothing
    , from = ""
    , replyTo = Nothing
    , sslType =
        Comp.Dropdown.makeSingleList
            { makeOption =
                \s ->
                    { value = Data.SSLType.toString s
                    , text = Data.SSLType.label s
                    , additional = ""
                    }
            , placeholder = ""
            , options = Data.SSLType.all
            , selected = Just Data.SSLType.None
            }
    , ignoreCertificates = False
    }


init : EmailSettings -> Model
init ems =
    { settings = ems
    , name = ems.name
    , host = ems.smtpHost
    , portField = Comp.IntField.init (Just 0) Nothing True "SMTP Port"
    , portNum = ems.smtpPort
    , user = ems.smtpUser
    , passField = Comp.PasswordInput.init
    , password = ems.smtpPassword
    , from = ems.from
    , replyTo = ems.replyTo
    , sslType =
        Comp.Dropdown.makeSingleList
            { makeOption =
                \s ->
                    { value = Data.SSLType.toString s
                    , text = Data.SSLType.label s
                    , additional = ""
                    }
            , placeholder = ""
            , options = Data.SSLType.all
            , selected =
                Data.SSLType.fromString ems.sslType
                    |> Maybe.withDefault Data.SSLType.None
                    |> Just
            }
    , ignoreCertificates = ems.ignoreCertificates
    }


getSettings : Model -> ( Maybe String, EmailSettings )
getSettings model =
    ( Util.Maybe.fromString model.settings.name
    , { name = model.name
      , smtpHost = model.host
      , smtpUser = model.user
      , smtpPort = model.portNum
      , smtpPassword = model.password
      , from = model.from
      , replyTo = model.replyTo
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
    | SetFrom String
    | SetReplyTo String
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

        SetFrom str ->
            ( { model | from = str }, Cmd.none )

        SetReplyTo str ->
            ( { model | replyTo = Util.Maybe.fromString str }, Cmd.none )

        ToggleCheckCert ->
            ( { model | ignoreCertificates = not model.ignoreCertificates }, Cmd.none )



--- View2


view2 : UiSettings -> Model -> Html Msg
view2 settings model =
    div [ class "grid grid-cols-4 gap-y-4 gap-x-2" ]
        [ div [ class "col-span-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text "Name"
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , value model.name
                , onInput SetName
                , placeholder "Connection name, e.g. 'gmail.com'"
                , class S.textInput
                , classList [ ( S.inputErrorBorder, model.name == "" ) ]
                ]
                []
            , div
                [ class S.message
                , class "mt-2"
                ]
                [ text "The connection name must not contain whitespace or special characters."
                ]
            ]
        , div [ class "col-span-3" ]
            [ label [ class S.inputLabel ]
                [ text "SMTP Host"
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , placeholder "SMTP host name, e.g. 'mail.gmail.com'"
                , value model.host
                , onInput SetHost
                , class S.textInput
                , classList [ ( S.inputErrorBorder, model.host == "" ) ]
                ]
                []
            ]
        , Html.map PortMsg
            (Comp.IntField.viewWithInfo2 ""
                model.portNum
                ""
                model.portField
            )
        , div [ class "col-span-4 sm:col-span-2" ]
            [ label
                [ class S.inputLabel
                ]
                [ text "SMTP User"
                ]
            , input
                [ type_ "text"
                , placeholder "SMTP Username, e.g. 'your.name@gmail.com'"
                , Maybe.withDefault "" model.user |> value
                , onInput SetUser
                , class S.textInput
                ]
                []
            ]
        , div [ class "col-span-4 sm:col-span-2" ]
            [ label [ class S.inputLabel ]
                [ text "SMTP Password"
                ]
            , Html.map PassMsg
                (Comp.PasswordInput.view2
                    model.password
                    False
                    model.passField
                )
            ]
        , div [ class "col-span-4 sm:col-span-2" ]
            [ label [ class S.inputLabel ]
                [ text "From Address"
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , placeholder "Sender E-Mail address"
                , value model.from
                , onInput SetFrom
                , class S.textInput
                , classList [ ( S.inputErrorBorder, model.from == "" ) ]
                ]
                []
            ]
        , div [ class "col-span-4 sm:col-span-2" ]
            [ label [ class S.inputLabel ]
                [ text "Reply-To"
                ]
            , input
                [ type_ "text"
                , placeholder "Optional reply-to E-Mail address"
                , Maybe.withDefault "" model.replyTo |> value
                , onInput SetReplyTo
                , class S.textInput
                ]
                []
            ]
        , div [ class "col-span-4 sm:col-span-2" ]
            [ label [ class S.inputLabel ]
                [ text "SSL"
                ]
            , Html.map SSLTypeMsg
                (Comp.Dropdown.view2
                    DS.mainStyle
                    settings
                    model.sslType
                )
            ]
        , div [ class "col-span-4 sm:col-span-2 flex items-center" ]
            [ MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleCheckCert
                    , label = "Ignore certificate check"
                    , value = model.ignoreCertificates
                    , id = "smpt-no-cert-check"
                    }
            ]
        ]
