module Comp.ItemDetail.View exposing (view)

import Api.Model.Attachment exposing (Attachment)
import Comp.AttachmentMeta
import Comp.DatePicker
import Comp.DetailEdit
import Comp.Dropdown
import Comp.Dropzone
import Comp.ItemDetail.Model exposing (Model, NotesField(..))
import Comp.ItemDetail.Update exposing (Msg(..))
import Comp.ItemMail
import Comp.MarkdownInput
import Comp.SentMails
import Comp.YesNoDimmer
import Data.Direction
import Data.Fields exposing (Field)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import DatePicker
import Dict
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Html5.DragDrop as DD
import Markdown
import Page exposing (Page(..))
import Set
import Util.File exposing (makeFileId)
import Util.Folder
import Util.List
import Util.Maybe
import Util.Size
import Util.String
import Util.Time


view : { prev : Maybe String, next : Maybe String } -> UiSettings -> Model -> Html Msg
view inav settings model =
    div []
        [ renderItemInfo settings model
        , renderDetailMenu inav model
        , renderMailForm settings model
        , renderAddFilesForm model
        , div [ class "ui grid" ]
            [ Html.map DeleteItemConfirm (Comp.YesNoDimmer.view model.deleteItemConfirm)
            , div
                [ classList
                    [ ( "sixteen wide mobile six wide tablet five wide computer column", True )
                    , ( "invisible", not model.menuOpen )
                    ]
                ]
                (if model.menuOpen then
                    renderEditMenu settings model

                 else
                    []
                )
            , div
                [ classList
                    [ ( "sixteen wide mobile ten wide tablet eleven wide computer column", model.menuOpen )
                    , ( "sixteen", not model.menuOpen )
                    , ( "wide column", True )
                    ]
                ]
              <|
                List.concat
                    [ if settings.itemDetailNotesPosition == Data.UiSettings.Top then
                        [ renderNotes model ]

                      else
                        []
                    , [ renderAttachmentsTabMenu model
                      ]
                    , renderAttachmentsTabBody settings model
                    , renderIdInfo model
                    , if settings.itemDetailNotesPosition == Data.UiSettings.Bottom then
                        [ renderNotes model ]

                      else
                        []
                    ]
            ]
        ]



--- Helper


renderDetailMenu : { prev : Maybe String, next : Maybe String } -> Model -> Html Msg
renderDetailMenu inav model =
    div
        [ classList
            [ ( "ui ablue-comp menu", True )
            , ( "top attached"
              , model.mailOpen
                    || model.addFilesOpen
              )
            ]
        ]
        [ a [ class "item", Page.href (HomePage (Just model.item.id)) ]
            [ i [ class "arrow left icon" ] []
            ]
        , a
            [ classList
                [ ( "item", True )
                , ( "disabled", inav.prev == Nothing )
                ]
            , Maybe.map ItemDetailPage inav.prev
                |> Maybe.map Page.href
                |> Maybe.withDefault (href "#")
            ]
            [ i [ class "caret square left outline icon" ] []
            ]
        , a
            [ classList
                [ ( "item", True )
                , ( "disabled", inav.next == Nothing )
                ]
            , Maybe.map ItemDetailPage inav.next
                |> Maybe.map Page.href
                |> Maybe.withDefault (href "#")
            ]
            [ i [ class "caret square right outline icon" ] []
            ]
        , a
            [ classList
                [ ( "toggle item", True )
                , ( "active", model.menuOpen )
                ]
            , title "Edit Metadata"
            , onClick ToggleMenu
            , href ""
            ]
            [ i [ class "edit icon" ] []
            ]
        , a
            [ classList
                [ ( "toggle item", True )
                , ( "active", model.mailOpen )
                ]
            , title "Send Mail"
            , onClick ToggleMail
            , href "#"
            ]
            [ i [ class "mail outline icon" ] []
            ]
        , a
            [ classList
                [ ( "toggle item", True )
                , ( "active", model.addFilesOpen )
                ]
            , if model.addFilesOpen then
                title "Close"

              else
                title "Add Files"
            , onClick AddFilesToggle
            , href "#"
            ]
            [ Icons.addFilesIcon
            ]
        ]


