module Comp.DetailEdit exposing
    ( Model
    , Msg
    , Value(..)
    , editEquip
    , editOrg
    , editPerson
    , initConcPerson
    , initCorrPerson
    , initEquip
    , initOrg
    , initTag
    , initTagByName
    , update
    , view
    , viewModal
    )

{-| Module for allowing to edit metadata in the item-edit menu.

It is only possible to edit one thing at a time, suitable for being
rendered in a modal.

-}

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.Equipment exposing (Equipment)
import Api.Model.Organization exposing (Organization)
import Api.Model.Person exposing (Person)
import Api.Model.Tag exposing (Tag)
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
import Util.Http


type alias Model =
    { form : FormModel
    , itemId : String
    , submitting : Bool
    , loading : Bool
    , result : Maybe BasicResult
    }


type FormModel
    = TM Comp.TagForm.Model
    | PMR Comp.PersonForm.Model
    | PMC Comp.PersonForm.Model
    | OM Comp.OrgForm.Model
    | EM Comp.EquipmentForm.Model


fold :
    (Comp.TagForm.Model -> a)
    -> (Comp.PersonForm.Model -> a)
    -> (Comp.OrgForm.Model -> a)
    -> (Comp.EquipmentForm.Model -> a)
    -> FormModel
    -> a
fold ft fp fo fe model =
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


init : String -> FormModel -> Model
init itemId fm =
    { form = fm
    , itemId = itemId
    , submitting = False
    , loading = False
    , result = Nothing
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
      , result = Nothing
      }
    , Api.getOrgFull orgId flags GetOrgResp
    )


editPerson : Flags -> String -> Comp.PersonForm.Model -> ( Model, Cmd Msg )
editPerson flags persId pm =
    ( { form = PMC pm
      , itemId = ""
      , submitting = False
      , loading = True
      , result = Nothing
      }
    , Api.getPersonFull persId flags GetPersonResp
    )


editEquip : Flags -> String -> Comp.EquipmentForm.Model -> ( Model, Cmd Msg )
editEquip flags equipId em =
    ( { form = EM em
      , itemId = ""
      , submitting = False
      , loading = True
      , result = Nothing
      }
    , Api.getEquipment flags equipId GetEquipResp
    )


initCorrPerson : String -> Comp.PersonForm.Model -> Model
initCorrPerson itemId pm =
    init itemId (PMR pm)


initConcPerson : String -> Comp.PersonForm.Model -> Model
initConcPerson itemId pm =
    init itemId (PMC pm)


initTag : String -> Comp.TagForm.Model -> Model
initTag itemId tm =
    init itemId (TM tm)


initTagByName : String -> String -> Model
initTagByName itemId name =
    let
        tm =
            Comp.TagForm.emptyModel

        tm_ =
            { tm | name = name }
    in
    initTag itemId tm_


type Msg
    = TagMsg Comp.TagForm.Msg
    | PersonMsg Comp.PersonForm.Msg
    | OrgMsg Comp.OrgForm.Msg
    | EquipMsg Comp.EquipmentForm.Msg
    | Submit
    | Cancel
    | SubmitResp (Result Http.Error BasicResult)
    | GetOrgResp (Result Http.Error Organization)
    | GetPersonResp (Result Http.Error Person)
    | GetEquipResp (Result Http.Error Equipment)


type Value
    = SubmitTag Tag
    | SubmitPerson Person
    | SubmitOrg Organization
    | SubmitEquip Equipment
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
            ( { model | loading = False, result = Just (BasicResult False (Util.Http.errorToString err)) }
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
            ( { model | loading = False, result = Just (BasicResult False (Util.Http.errorToString err)) }
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
            ( { model | loading = False, result = Just (BasicResult False (Util.Http.errorToString err)) }
            , Cmd.none
            , Nothing
            )

        SubmitResp (Ok res) ->
            ( { model
                | result = Just res
                , submitting = False
              }
            , Cmd.none
            , Just (makeValue model.form)
            )

        SubmitResp (Err err) ->
            ( { model
                | result = Just (BasicResult False (Util.Http.errorToString err))
                , submitting = False
              }
            , Cmd.none
            , Nothing
            )

        Submit ->
            let
                failMsg =
                    Just (BasicResult False "Please fill required fields.")
            in
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
                        ( { model | result = failMsg }
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
                        ( { model | result = failMsg }
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
                        ( { model | result = failMsg }
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
                        ( { model | result = failMsg }
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
                        ( { model | result = failMsg }
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
                        , result = Nothing
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
                        , result = Nothing
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
                        , result = Nothing
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
                        , result = Nothing
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
                        , result = Nothing
                      }
                    , Cmd.map EquipMsg ec_
                    , Nothing
                    )

                _ ->
                    ( model, Cmd.none, Nothing )



--- View


viewButtons : Model -> List (Html Msg)
viewButtons model =
    [ button
        [ class "ui primary button"
        , href "#"
        , onClick Submit
        , disabled (model.submitting || model.loading)
        ]
        [ if model.submitting || model.loading then
            i [ class "ui spinner loading icon" ] []

          else
            text "Submit"
        ]
    , button
        [ class "ui button"
        , href "#"
        , onClick Cancel
        ]
        [ text "Cancel"
        ]
    ]


viewIntern : UiSettings -> Bool -> Model -> List (Html Msg)
viewIntern settings withButtons model =
    [ div
        [ classList
            [ ( "ui message", True )
            , ( "error", Maybe.map .success model.result == Just False )
            , ( "success", Maybe.map .success model.result == Just True )
            , ( "invisible hidden", model.result == Nothing )
            ]
        ]
        [ Maybe.map .message model.result
            |> Maybe.withDefault ""
            |> text
        ]
    , case model.form of
        TM tm ->
            Html.map TagMsg (Comp.TagForm.view tm)

        PMR pm ->
            Html.map PersonMsg (Comp.PersonForm.view1 settings True pm)

        PMC pm ->
            Html.map PersonMsg (Comp.PersonForm.view1 settings True pm)

        OM om ->
            Html.map OrgMsg (Comp.OrgForm.view1 settings True om)

        EM em ->
            Html.map EquipMsg (Comp.EquipmentForm.view em)
    ]
        ++ (if withButtons then
                div [ class "ui divider" ] [] :: viewButtons model

            else
                []
           )


view : UiSettings -> Model -> Html Msg
view settings model =
    div []
        (viewIntern settings True model)


viewModal : UiSettings -> Maybe Model -> Html Msg
viewModal settings mm =
    let
        hidden =
            mm == Nothing

        heading =
            fold (\_ -> "Add Tag")
                (\_ -> "Add Person")
                (\_ -> "Add Organization")
                (\_ -> "Add Equipment")

        headIcon =
            fold (\_ -> Icons.tagIcon "")
                (\_ -> Icons.personIcon "")
                (\_ -> Icons.organizationIcon "")
                (\_ -> Icons.equipmentIcon "")
    in
    div
        [ classList
            [ ( "ui inverted dimmer keep-small", True )
            , ( "invisibe hidden", hidden )
            , ( "active", not hidden )
            ]
        , style "display" "flex !important"
        ]
        [ div
            [ classList
                [ ( "ui modal keep-small", True )
                , ( "active", not hidden )
                ]
            ]
            [ div [ class "header" ]
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
                        viewIntern settings False model

                    Nothing ->
                        []
                )
            , div [ class "actions" ]
                (case mm of
                    Just model ->
                        viewButtons model

                    Nothing ->
                        []
                )
            ]
        ]
