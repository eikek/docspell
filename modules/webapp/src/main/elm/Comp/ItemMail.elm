module Comp.ItemMail exposing
    ( FormAction(..)
    , Model
    , Msg
    , clear
    , emptyModel
    , init
    , update
    , view2
    )

import Api
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Api.Model.SimpleMail exposing (SimpleMail)
import Comp.Basic as B
import Comp.Dropdown
import Comp.EmailInput
import Comp.MenuBar as MB
import Data.DropdownStyle
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Styles as S
import Util.Http


type alias Model =
    { connectionModel : Comp.Dropdown.Model String
    , subject : String
    , recipients : List String
    , recipientsModel : Comp.EmailInput.Model
    , ccRecipients : List String
    , ccRecipientsModel : Comp.EmailInput.Model
    , bccRecipients : List String
    , bccRecipientsModel : Comp.EmailInput.Model
    , body : String
    , attachAll : Bool
    , formError : Maybe String
    }


type Msg
    = SetSubject String
    | RecipientMsg Comp.EmailInput.Msg
    | CCRecipientMsg Comp.EmailInput.Msg
    | BCCRecipientMsg Comp.EmailInput.Msg
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
            { makeOption = \a -> { value = a, text = a, additional = "" }
            , placeholder = "Select connection..."
            }
    , subject = ""
    , recipients = []
    , recipientsModel = Comp.EmailInput.init
    , ccRecipients = []
    , ccRecipientsModel = Comp.EmailInput.init
    , bccRecipients = []
    , bccRecipientsModel = Comp.EmailInput.init
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
        , ccRecipients = []
        , bccRecipients = []
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

        CCRecipientMsg m ->
            let
                ( em, ec, rec ) =
                    Comp.EmailInput.update flags model.ccRecipients m model.ccRecipientsModel
            in
            ( { model | ccRecipients = rec, ccRecipientsModel = em }
            , Cmd.map CCRecipientMsg ec
            , FormNone
            )

        BCCRecipientMsg m ->
            let
                ( em, ec, rec ) =
                    Comp.EmailInput.update flags model.bccRecipients m model.bccRecipientsModel
            in
            ( { model | bccRecipients = rec, bccRecipientsModel = em }
            , Cmd.map BCCRecipientMsg ec
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
                        { makeOption = \a -> { value = a, text = a, additional = "" }
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
                        emptyMail =
                            Api.Model.SimpleMail.empty

                        sm =
                            { emptyMail
                                | recipients = model.recipients
                                , cc = model.ccRecipients
                                , bcc = model.bccRecipients
                                , subject = model.subject
                                , body = model.body
                                , addAllAttachments = model.attachAll
                            }
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



--- View2


view2 : UiSettings -> Model -> Html Msg
view2 settings model =
    let
        dds =
            Data.DropdownStyle.mainStyle
    in
    div
        [ class "flex flex-col"
        ]
        [ div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text "Send via"
                , B.inputRequired
                ]
            , Html.map ConnMsg (Comp.Dropdown.view2 dds settings model.connectionModel)
            ]
        , div
            [ class S.errorMessage
            , classList [ ( "hidden", model.formError == Nothing ) ]
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text "Recipient(s)"
                , B.inputRequired
                ]
            , Html.map RecipientMsg
                (Comp.EmailInput.view2 dds model.recipients model.recipientsModel)
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text "CC(s)"
                ]
            , Html.map CCRecipientMsg
                (Comp.EmailInput.view2 dds model.ccRecipients model.ccRecipientsModel)
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text "BCC(s)"
                ]
            , Html.map BCCRecipientMsg
                (Comp.EmailInput.view2 dds model.bccRecipients model.bccRecipientsModel)
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text "Subject"
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , class S.textInput
                , onInput SetSubject
                , value model.subject
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text "Body"
                , B.inputRequired
                ]
            , textarea
                [ onInput SetBody
                , value model.body
                , class S.textAreaInput
                ]
                []
            ]
        , MB.viewItem <|
            MB.Checkbox
                { tagger = \_ -> ToggleAttachAll
                , label = "Include all item attachments"
                , value = model.attachAll
                , id = "item-send-mail-attach-all"
                }
        , div [ class "flex flex-row space-x-2" ]
            [ B.primaryButton
                { label = "Send"
                , icon = "fa fa-paper-plane font-thin"
                , handler = onClick Send
                , attrs = [ href "#" ]
                , disabled = not (isValid model)
                }
            , B.secondaryButton
                { label = "Cancel"
                , icon = "fa fa-times"
                , handler = onClick Cancel
                , attrs = [ href "#" ]
                , disabled = False
                }
            ]
        ]
