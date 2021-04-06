module Comp.ItemDetail.FieldTabState exposing (EditTab(..), allTabs, findTab, tabName, tabState)

import Comp.CustomFieldMultiInput
import Comp.Tabs as TB
import Data.Fields
import Data.UiSettings exposing (UiSettings)
import Set exposing (Set)


type EditTab
    = TabName
    | TabDate
    | TabTags
    | TabFolder
    | TabCustomFields
    | TabDueDate
    | TabCorrespondent
    | TabConcerning
    | TabDirection
    | TabConfirmUnconfirm


allTabs : List EditTab
allTabs =
    [ TabName
    , TabDate
    , TabTags
    , TabFolder
    , TabCustomFields
    , TabDueDate
    , TabCorrespondent
    , TabConcerning
    , TabDirection
    , TabConfirmUnconfirm
    ]


tabName : EditTab -> String
tabName tab =
    case tab of
        TabName ->
            "name"

        TabTags ->
            "tags"

        TabDate ->
            "date"

        TabFolder ->
            "folder"

        TabCustomFields ->
            "custom-fields"

        TabDueDate ->
            "due-date"

        TabCorrespondent ->
            "correspondent"

        TabConcerning ->
            "concerning"

        TabDirection ->
            "direction"

        TabConfirmUnconfirm ->
            "confirm-unconfirm"


findTab : TB.Tab msg -> Maybe EditTab
findTab tab =
    case tab.name of
        "name" ->
            Just TabName

        "tags" ->
            Just TabTags

        "date" ->
            Just TabDate

        "folder" ->
            Just TabFolder

        "custom-fields" ->
            Just TabCustomFields

        "due-date" ->
            Just TabDueDate

        "correspondent" ->
            Just TabCorrespondent

        "concerning" ->
            Just TabConcerning

        "direction" ->
            Just TabDirection

        _ ->
            Nothing


tabState :
    UiSettings
    -> Set String
    -> Maybe Comp.CustomFieldMultiInput.Model
    -> (TB.Tab msg -> msg)
    -> TB.Tab msg
    -> ( TB.State, msg )
tabState settings openTabs cfmodel toggle tab =
    let
        isHidden f =
            Data.UiSettings.fieldHidden settings f

        hidden =
            case findTab tab of
                Just TabTags ->
                    isHidden Data.Fields.Tag

                Just TabFolder ->
                    isHidden Data.Fields.Folder

                Just TabCorrespondent ->
                    isHidden Data.Fields.CorrOrg && isHidden Data.Fields.CorrPerson

                Just TabConcerning ->
                    isHidden Data.Fields.ConcEquip && isHidden Data.Fields.ConcPerson

                Just TabCustomFields ->
                    isHidden Data.Fields.CustomFields
                        || (Maybe.map Comp.CustomFieldMultiInput.isEmpty cfmodel
                                |> Maybe.withDefault False
                           )

                Just TabDate ->
                    isHidden Data.Fields.Date

                Just TabDueDate ->
                    isHidden Data.Fields.DueDate

                Just TabDirection ->
                    isHidden Data.Fields.Direction

                _ ->
                    False

        state =
            if hidden then
                TB.Hidden

            else if Set.member tab.name openTabs then
                TB.Open

            else
                TB.Closed
    in
    ( state, toggle tab )