actionInputDatePicker : DatePicker.Settings
actionInputDatePicker =
    let
        ds =
            Comp.DatePicker.defaultSettings
    in
    { ds | containerClassList = [ ( "ui action input", True ) ] }


renderIdInfo : Model -> List (Html msg)
renderIdInfo model =
    [ div [ class "ui bottom attached segment" ]
        [ div [ class "ui center aligned container" ]
            [ div [ class "ui bulleted mini horizontal list small-info" ]
                [ div [ class "item" ]
                    [ i [ class "bullseye icon" ] []
                    , text model.item.id
                    ]
                , div [ class "item" ]
                    [ i [ class "sun outline icon" ] []
                    , Util.Time.formatDateTime model.item.created |> text
                    ]
                , div [ class "item" ]
                    [ i [ class "pencil alternate icon" ] []
                    , Util.Time.formatDateTime model.item.updated |> text
                    ]
                ]
            ]
        ]
    ]


renderNotes : Model -> Html Msg
renderNotes model =
    case model.notesField of
        ViewNotes ->
            div [ class "ui segments" ]
                [ div [ class "ui segment" ]
                    [ div [ class "ui two column grid" ]
                        [ div [ class "column" ]
                            [ p [ class "ui header" ]
                                [ text "Notes"
                                ]
                            ]
                        , div [ class "right aligned column" ]
                            [ a
                                [ class "ui basic icon link"
                                , onClick ToggleEditNotes
                                , href "#"
                                ]
                                [ i [ class "edit icon" ] []
                                ]
                            ]
                        ]
                    ]
                , div [ class "ui segment" ]
                    [ Markdown.toHtml [] (Maybe.withDefault "" model.item.notes)
                    ]
                ]

        EditNotes mm ->
            let
                classes act =
                    classList
                        [ ( "item", True )
                        , ( "active", act )
                        ]
            in
            div [ class "ui segments" ]
                [ div [ class "ui segment" ]
                    [ div [ class "ui grid" ]
                        [ div [ class "two wide column" ]
                            [ p [ class "ui header" ]
                                [ text "Notes"
                                ]
                            ]
                        , div [ class "eleven wide center aligned column" ]
                            [ div [ class "ui horizontal bulleted link list" ]
                                [ Html.map NotesEditMsg
                                    (Comp.MarkdownInput.viewEditLink classes mm)
                                , Html.map NotesEditMsg
                                    (Comp.MarkdownInput.viewPreviewLink classes mm)
                                , Html.map NotesEditMsg
                                    (Comp.MarkdownInput.viewSplitLink classes mm)
                                ]
                            ]
                        , div [ class "right aligned three wide column" ]
                            [ div [ class "ui horizontal link list" ]
                                [ Comp.MarkdownInput.viewCheatLink "item" mm
                                ]
                            ]
                        ]
                    ]
                , div [ class "ui segment" ]
                    [ Html.map NotesEditMsg
                        (Comp.MarkdownInput.viewContent
                            (Maybe.withDefault "" model.notesModel)
                            mm
                        )
                    , div [ class "ui secondary menu" ]
                        [ a
                            [ class "link item"
                            , href "#"
                            , onClick SaveNotes
                            ]
                            [ i [ class "save outline icon" ] []
                            , text "Save"
                            ]
                        , a
                            [ classList
                                [ ( "link item", True )
                                , ( "invisible hidden", Util.String.isNothingOrBlank model.item.notes )
                                ]
                            , href "#"
                            , onClick ToggleEditNotes
                            ]
                            [ i [ class "cancel icon" ] []
                            , text "Cancel"
                            ]
                        ]
                    ]
                ]


attachmentVisible : Model -> Int -> Bool
attachmentVisible model pos =
    if model.visibleAttach >= List.length model.item.attachments then
        pos == 0

    else
        model.visibleAttach == pos


