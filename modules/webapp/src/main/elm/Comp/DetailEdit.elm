{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.DetailEdit exposing
    ( Model
    , Msg
    , Value(..)
    , editEquip
    , editOrg
    , editPerson
    , formHeading
    , initConcPerson
    , initCorrPerson
    , initCustomField
    , initEquip
    , initOrg
    , initTag
    , initTagByName
    , update
    , view2
    , viewModal2
    )

{-| Module for allowing to edit metadata in the item-edit menu.

It is only possible to edit one thing at a time, suitable for being
rendered in a modal.

-}

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.Equipment exposing (Equipment)
import Api.Model.NewCustomField exposing (NewCustomField)
import Api.Model.Organization exposing (Organization)
import Api.Model.Person exposing (Person)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.Tag exposing (Tag)
import Comp.Basic as B
import Comp.CustomFieldForm
import Comp.EquipmentForm
import Comp.OrgForm
import Comp.PersonForm
import Comp.TagForm
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.DetailEdit exposing (Texts)
import Styles as S


type alias Model =
    { form : FormModel
    , itemId : String
    , submitting : Bool
    , loading : Bool
    , formState : FormState
    }


type FormState
    = FormStateInitial
    | FormStateHttpError Http.Error
    | FormStateSubmitSuccessful
    | FormStateSubmitError String
    | FormStateMissingRequiredFields


isError : FormState -> Bool
isError state =
    case state of
        FormStateInitial ->
            False

        FormStateHttpError _ ->
            True

        FormStateSubmitSuccessful ->
            False

        FormStateSubmitError _ ->
            True

        FormStateMissingRequiredFields ->
            True


isSuccess : FormState -> Bool
isSuccess state =
    case state of
        FormStateInitial ->
            False

        _ ->
            not (isError state)


type FormModel
    = TM Comp.TagForm.Model
    | PMR Comp.PersonForm.Model
    | PMC Comp.PersonForm.Model
    | OM Comp.OrgForm.Model
    | EM Comp.EquipmentForm.Model
    | CFM Comp.CustomFieldForm.Model


fold :
    (Comp.TagForm.Model -> a)
    -> (Comp.PersonForm.Model -> a)
    -> (Comp.OrgForm.Model -> a)
    -> (Comp.EquipmentForm.Model -> a)
    -> (Comp.CustomFieldForm.Model -> a)
    -> FormModel
    -> a
fold ft fp fo fe fcf model =
    case model of
        TM tm ->
            ft tm

        PMR pm ->
            fp pm

        PMC pm ->
            fp pm

        OM om ->
            fo om

        EM em ->
            fe em

        CFM fm ->
            fcf fm


init : String -> FormModel -> Model
init itemId fm =
    { form = fm
    , itemId = itemId
    , submitting = False
    , loading = False
    , formState = FormStateInitial
    }


initEquip : String -> Comp.EquipmentForm.Model -> Model
initEquip itemId em =
    init itemId (EM em)


initOrg : String -> Comp.OrgForm.Model -> Model
initOrg itemId om =
    init itemId (OM om)


editOrg : Flags -> String -> Comp.OrgForm.Model -> ( Model, Cmd Msg )
editOrg flags orgId om =
    ( { form = OM om
      , itemId = ""
      , submitting = False
      , loading = True
      , formState = FormStateInitial
      }
    , Api.getOrgFull orgId flags GetOrgResp
    )


editPerson : Flags -> String -> Comp.PersonForm.Model -> ( Model, Cmd Msg )
editPerson flags persId pm =
    ( { form = PMC pm
      , itemId = ""
      , submitting = False
      , loading = True
      , formState = FormStateInitial
      }
    , Cmd.batch
        [ Api.getPersonFull persId flags GetPersonResp
        , Api.getOrgLight flags GetOrgsResp
        ]
    )


editEquip : Flags -> String -> Comp.EquipmentForm.Model -> ( Model, Cmd Msg )
editEquip flags equipId em =
    ( { form = EM em
      , itemId = ""
      , submitting = False
      , loading = True
      , formState = FormStateInitial
      }
    , Api.getEquipment flags equipId GetEquipResp
    )


initCorrPerson : Flags -> String -> Comp.PersonForm.Model -> ( Model, Cmd Msg )
initCorrPerson flags itemId pm =
    ( init itemId (PMR pm)
    , Api.getOrgLight flags GetOrgsResp
    )


initConcPerson : Flags -> String -> Comp.PersonForm.Model -> ( Model, Cmd Msg )
initConcPerson flags itemId pm =
    ( init itemId (PMC pm)
    , Api.getOrgLight flags GetOrgsResp
    )


initTag : String -> Comp.TagForm.Model -> Model
initTag itemId tm =
    init itemId (TM tm)


initTagByName : String -> String -> List String -> Model
initTagByName itemId name categories =
    let
        tm =
            Comp.TagForm.emptyModel categories

        tm_ =
            { tm | name = name }
    in
    initTag itemId tm_


initCustomField : String -> Model
initCustomField itemId =
    let
        cfm =
            Comp.CustomFieldForm.initEmpty
    in
    init itemId (CFM cfm)


type Msg
    = TagMsg Comp.TagForm.Msg
    | PersonMsg Comp.PersonForm.Msg
    | OrgMsg Comp.OrgForm.Msg
    | EquipMsg Comp.EquipmentForm.Msg
    | CustomFieldMsg Comp.CustomFieldForm.Msg
    | Submit
    | Cancel
    | SubmitResp (Result Http.Error BasicResult)
    | GetOrgResp (Result Http.Error Organization)
    | GetPersonResp (Result Http.Error Person)
    | GetEquipResp (Result Http.Error Equipment)
    | GetOrgsResp (Result Http.Error ReferenceList)


type Value
    = SubmitTag Tag
    | SubmitPerson Person
    | SubmitOrg Organization
    | SubmitEquip Equipment
    | SubmitCustomField NewCustomField
    | CancelForm


makeValue : FormModel -> Value
makeValue fm =
    case fm of
        TM tm ->
            SubmitTag (Comp.TagForm.getTag tm)

        PMR pm ->
            SubmitPerson (Comp.PersonForm.getPerson pm)

        PMC pm ->
            SubmitPerson (Comp.PersonForm.getPerson pm)

        OM om ->
            SubmitOrg (Comp.OrgForm.getOrg om)

        EM em ->
            SubmitEquip (Comp.EquipmentForm.getEquipment em)

        CFM fieldModel ->
            let
                cfield =
                    Comp.CustomFieldForm.makeField fieldModel
            in
            case cfield of
                Ok field ->
                    SubmitCustomField field

                Err _ ->
                    CancelForm



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe Value )
update flags msg model =
    case msg of
        Cancel ->
            ( model, Cmd.none, Just CancelForm )

        GetOrgResp (Ok org) ->
            case model.form of
                OM om ->
                    let
                        ( om_, oc_ ) =
                            Comp.OrgForm.update flags (Comp.OrgForm.SetOrg org) om
                    in
                    ( { model
                        | loading = False
                        , form = OM om_
                      }
                    , Cmd.map OrgMsg oc_
                    , Nothing
                    )

                _ ->
                    ( { model | loading = False }
                    , Cmd.none
                    , Nothing
                    )

        GetOrgResp (Err err) ->
            ( { model
                | loading = False
                , formState = FormStateHttpError err
              }
            , Cmd.none
            , Nothing
            )

        GetPersonResp (Ok pers) ->
            case model.form of
                PMC pm ->
                    let
                        ( pm_, pc_ ) =
                            Comp.PersonForm.update flags (Comp.PersonForm.SetPerson pers) pm
                    in
                    ( { model
                        | loading = False
                        , form = PMC pm_
                      }
                    , Cmd.map PersonMsg pc_
                    , Nothing
                    )

                _ ->
                    ( { model | loading = False }
                    , Cmd.none
                    , Nothing
                    )

        GetPersonResp (Err err) ->
            ( { model
                | loading = False
                , formState = FormStateHttpError err
              }
            , Cmd.none
            , Nothing
            )

        GetOrgsResp (Ok list) ->
            case model.form of
                PMC pm ->
                    let
                        ( p_, c_ ) =
                            Comp.PersonForm.update flags (Comp.PersonForm.SetOrgs list.items) pm
                    in
                    ( { model
                        | loading = False
                        , form = PMC p_
                      }
                    , Cmd.map PersonMsg c_
                    , Nothing
                    )

                PMR pm ->
                    let
                        ( p_, c_ ) =
                            Comp.PersonForm.update flags (Comp.PersonForm.SetOrgs list.items) pm
                    in
                    ( { model
                        | loading = False
                        , form = PMR p_
                      }
                    , Cmd.map PersonMsg c_
                    , Nothing
                    )

                _ ->
                    ( { model | loading = False }, Cmd.none, Nothing )

        GetOrgsResp (Err err) ->
            ( { model
                | loading = False
                , formState = FormStateHttpError err
              }
            , Cmd.none
            , Nothing
            )

        GetEquipResp (Ok equip) ->
            case model.form of
                EM em ->
                    let
                        ( em_, ec_ ) =
                            Comp.EquipmentForm.update flags (Comp.EquipmentForm.SetEquipment equip) em
                    in
                    ( { model
                        | loading = False
                        , form = EM em_
                      }
                    , Cmd.map EquipMsg ec_
                    , Nothing
                    )

                _ ->
                    ( { model | loading = False }
                    , Cmd.none
                    , Nothing
                    )

        GetEquipResp (Err err) ->
            ( { model
                | loading = False
                , formState = FormStateHttpError err
              }
            , Cmd.none
            , Nothing
            )

        SubmitResp (Ok res) ->
            let
                ret =
                    if res.success then
                        Just (makeValue model.form)

                    else
                        Nothing
            in
            ( { model
                | formState =
                    if res.success then
                        FormStateSubmitSuccessful

                    else
                        FormStateSubmitError res.message
                , submitting = False
              }
            , Cmd.none
            , ret
            )

        SubmitResp (Err err) ->
            ( { model
                | formState = FormStateHttpError err
                , submitting = False
              }
            , Cmd.none
            , Nothing
            )

        Submit ->
            case model.form of
                TM tm ->
                    let
                        tag =
                            Comp.TagForm.getTag tm
                    in
                    if Comp.TagForm.isValid tm then
                        ( { model | submitting = True }
                        , Api.addTag flags model.itemId tag SubmitResp
                        , Nothing
                        )

                    else
                        ( { model | formState = FormStateMissingRequiredFields }
                        , Cmd.none
                        , Nothing
                        )

                OM om ->
                    let
                        org =
                            Comp.OrgForm.getOrg om
                    in
                    if Comp.OrgForm.isValid om then
                        ( { model | submitting = True }
                        , if model.itemId == "" then
                            Api.postOrg flags org SubmitResp

                          else
                            Api.addCorrOrg flags model.itemId org SubmitResp
                        , Nothing
                        )

                    else
                        ( { model | formState = FormStateMissingRequiredFields }
                        , Cmd.none
                        , Nothing
                        )

                PMC pm ->
                    let
                        pers =
                            Comp.PersonForm.getPerson pm
                    in
                    if Comp.PersonForm.isValid pm then
                        ( { model | submitting = True }
                        , if model.itemId == "" then
                            Api.postPerson flags pers SubmitResp

                          else
                            Api.addConcPerson flags model.itemId pers SubmitResp
                        , Nothing
                        )

                    else
                        ( { model | formState = FormStateMissingRequiredFields }
                        , Cmd.none
                        , Nothing
                        )

                PMR pm ->
                    let
                        pers =
                            Comp.PersonForm.getPerson pm
                    in
                    if Comp.PersonForm.isValid pm then
                        ( { model | submitting = True }
                        , if model.itemId == "" then
                            Api.postPerson flags pers SubmitResp

                          else
                            Api.addCorrPerson flags model.itemId pers SubmitResp
                        , Nothing
                        )

                    else
                        ( { model | formState = FormStateMissingRequiredFields }
                        , Cmd.none
                        , Nothing
                        )

                EM em ->
                    let
                        equip =
                            Comp.EquipmentForm.getEquipment em
                    in
                    if Comp.EquipmentForm.isValid em then
                        ( { model | submitting = True }
                        , if model.itemId == "" then
                            Api.postEquipment flags equip SubmitResp

                          else
                            Api.addConcEquip flags model.itemId equip SubmitResp
                        , Nothing
                        )

                    else
                        ( { model | formState = FormStateMissingRequiredFields }
                        , Cmd.none
                        , Nothing
                        )

                CFM fm ->
                    let
                        cfield =
                            Comp.CustomFieldForm.makeField fm
                    in
                    case cfield of
                        Ok newField ->
                            ( { model | submitting = True }
                            , Api.postCustomField flags newField SubmitResp
                            , Nothing
                            )

                        Err _ ->
                            ( { model | formState = FormStateMissingRequiredFields }
                            , Cmd.none
                            , Nothing
                            )

        TagMsg lm ->
            case model.form of
                TM tm ->
                    let
                        ( tm_, tc_ ) =
                            Comp.TagForm.update flags lm tm
                    in
                    ( { model
                        | form = TM tm_
                        , formState = FormStateInitial
                      }
                    , Cmd.map TagMsg tc_
                    , Nothing
                    )

                _ ->
                    ( model, Cmd.none, Nothing )

        PersonMsg lm ->
            case model.form of
                PMR pm ->
                    let
                        ( pm_, pc_ ) =
                            Comp.PersonForm.update flags lm pm
                    in
                    ( { model
                        | form = PMR pm_
                        , formState = FormStateInitial
                      }
                    , Cmd.map PersonMsg pc_
                    , Nothing
                    )

                PMC pm ->
                    let
                        ( pm_, pc_ ) =
                            Comp.PersonForm.update flags lm pm
                    in
                    ( { model
                        | form = PMC pm_
                        , formState = FormStateInitial
                      }
                    , Cmd.map PersonMsg pc_
                    , Nothing
                    )

                _ ->
                    ( model, Cmd.none, Nothing )

        OrgMsg lm ->
            case model.form of
                OM om ->
                    let
                        ( om_, oc_ ) =
                            Comp.OrgForm.update flags lm om
                    in
                    ( { model
                        | form = OM om_
                        , formState = FormStateInitial
                      }
                    , Cmd.map OrgMsg oc_
                    , Nothing
                    )

                _ ->
                    ( model, Cmd.none, Nothing )

        EquipMsg lm ->
            case model.form of
                EM em ->
                    let
                        ( em_, ec_ ) =
                            Comp.EquipmentForm.update flags lm em
                    in
                    ( { model
                        | form = EM em_
                        , formState = FormStateInitial
                      }
                    , Cmd.map EquipMsg ec_
                    , Nothing
                    )

                _ ->
                    ( model, Cmd.none, Nothing )

        CustomFieldMsg lm ->
            case model.form of
                CFM fm ->
                    let
                        ( fm_, fc_, _ ) =
                            Comp.CustomFieldForm.update flags lm fm
                    in
                    ( { model
                        | form = CFM fm_
                        , formState = FormStateInitial
                      }
                    , Cmd.map CustomFieldMsg fc_
                    , Nothing
                    )

                _ ->
                    ( model, Cmd.none, Nothing )



