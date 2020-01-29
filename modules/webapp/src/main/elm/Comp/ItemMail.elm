module Comp.ItemMail exposing
    ( FormAction(..)
    , Model
    , Msg
    , clear
    , emptyModel
    , init
    , update
    , view
    )

import Api
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Api.Model.SimpleMail exposing (SimpleMail)
import Comp.Dropdown
import Comp.EmailInput
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Util.Http


type alias Model =
    { connectionModel : Comp.Dropdown.Model String
    , subject : String
    , recipients : List String
    , recipientsModel : Comp.EmailInput.Model
    , body : String
    , attachAll : Bool
    , formError : Maybe String
    }


type Msg
    = SetSubject String
    | RecipientMsg Comp.EmailInput.Msg
    | SetBody String
    | ConnMsg (Comp.Dropdown.Msg String)
    | ConnResp (Result Http.Error EmailSettingsList)
    | ToggleAttachAll
    | Cancel
    | Send


type alias MailInfo =
    { conn : String
    , mail : SimpleMail
    }


type FormAction
    = FormSend MailInfo
    | FormCancel
    | FormNone


emptyModel : Model
emptyModel =
    { connectionModel =
        Comp.Dropdown.makeSingle
            { makeOption = \a -> { value = a, text = a }
            , placeholder = "Select connection..."
            }
    , subject = ""
    , recipients = []
    , recipientsModel = Comp.EmailInput.init
    , body = ""
    , attachAll = True
    , formError = Nothing
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel, Api.getMailSettings flags "" ConnResp )


clear : Model -> Model
clear model =
    { model
        | subject = ""
        , recipients = []
        , body = ""
    }


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, FormAction )
update flags msg model =
    case msg of
        SetSubject str ->
            ( { model | subject = str }, Cmd.none, FormNone )

        RecipientMsg m ->
            let
                ( em, ec, rec ) =
                    Comp.EmailInput.update flags model.recipients m model.recipientsModel
            in
            ( { model | recipients = rec, recipientsModel = em }
            , Cmd.map RecipientMsg ec
            , FormNone
            )

        SetBody str ->
            ( { model | body = str }, Cmd.none, FormNone )

        ConnMsg m ->
            let
                ( cm, _ ) =
                    -- dropdown doesn't use cmd!!
                    Comp.Dropdown.update m model.connectionModel
            in
            ( { model | connectionModel = cm }, Cmd.none, FormNone )

        ToggleAttachAll ->
            ( { model | attachAll = not model.attachAll }, Cmd.none, FormNone )

        ConnResp (Ok list) ->
            let
                names =
                    List.map .name list.items

                cm =
                    Comp.Dropdown.makeSingleList
                        { makeOption = \a -> { value = a, text = a }
                        , placeholder = "Select Connection..."
                        , options = names
                        , selected = List.head names
                        }
            in
            ( { model
                | connectionModel = cm
                , formError =
                    if names == [] then
                        Just "No E-Mail connections configured. Goto user settings to add one."

                    else
                        Nothing
              }
            , Cmd.none
            , FormNone
            )

        ConnResp (Err err) ->
            ( { model | formError = Just (Util.Http.errorToString err) }, Cmd.none, FormNone )

        Cancel ->
            ( model, Cmd.none, FormCancel )

        Send ->
            case ( model.formError, Comp.Dropdown.getSelected model.connectionModel ) of
                ( Nothing, conn :: [] ) ->
                    let
                        sm =
                            SimpleMail model.recipients model.subject model.body model.attachAll []
                    in
                    ( model, Cmd.none, FormSend { conn = conn, mail = sm } )

                _ ->
                    ( model, Cmd.none, FormNone )


isValid : Model -> Bool
isValid model =
    model.recipients
        /= []
        && model.subject
        /= ""
        && model.body
        /= ""
        && model.formError
        == Nothing


view : Model -> Html Msg
view model =
    div
        [ classList
            [ ( "ui form", True )
            , ( "error", model.formError /= Nothing )
            ]
        ]
        [ div [ class "field" ]
            [ label [] [ text "Send via" ]
            , Html.map ConnMsg (Comp.Dropdown.view model.connectionModel)
            ]
        , div [ class "ui error message" ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , div [ class "field" ]
            [ label []
                [ text "Recipient(s)"
                ]
            , Html.map RecipientMsg (Comp.EmailInput.view model.recipients model.recipientsModel)
            ]
        , div [ class "field" ]
            [ label [] [ text "Subject" ]
            , input
                [ type_ "text"
                , onInput SetSubject
                , value model.subject
                ]
                []
            ]
        , div [ class "field" ]
            [ label [] [ text "Body" ]
            , textarea
                [ onInput SetBody
                , value model.body
                ]
                []
            ]
        , div [ class "inline field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , checked model.attachAll
                    , onCheck (\_ -> ToggleAttachAll)
                    ]
                    []
                , label [] [ text "Include all item attachments" ]
                ]
            ]
        , button
            [ classList
                [ ( "ui primary button", True )
                , ( "disabled", not (isValid model) )
                ]
            , onClick Send
            ]
            [ text "Send"
            ]
        , button
            [ class "ui secondary button"
            , onClick Cancel
            ]
            [ text "Cancel"
            ]
        ]