renderAttachmentsTabMenu : Model -> Html Msg
renderAttachmentsTabMenu model =
    let
        mailTab =
            if Comp.SentMails.isEmpty model.sentMails then
                []

            else
                [ div
                    [ classList
                        [ ( "right item", True )
                        , ( "active", model.sentMailsOpen )
                        ]
                    , onClick ToggleSentMails
                    ]
                    [ text "E-Mails"
                    ]
                ]

        highlight el =
            let
                dropId =
                    DD.getDropId model.attachDD

                dragId =
                    DD.getDragId model.attachDD

                enable =
                    Just el.id == dropId && dropId /= dragId
            in
            [ ( "current-drop-target", enable )
            ]
    in
    div [ class "ui top attached tabular menu" ]
        (List.indexedMap
            (\pos ->
                \el ->
                    if attachmentVisible model pos then
                        a
                            ([ classList <|
                                [ ( "active item", True )
                                ]
                                    ++ highlight el
                             , title (Maybe.withDefault "No Name" el.name)
                             , href ""
                             ]
                                ++ DD.draggable AttachDDMsg el.id
                                ++ DD.droppable AttachDDMsg el.id
                            )
                            [ Maybe.map (Util.String.ellipsis 30) el.name
                                |> Maybe.withDefault "No Name"
                                |> text
                            , a
                                [ class "right-tab-icon-link"
                                , href "#"
                                , onClick (EditAttachNameStart el.id)
                                ]
                                [ i [ class "grey edit link icon" ] []
                                ]
                            ]

                    else
                        a
                            ([ classList <|
                                [ ( "item", True )
                                ]
                                    ++ highlight el
                             , title (Maybe.withDefault "No Name" el.name)
                             , href ""
                             , onClick (SetActiveAttachment pos)
                             ]
                                ++ DD.draggable AttachDDMsg el.id
                                ++ DD.droppable AttachDDMsg el.id
                            )
                            [ Maybe.map (Util.String.ellipsis 20) el.name
                                |> Maybe.withDefault "No Name"
                                |> text
                            ]
            )
            model.item.attachments
            ++ mailTab
        )


renderAttachmentView : UiSettings -> Model -> Int -> Attachment -> Html Msg
renderAttachmentView settings model pos attach =
    let
        fileUrl =
            "/api/v1/sec/attachment/" ++ attach.id

        attachName =
            Maybe.withDefault "No name" attach.name

        hasArchive =
            List.map .id model.item.archives
                |> List.member attach.id
    in
    div
        [ classList
            [ ( "ui attached tab segment", True )
            , ( "active", attachmentVisible model pos )
            ]
        ]
        [ Html.map (DeleteAttachConfirm attach.id) (Comp.YesNoDimmer.view model.deleteAttachConfirm)
        , renderEditAttachmentName model attach
        , div [ class "ui small secondary menu" ]
            [ div [ class "horizontally fitted item" ]
                [ i [ class "file outline icon" ] []
                , text attachName
                , text " ("
                , text (Util.Size.bytesReadable Util.Size.B (toFloat attach.size))
                , text ")"
                ]
            , div [ class "item" ]
                [ div [ class "ui slider checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , onCheck (\_ -> TogglePdfNativeView settings.nativePdfPreview)
                        , checked (Maybe.withDefault settings.nativePdfPreview model.pdfNativeView)
                        ]
                        []
                    , label [] [ text "Native view" ]
                    ]
                ]
            , div [ class "right menu" ]
                [ a
                    [ classList
                        [ ( "item", True )
                        ]
                    , title "Delete this file permanently"
                    , href "#"
                    , onClick (RequestDeleteAttachment attach.id)
                    ]
                    [ i [ class "red trash icon" ] []
                    ]
                , a
                    [ classList
                        [ ( "item", True )
                        , ( "invisible", not hasArchive )
                        ]
                    , title "Download the original archive file."
                    , href (fileUrl ++ "/archive")
                    , target "_new"
                    ]
                    [ i [ class "file archive outline icon" ] []
                    ]
                , a
                    [ classList
                        [ ( "item", True )
                        , ( "disabled", not attach.converted )
                        ]
                    , title
                        (if attach.converted then
                            case Util.List.find (\s -> s.id == attach.id) model.item.sources of
                                Just src ->
                                    "Goto original: "
                                        ++ Maybe.withDefault "<noname>" src.name

                                Nothing ->
                                    "Goto original file"

                         else
                            "The file was not converted."
                        )
                    , href (fileUrl ++ "/original")
                    , target "_new"
                    ]
                    [ i [ class "external square alternate icon" ] []
                    ]
                , a
                    [ classList
                        [ ( "toggle item", True )
                        , ( "active", isAttachMetaOpen model attach.id )
                        ]
                    , title "Show extracted data"
                    , onClick (AttachMetaClick attach.id)
                    , href "#"
                    ]
                    [ i [ class "info icon" ] []
                    ]
                , a
                    [ class "item"
                    , title "Download PDF to disk"
                    , download attachName
                    , href fileUrl
                    ]
                    [ i [ class "download icon" ] []
                    ]
                ]
            ]
        , div
            [ classList
                [ ( "ui 4:3 embed doc-embed", True )
                , ( "invisible hidden", isAttachMetaOpen model attach.id )
                ]
            ]
            [ iframe
                [ if Maybe.withDefault settings.nativePdfPreview model.pdfNativeView then
                    src fileUrl

                  else
                    src (fileUrl ++ "/view")
                ]
                []
            ]
        , div
            [ classList
                [ ( "ui basic segment", True )
                , ( "invisible hidden", not (isAttachMetaOpen model attach.id) )
                ]
            ]
            [ case Dict.get attach.id model.attachMeta of
                Just am ->
                    Html.map (AttachMetaMsg attach.id)
                        (Comp.AttachmentMeta.view am)

                Nothing ->
                    span [] []
            ]
        ]