--- View2


view2 : Texts -> List (Attribute Msg) -> UiSettings -> Model -> Html Msg
view2 texts attr settings model =
    div attr
        (viewIntern2 texts settings True model)


formHeading : Texts -> String -> Model -> Html msg
formHeading texts classes model =
    let
        heading =
            fold (\_ -> texts.addTagHeader)
                (\_ -> texts.addPersonHeader)
                (\_ -> texts.addOrgHeader)
                (\_ -> texts.addEquipmentHeader)
                (\_ -> texts.addCustomFieldHeader)

        headIcon =
            fold (\_ -> Icons.tagIcon "mr-2")
                (\_ -> Icons.personIcon "mr-2")
                (\_ -> Icons.organizationIcon "mr-2")
                (\_ -> Icons.equipmentIcon "mt-2")
                (\_ -> Icons.customFieldIcon2 "mr-2")
    in
    div [ class classes ]
        [ headIcon model.form
        , text (heading model.form)
        ]


viewModal2 : Texts -> UiSettings -> Maybe Model -> Html Msg
viewModal2 texts settings mm =
    let
        hidden =
            mm == Nothing

        heading =
            fold (\_ -> texts.addTagHeader)
                (\_ -> texts.addPersonHeader)
                (\_ -> texts.addOrgHeader)
                (\_ -> texts.addEquipmentHeader)
                (\_ -> texts.addCustomFieldHeader)

        headIcon =
            fold (\_ -> Icons.tagIcon "mr-2")
                (\_ -> Icons.personIcon "mr-2")
                (\_ -> Icons.organizationIcon "mr-2")
                (\_ -> Icons.equipmentIcon "mt-2")
                (\_ -> Icons.customFieldIcon2 "mr-2")
    in
    div
        [ classList
            [ ( S.dimmer, True )
            , ( " hidden", hidden )
            ]
        , class "flex"
        ]
        [ div
            [ class ""
            ]
            [ div [ class S.header2 ]
                [ Maybe.map .form mm
                    |> Maybe.map headIcon
                    |> Maybe.withDefault (i [] [])
                , Maybe.map .form mm
                    |> Maybe.map heading
                    |> Maybe.withDefault ""
                    |> text
                ]
            , div [ class "scrolling content" ]
                (case mm of
                    Just model ->
                        viewIntern2 texts settings False model

                    Nothing ->
                        []
                )
            , div [ class "flex flex-row space-x-2" ]
                (case mm of
                    Just model ->
                        viewButtons2 texts model

                    Nothing ->
                        []
                )
            ]
        ]