isAttachMetaOpen : Model -> String -> Bool
isAttachMetaOpen model id =
    model.attachMetaOpen && (Dict.get id model.attachMeta /= Nothing)


renderAttachmentsTabBody : UiSettings -> Model -> List (Html Msg)
renderAttachmentsTabBody settings model =
    let
        mailTab =
            if Comp.SentMails.isEmpty model.sentMails then
                []

            else
                [ div
                    [ classList
                        [ ( "ui attached tab segment", True )
                        , ( "active", model.sentMailsOpen )
                        ]
                    ]
                    [ h3 [ class "ui header" ]
                        [ text "Sent E-Mails"
                        ]
                    , Html.map SentMailsMsg (Comp.SentMails.view model.sentMails)
                    ]
                ]
    in
    List.indexedMap (renderAttachmentView settings model) model.item.attachments
        ++ mailTab


renderItemInfo : UiSettings -> Model -> Html Msg
renderItemInfo settings model =
    let
        date =
            ( div
                [ class "item"
                , title "Item Date"
                ]
                [ Maybe.withDefault model.item.created model.item.itemDate
                    |> Util.Time.formatDate
                    |> text
                ]
            , Data.UiSettings.fieldVisible settings Data.Fields.Date
            )

        duedate =
            ( div
                [ class "item"
                , title "Due Date"
                ]
                [ Icons.dueDateIcon "grey"
                , Maybe.map Util.Time.formatDate model.item.dueDate
                    |> Maybe.withDefault ""
                    |> text
                ]
            , Data.UiSettings.fieldVisible settings Data.Fields.DueDate
                && Util.Maybe.nonEmpty model.item.dueDate
            )

        corr =
            ( div
                [ class "item"
                , title "Correspondent"
                ]
                [ Icons.correspondentIcon ""
                , List.filterMap identity [ model.item.corrOrg, model.item.corrPerson ]
                    |> List.map .name
                    |> String.join ", "
                    |> Util.String.withDefault "(None)"
                    |> text
                ]
            , Data.UiSettings.fieldVisible settings Data.Fields.CorrOrg
                || Data.UiSettings.fieldVisible settings Data.Fields.CorrPerson
            )

        conc =
            ( div
                [ class "item"
                , title "Concerning"
                ]
                [ Icons.concernedIcon
                , List.filterMap identity [ model.item.concPerson, model.item.concEquipment ]
                    |> List.map .name
                    |> String.join ", "
                    |> Util.String.withDefault "(None)"
                    |> text
                ]
            , Data.UiSettings.fieldVisible settings Data.Fields.ConcEquip
                || Data.UiSettings.fieldVisible settings Data.Fields.ConcPerson
            )

        itemfolder =
            ( div
                [ class "item"
                , title "Folder"
                ]
                [ Icons.folderIcon ""
                , Maybe.map .name model.item.folder
                    |> Maybe.withDefault "-"
                    |> text
                ]
            , Data.UiSettings.fieldVisible settings Data.Fields.Folder
            )

        src =
            ( div
                [ class "item"
                , title "Source"
                ]
                [ text model.item.source
                ]
            , True
            )
    in
    div [ class "ui fluid container" ]
        (h2
            [ class "ui header"
            ]
            [ i
                [ classList
                    [ ( Data.Direction.iconFromString model.item.direction, True )
                    , ( "hidden invisible", Data.UiSettings.fieldHidden settings Data.Fields.Direction )
                    ]
                , title model.item.direction
                ]
                []
            , div [ class "content" ]
                [ text model.item.name
                , div
                    [ classList
                        [ ( "ui teal label", True )
                        , ( "invisible", model.item.state /= "created" )
                        ]
                    ]
                    [ text "New!"
                    ]
                , div [ class "sub header" ]
                    [ div [ class "ui horizontal bulleted list" ]
                        (List.filter Tuple.second
                            [ date
                            , corr
                            , conc
                            , itemfolder
                            , src
                            , duedate
                            ]
                            |> List.map Tuple.first
                        )
                    ]
                ]
            ]
            :: renderTags settings model
        )


renderTags : UiSettings -> Model -> List (Html Msg)
renderTags settings model =
    if Data.UiSettings.fieldHidden settings Data.Fields.Tag then
        []

    else
        case model.item.tags of
            [] ->
                []

            _ ->
                [ div [ class "ui right aligned fluid container" ] <|
                    List.map
                        (\t ->
                            div
                                [ classList
                                    [ ( "ui tag label", True )
                                    , ( Data.UiSettings.tagColorString t settings, True )
                                    ]
                                ]
                                [ text t.name
                                ]
                        )
                        model.item.tags
                ]


renderEditMenu : UiSettings -> Model -> List (Html Msg)
renderEditMenu settings model =
    [ Html.map ModalEditMsg (Comp.DetailEdit.viewModal settings model.modalEdit)
    , div []
        [ renderEditButtons model
        , renderEditForm settings model
        ]
    ]


renderEditButtons : Model -> Html Msg
renderEditButtons model =
    div [ class "ui top attached icon ablue-comp menu" ]
        [ a
            [ classList
                [ ( "borderless item", True )
                , ( "invisible", model.item.state /= "created" )
                ]
            , title "Confirm metadata"
            , href "#"
            , onClick ConfirmItem
            ]
            [ i [ class "check icon" ] []
            ]
        , a
            [ classList
                [ ( "borderless item", True )
                , ( "invisible", model.item.state /= "confirmed" )
                ]
            , href "#"
            , title "Unconfirm metadata"
            , onClick UnconfirmItem
            ]
            [ i [ class "eye slash outline icon" ] []
            ]
        , div [ class "right floated menu" ]
            [ a
                [ class "borderless item"
                , onClick RequestDelete
                , href "#"
                , title "Delete the item"
                ]
                [ i [ class "red trash icon" ] []
                ]
            ]
        ]