viewButtons2 : Texts -> Model -> List (Html Msg)
viewButtons2 texts model =
    [ B.primaryButton
        { label = texts.basics.submit
        , icon =
            if model.submitting || model.loading then
                "fa fa-circle-notch animate-spin"

            else
                "fa fa-save"
        , disabled = model.submitting || model.loading
        , handler = onClick Submit
        , attrs = [ href "#" ]
        }
    , B.secondaryButton
        { label = texts.basics.cancel
        , handler = onClick Cancel
        , disabled = False
        , icon = "fa fa-times"
        , attrs = [ href "#" ]
        }
    ]


viewIntern2 : Texts -> UiSettings -> Bool -> Model -> List (Html Msg)
viewIntern2 texts settings withButtons model =
    [ div
        [ classList
            [ ( S.errorMessage, isError model.formState )
            , ( S.successMessage, isSuccess model.formState )
            , ( "hidden", model.formState == FormStateInitial )
            ]
        ]
        [ case model.formState of
            FormStateInitial ->
                text ""

            FormStateHttpError err ->
                text (texts.httpError err)

            FormStateSubmitSuccessful ->
                text texts.submitSuccessful

            FormStateSubmitError m ->
                text m

            FormStateMissingRequiredFields ->
                text texts.missingRequiredFields
        ]
    , case model.form of
        TM tm ->
            Html.map TagMsg (Comp.TagForm.view2 texts.tagForm settings tm)

        PMR pm ->
            Html.map PersonMsg (Comp.PersonForm.view2 texts.personForm True settings pm)

        PMC pm ->
            Html.map PersonMsg (Comp.PersonForm.view2 texts.personForm True settings pm)

        OM om ->
            Html.map OrgMsg (Comp.OrgForm.view2 texts.orgForm True settings om)

        EM em ->
            Html.map EquipMsg (Comp.EquipmentForm.view2 texts.equipmentForm em)

        CFM fm ->
            div []
                (List.map (Html.map CustomFieldMsg)
                    (Comp.CustomFieldForm.view2
                        texts.customFieldForm
                        { classes = ""
                        , showControls = False
                        }
                        fm
                    )
                )
    ]
        ++ (if withButtons then
                [ div [ class "flex flex-row space-x-2" ]
                    (viewButtons2 texts model)
                ]

            else
                []
           )