renderEditForm : UiSettings -> Model -> Html Msg
renderEditForm settings model =
    let
        addIconLink tip m =
            a
                [ class "right-float"
                , href "#"
                , title tip
                , onClick m
                ]
                [ i [ class "grey plus link icon" ] []
                ]

        editIconLink tip dm m =
            a
                [ classList
                    [ ( "right-float", True )
                    , ( "invisible hidden", Comp.Dropdown.notSelected dm )
                    ]
                , href "#"
                , title tip
                , onClick m
                ]
                [ i [ class "grey pencil alternate link icon" ] []
                ]

        fieldVisible field =
            Data.UiSettings.fieldVisible settings field

        optional fields html =
            if
                List.map fieldVisible fields
                    |> List.foldl (||) False
            then
                html

            else
                span [ class "invisible hidden" ] []
    in
    div [ class "ui attached segment" ]
        [ div [ class "ui form warning" ]
            [ optional [ Data.Fields.Tag ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.tagsIcon "grey"
                        , text "Tags"
                        , addIconLink "Add new tag" StartTagModal
                        ]
                    , Html.map TagDropdownMsg (Comp.Dropdown.view settings model.tagModel)
                    ]
            , div [ class " field" ]
                [ label [] [ text "Name" ]
                , div [ class "ui action input" ]
                    [ input [ type_ "text", value model.nameModel, onInput SetName ] []
                    , button
                        [ class "ui icon button"
                        , onClick SaveName
                        ]
                        [ i [ class "save outline icon" ] []
                        ]
                    ]
                ]
            , optional [ Data.Fields.Folder ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.folderIcon "grey"
                        , text "Folder"
                        ]
                    , Html.map FolderDropdownMsg (Comp.Dropdown.view settings model.folderModel)
                    , div
                        [ classList
                            [ ( "ui warning message", True )
                            , ( "hidden", isFolderMember model )
                            ]
                        ]
                        [ Markdown.toHtml [] """
You are **not a member** of this folder. This item will be **hidden**
from any search now. Use a folder where you are a member of to make this
item visible. This message will disappear then.
                      """
                        ]
                    ]
            , optional [ Data.Fields.Direction ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.directionIcon "grey"
                        , text "Direction"
                        ]
                    , Html.map DirDropdownMsg (Comp.Dropdown.view settings model.directionModel)
                    ]
            , optional [ Data.Fields.Date ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.dateIcon "grey"
                        , text "Date"
                        ]
                    , div [ class "ui action input" ]
                        [ Html.map ItemDatePickerMsg
                            (Comp.DatePicker.viewTime
                                model.itemDate
                                actionInputDatePicker
                                model.itemDatePicker
                            )
                        , a [ class "ui icon button", href "", onClick RemoveDate ]
                            [ i [ class "trash alternate outline icon" ] []
                            ]
                        ]
                    , renderItemDateSuggestions model
                    ]
            , optional [ Data.Fields.DueDate ] <|
                div [ class " field" ]
                    [ label []
                        [ Icons.dueDateIcon "grey"
                        , text "Due Date"
                        ]
                    , div [ class "ui action input" ]
                        [ Html.map DueDatePickerMsg
                            (Comp.DatePicker.viewTime
                                model.dueDate
                                actionInputDatePicker
                                model.dueDatePicker
                            )
                        , a [ class "ui icon button", href "", onClick RemoveDueDate ]
                            [ i [ class "trash alternate outline icon" ] [] ]
                        ]
                    , renderDueDateSuggestions model
                    ]
            , optional [ Data.Fields.CorrOrg, Data.Fields.CorrPerson ] <|
                h4 [ class "ui dividing header" ]
                    [ Icons.correspondentIcon ""
                    , text "Correspondent"
                    ]
            , optional [ Data.Fields.CorrOrg ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.organizationIcon "grey"
                        , text "Organization"
                        , addIconLink "Add new organization" StartCorrOrgModal
                        , editIconLink "Edit organization" model.corrOrgModel StartEditCorrOrgModal
                        ]
                    , Html.map OrgDropdownMsg (Comp.Dropdown.view settings model.corrOrgModel)
                    , renderOrgSuggestions model
                    ]
            , optional [ Data.Fields.CorrPerson ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.personIcon "grey"
                        , text "Person"
                        , addIconLink "Add new correspondent person" StartCorrPersonModal
                        , editIconLink "Edit person"
                            model.corrPersonModel
                            (StartEditPersonModal model.corrPersonModel)
                        ]
                    , Html.map CorrPersonMsg (Comp.Dropdown.view settings model.corrPersonModel)
                    , renderCorrPersonSuggestions model
                    ]
            , optional [ Data.Fields.ConcPerson, Data.Fields.ConcEquip ] <|
                h4 [ class "ui dividing header" ]
                    [ Icons.concernedIcon
                    , text "Concerning"
                    ]
            , optional [ Data.Fields.ConcPerson ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.personIcon "grey"
                        , text "Person"
                        , addIconLink "Add new concerning person" StartConcPersonModal
                        , editIconLink "Edit person"
                            model.concPersonModel
                            (StartEditPersonModal model.concPersonModel)
                        ]
                    , Html.map ConcPersonMsg (Comp.Dropdown.view settings model.concPersonModel)
                    , renderConcPersonSuggestions model
                    ]
            , optional [ Data.Fields.ConcEquip ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.equipmentIcon "grey"
                        , text "Equipment"
                        , addIconLink "Add new equipment" StartEquipModal
                        , editIconLink "Edit equipment"
                            model.concEquipModel
                            StartEditEquipModal
                        ]
                    , Html.map ConcEquipMsg (Comp.Dropdown.view settings model.concEquipModel)
                    , renderConcEquipSuggestions model
                    ]
            ]
        ]


renderSuggestions : Model -> (a -> String) -> List a -> (a -> Msg) -> Html Msg
renderSuggestions model mkName idnames tagger =
    div
        [ classList
            [ ( "ui secondary vertical menu", True )
            , ( "invisible", model.item.state /= "created" )
            ]
        ]
        [ div [ class "item" ]
            [ div [ class "header" ]
                [ text "Suggestions"
                ]
            , div [ class "menu" ] <|
                (idnames
                    |> List.take 5
                    |> List.map (\p -> a [ class "item", href "", onClick (tagger p) ] [ text (mkName p) ])
                )
            ]
        ]


renderOrgSuggestions : Model -> Html Msg
renderOrgSuggestions model =
    renderSuggestions model
        .name
        (List.take 5 model.itemProposals.corrOrg)
        SetCorrOrgSuggestion


renderCorrPersonSuggestions : Model -> Html Msg
renderCorrPersonSuggestions model =
    renderSuggestions model
        .name
        (List.take 5 model.itemProposals.corrPerson)
        SetCorrPersonSuggestion


renderConcPersonSuggestions : Model -> Html Msg
renderConcPersonSuggestions model =
    renderSuggestions model
        .name
        (List.take 5 model.itemProposals.concPerson)
        SetConcPersonSuggestion


renderConcEquipSuggestions : Model -> Html Msg
renderConcEquipSuggestions model =
    renderSuggestions model
        .name
        (List.take 5 model.itemProposals.concEquipment)
        SetConcEquipSuggestion


renderItemDateSuggestions : Model -> Html Msg
renderItemDateSuggestions model =
    renderSuggestions model
        Util.Time.formatDate
        (List.take 5 model.itemProposals.itemDate)
        SetItemDateSuggestion


renderDueDateSuggestions : Model -> Html Msg
renderDueDateSuggestions model =
    renderSuggestions model
        Util.Time.formatDate
        (List.take 5 model.itemProposals.dueDate)
        SetDueDateSuggestion


renderMailForm : UiSettings -> Model -> Html Msg
renderMailForm settings model =
    div
        [ classList
            [ ( "ui bottom attached segment", True )
            , ( "invisible hidden", not model.mailOpen )
            ]
        ]
        [ h4 [ class "ui header" ]
            [ text "Send this item via E-Mail"
            ]
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.mailSending )
                ]
            ]
            [ div [ class "ui text loader" ]
                [ text "Sending …"
                ]
            ]
        , Html.map ItemMailMsg (Comp.ItemMail.view settings model.itemMail)
        , div
            [ classList
                [ ( "ui message", True )
                , ( "error"
                  , Maybe.map .success model.mailSendResult
                        |> Maybe.map not
                        |> Maybe.withDefault False
                  )
                , ( "success"
                  , Maybe.map .success model.mailSendResult
                        |> Maybe.withDefault False
                  )
                , ( "invisible hidden", model.mailSendResult == Nothing )
                ]
            ]
            [ Maybe.map .message model.mailSendResult
                |> Maybe.withDefault ""
                |> text
            ]
        ]


isIdle : Model -> File -> Bool
isIdle model file =
    not (isLoading model file || isCompleted model file || isError model file)


isLoading : Model -> File -> Bool
isLoading model file =
    Set.member (makeFileId file) model.loading


isCompleted : Model -> File -> Bool
isCompleted model file =
    Set.member (makeFileId file) model.completed


isError : Model -> File -> Bool
isError model file =
    Set.member (makeFileId file) model.errored


isSuccessAll : Model -> Bool
isSuccessAll model =
    List.map makeFileId model.selectedFiles
        |> List.all (\id -> Set.member id model.completed)


renderAddFilesForm : Model -> Html Msg
renderAddFilesForm model =
    div
        [ classList
            [ ( "ui bottom attached segment", True )
            , ( "invisible hidden", not model.addFilesOpen )
            ]
        ]
        [ h4 [ class "ui header" ]
            [ text "Add more files to this item"
            ]
        , Html.map AddFilesMsg (Comp.Dropzone.view model.addFilesModel)
        , button
            [ class "ui primary button"
            , href "#"
            , onClick AddFilesSubmitUpload
            ]
            [ text "Submit"
            ]
        , button
            [ class "ui secondary button"
            , href "#"
            , onClick AddFilesReset
            ]
            [ text "Reset"
            ]
        , div
            [ classList
                [ ( "ui success message", True )
                , ( "invisible hidden", model.selectedFiles == [] || not (isSuccessAll model) )
                ]
            ]
            [ text "All files have been uploaded. They are being processed, some data "
            , text "may not be available immediately. "
            , a
                [ class "link"
                , href "#"
                , onClick ReloadItem
                ]
                [ text "Refresh now"
                ]
            ]
        , div [ class "ui items" ]
            (List.map (renderFileItem model) model.selectedFiles)
        ]


renderFileItem : Model -> File -> Html Msg
renderFileItem model file =
    let
        name =
            File.name file

        size =
            File.size file
                |> toFloat
                |> Util.Size.bytesReadable Util.Size.B
    in
    div [ class "item" ]
        [ i
            [ classList
                [ ( "large", True )
                , ( "file outline icon", isIdle model file )
                , ( "loading spinner icon", isLoading model file )
                , ( "green check icon", isCompleted model file )
                , ( "red bolt icon", isError model file )
                ]
            ]
            []
        , div [ class "middle aligned content" ]
            [ div [ class "header" ]
                [ text name
                ]
            , div [ class "right floated meta" ]
                [ text size
                ]
            , div [ class "description" ]
                [ div
                    [ classList
                        [ ( "ui small indicating progress", True )
                        ]
                    , id (makeFileId file)
                    ]
                    [ div [ class "bar" ]
                        []
                    ]
                ]
            ]
        ]


renderEditAttachmentName : Model -> Attachment -> Html Msg
renderEditAttachmentName model attach =
    let
        am =
            Util.Maybe.filter (\m -> m.id == attach.id) model.attachRename
    in
    case am of
        Just m ->
            div [ class "ui fluid action input" ]
                [ input
                    [ type_ "text"
                    , value m.newName
                    , onInput EditAttachNameSet
                    ]
                    []
                , button
                    [ class "ui primary icon button"
                    , onClick EditAttachNameSubmit
                    ]
                    [ i [ class "check icon" ] []
                    ]
                , button
                    [ class "ui secondary icon button"
                    , onClick EditAttachNameCancel
                    ]
                    [ i [ class "delete icon" ] []
                    ]
                ]

        Nothing ->
            span [ class "invisible hidden" ] []


isFolderMember : Model -> Bool
isFolderMember model =
    let
        selected =
            Comp.Dropdown.getSelected model.folderModel
                |> List.head
                |> Maybe.map .id
    in
    Util.Folder.isFolderMember model.allFolders selected
