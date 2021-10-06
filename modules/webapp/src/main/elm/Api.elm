{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Api exposing
    ( addConcEquip
    , addConcPerson
    , addCorrOrg
    , addCorrPerson
    , addMember
    , addShare
    , addTag
    , addTagsMultiple
    , attachmentPreviewURL
    , cancelJob
    , changeFolderName
    , changePassword
    , checkCalEvent
    , confirmMultiple
    , confirmOtp
    , createImapSettings
    , createMailSettings
    , createNewFolder
    , createNotifyDueItems
    , createScanMailbox
    , deleteAllItems
    , deleteAttachment
    , deleteAttachments
    , deleteCustomField
    , deleteCustomValue
    , deleteCustomValueMultiple
    , deleteEquip
    , deleteFolder
    , deleteImapSettings
    , deleteItem
    , deleteMailSettings
    , deleteNotifyDueItems
    , deleteOrg
    , deletePerson
    , deleteScanMailbox
    , deleteShare
    , deleteSource
    , deleteTag
    , deleteUser
    , disableOtp
    , fileURL
    , getAttachmentMeta
    , getClientSettings
    , getCollective
    , getCollectiveSettings
    , getContacts
    , getCustomFields
    , getDeleteUserData
    , getEquipment
    , getEquipments
    , getFolderDetail
    , getFolders
    , getImapSettings
    , getInsights
    , getItemProposals
    , getJobQueueState
    , getJobQueueStateIn
    , getMailSettings
    , getNotifyDueItems
    , getOrgFull
    , getOrgLight
    , getOrganizations
    , getOtpState
    , getPersonFull
    , getPersons
    , getPersonsLight
    , getScanMailbox
    , getSentMails
    , getShare
    , getShares
    , getSources
    , getTagCloud
    , getTags
    , getUsers
    , initOtp
    , itemBasePreviewURL
    , itemDetail
    , itemDetailShare
    , itemIndexSearch
    , itemSearch
    , itemSearchStats
    , login
    , loginSession
    , logout
    , mergeItems
    , moveAttachmentBefore
    , newInvite
    , openIdAuthLink
    , postCustomField
    , postEquipment
    , postNewUser
    , postOrg
    , postPerson
    , postSource
    , postTag
    , putCustomField
    , putCustomValue
    , putCustomValueMultiple
    , putUser
    , refreshSession
    , register
    , removeMember
    , removeTagsMultiple
    , reprocessItem
    , reprocessMultiple
    , restoreAllItems
    , restoreItem
    , saveClientSettings
    , searchShare
    , searchShareStats
    , sendMail
    , setAttachmentName
    , setCollectiveSettings
    , setConcEquip
    , setConcEquipmentMultiple
    , setConcPerson
    , setConcPersonMultiple
    , setConfirmed
    , setCorrOrg
    , setCorrOrgMultiple
    , setCorrPerson
    , setCorrPersonMultiple
    , setDateMultiple
    , setDirection
    , setDirectionMultiple
    , setDueDateMultiple
    , setFolder
    , setFolderMultiple
    , setItemDate
    , setItemDueDate
    , setItemName
    , setItemNotes
    , setJobPrio
    , setNameMultiple
    , setTags
    , setTagsMultiple
    , setUnconfirmed
    , shareAttachmentPreviewURL
    , shareFileURL
    , shareItemBasePreviewURL
    , startClassifier
    , startEmptyTrash
    , startOnceNotifyDueItems
    , startOnceScanMailbox
    , startReIndex
    , submitNotifyDueItems
    , toggleTags
    , twoFactor
    , unconfirmMultiple
    , updateNotifyDueItems
    , updateScanMailbox
    , updateShare
    , upload
    , uploadAmend
    , uploadSingle
    , verifyShare
    , versionInfo
    )

import Api.Model.AttachmentMeta exposing (AttachmentMeta)
import Api.Model.AuthResult exposing (AuthResult)
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.CalEventCheck exposing (CalEventCheck)
import Api.Model.CalEventCheckResult exposing (CalEventCheckResult)
import Api.Model.Collective exposing (Collective)
import Api.Model.CollectiveSettings exposing (CollectiveSettings)
import Api.Model.ContactList exposing (ContactList)
import Api.Model.CustomFieldList exposing (CustomFieldList)
import Api.Model.CustomFieldValue exposing (CustomFieldValue)
import Api.Model.DeleteUserData exposing (DeleteUserData)
import Api.Model.DirectionValue exposing (DirectionValue)
import Api.Model.EmailSettings exposing (EmailSettings)
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Api.Model.EmptyTrashSetting exposing (EmptyTrashSetting)
import Api.Model.Equipment exposing (Equipment)
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.FolderDetail exposing (FolderDetail)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.GenInvite exposing (GenInvite)
import Api.Model.IdList exposing (IdList)
import Api.Model.IdResult exposing (IdResult)
import Api.Model.ImapSettings exposing (ImapSettings)
import Api.Model.ImapSettingsList exposing (ImapSettingsList)
import Api.Model.InviteResult exposing (InviteResult)
import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ItemInsights exposing (ItemInsights)
import Api.Model.ItemLightList exposing (ItemLightList)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.ItemQuery exposing (ItemQuery)
import Api.Model.ItemUploadMeta exposing (ItemUploadMeta)
import Api.Model.ItemsAndDate exposing (ItemsAndDate)
import Api.Model.ItemsAndDirection exposing (ItemsAndDirection)
import Api.Model.ItemsAndFieldValue exposing (ItemsAndFieldValue)
import Api.Model.ItemsAndName exposing (ItemsAndName)
import Api.Model.ItemsAndRef exposing (ItemsAndRef)
import Api.Model.ItemsAndRefs exposing (ItemsAndRefs)
import Api.Model.JobPriority exposing (JobPriority)
import Api.Model.JobQueueState exposing (JobQueueState)
import Api.Model.MoveAttachment exposing (MoveAttachment)
import Api.Model.NewCustomField exposing (NewCustomField)
import Api.Model.NewFolder exposing (NewFolder)
import Api.Model.NotificationSettings exposing (NotificationSettings)
import Api.Model.NotificationSettingsList exposing (NotificationSettingsList)
import Api.Model.OptionalDate exposing (OptionalDate)
import Api.Model.OptionalId exposing (OptionalId)
import Api.Model.OptionalText exposing (OptionalText)
import Api.Model.Organization exposing (Organization)
import Api.Model.OrganizationList exposing (OrganizationList)
import Api.Model.OtpConfirm exposing (OtpConfirm)
import Api.Model.OtpResult exposing (OtpResult)
import Api.Model.OtpState exposing (OtpState)
import Api.Model.PasswordChange exposing (PasswordChange)
import Api.Model.Person exposing (Person)
import Api.Model.PersonList exposing (PersonList)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.Registration exposing (Registration)
import Api.Model.ScanMailboxSettings exposing (ScanMailboxSettings)
import Api.Model.ScanMailboxSettingsList exposing (ScanMailboxSettingsList)
import Api.Model.SearchStats exposing (SearchStats)
import Api.Model.SecondFactor exposing (SecondFactor)
import Api.Model.SentMails exposing (SentMails)
import Api.Model.ShareData exposing (ShareData)
import Api.Model.ShareDetail exposing (ShareDetail)
import Api.Model.ShareList exposing (ShareList)
import Api.Model.ShareSecret exposing (ShareSecret)
import Api.Model.ShareVerifyResult exposing (ShareVerifyResult)
import Api.Model.SimpleMail exposing (SimpleMail)
import Api.Model.SourceAndTags exposing (SourceAndTags)
import Api.Model.SourceList exposing (SourceList)
import Api.Model.SourceTagIn
import Api.Model.StringList exposing (StringList)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagCloud exposing (TagCloud)
import Api.Model.TagList exposing (TagList)
import Api.Model.User exposing (User)
import Api.Model.UserList exposing (UserList)
import Api.Model.UserPass exposing (UserPass)
import Api.Model.VersionInfo exposing (VersionInfo)
import Data.ContactType exposing (ContactType)
import Data.CustomFieldOrder exposing (CustomFieldOrder)
import Data.EquipmentOrder exposing (EquipmentOrder)
import Data.Flags exposing (Flags)
import Data.FolderOrder exposing (FolderOrder)
import Data.OrganizationOrder exposing (OrganizationOrder)
import Data.PersonOrder exposing (PersonOrder)
import Data.Priority exposing (Priority)
import Data.TagOrder exposing (TagOrder)
import Data.UiSettings exposing (UiSettings)
import File exposing (File)
import Http
import Json.Decode as JsonDecode
import Json.Encode as JsonEncode
import Set exposing (Set)
import Task
import Url
import Util.File
import Util.Http as Http2



--- Custom Fields


putCustomValueMultiple :
    Flags
    -> ItemsAndFieldValue
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
putCustomValueMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/customfield"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndFieldValue.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


deleteCustomValueMultiple :
    Flags
    -> ItemsAndName
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
deleteCustomValueMultiple flags data receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/customfieldremove"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndName.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


deleteCustomValue :
    Flags
    -> String
    -> String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
deleteCustomValue flags item field receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/customfield/" ++ field
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


putCustomValue :
    Flags
    -> String
    -> CustomFieldValue
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
putCustomValue flags item fieldValue receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/customfield"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.CustomFieldValue.encode fieldValue)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getCustomFields : Flags -> String -> CustomFieldOrder -> (Result Http.Error CustomFieldList -> msg) -> Cmd msg
getCustomFields flags query order receive =
    Http2.authGet
        { url =
            flags.config.baseUrl
                ++ "/api/v1/sec/customfield?q="
                ++ Url.percentEncode query
                ++ "&sort="
                ++ Data.CustomFieldOrder.asString order
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.CustomFieldList.decoder
        }


postCustomField :
    Flags
    -> NewCustomField
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
postCustomField flags field receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/customfield"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NewCustomField.encode field)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


putCustomField :
    Flags
    -> String
    -> NewCustomField
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
putCustomField flags id field receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/customfield/" ++ id
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NewCustomField.encode field)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


deleteCustomField : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteCustomField flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/customfield/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Folders


deleteFolder : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteFolder flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/folder/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


removeMember : Flags -> String -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
removeMember flags id user receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/folder/" ++ id ++ "/member/" ++ user
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addMember : Flags -> String -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addMember flags id user receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/folder/" ++ id ++ "/member/" ++ user
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


changeFolderName : Flags -> String -> NewFolder -> (Result Http.Error BasicResult -> msg) -> Cmd msg
changeFolderName flags id ns receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/folder/" ++ id
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NewFolder.encode ns)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


createNewFolder : Flags -> NewFolder -> (Result Http.Error IdResult -> msg) -> Cmd msg
createNewFolder flags ns receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/folder"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NewFolder.encode ns)
        , expect = Http.expectJson receive Api.Model.IdResult.decoder
        }


getFolderDetail : Flags -> String -> (Result Http.Error FolderDetail -> msg) -> Cmd msg
getFolderDetail flags id receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/folder/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.FolderDetail.decoder
        }


getFolders :
    Flags
    -> String
    -> FolderOrder
    -> Bool
    -> (Result Http.Error FolderList -> msg)
    -> Cmd msg
getFolders flags query order owningOnly receive =
    Http2.authGet
        { url =
            flags.config.baseUrl
                ++ "/api/v1/sec/folder?q="
                ++ Url.percentEncode query
                ++ "&sort="
                ++ Data.FolderOrder.asString order
                ++ (if owningOnly then
                        "&owning=true"

                    else
                        ""
                   )
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.FolderList.decoder
        }



--- Full-Text


startReIndex : Flags -> (Result Http.Error BasicResult -> msg) -> Cmd msg
startReIndex flags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/fts/reIndex"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Scan Mailboxes


deleteScanMailbox :
    Flags
    -> String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
deleteScanMailbox flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/scanmailbox/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


startOnceScanMailbox :
    Flags
    -> ScanMailboxSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
startOnceScanMailbox flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/scanmailbox/startonce"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ScanMailboxSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


updateScanMailbox :
    Flags
    -> ScanMailboxSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
updateScanMailbox flags settings receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/scanmailbox"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ScanMailboxSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


createScanMailbox :
    Flags
    -> ScanMailboxSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
createScanMailbox flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/scanmailbox"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ScanMailboxSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getScanMailbox :
    Flags
    -> (Result Http.Error ScanMailboxSettingsList -> msg)
    -> Cmd msg
getScanMailbox flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/scanmailbox"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ScanMailboxSettingsList.decoder
        }



--- NotifyDueItems


deleteNotifyDueItems :
    Flags
    -> String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
deleteNotifyDueItems flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


startOnceNotifyDueItems :
    Flags
    -> NotificationSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
startOnceNotifyDueItems flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems/startonce"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NotificationSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


updateNotifyDueItems :
    Flags
    -> NotificationSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
updateNotifyDueItems flags settings receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NotificationSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


createNotifyDueItems :
    Flags
    -> NotificationSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
createNotifyDueItems flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NotificationSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getNotifyDueItems :
    Flags
    -> (Result Http.Error NotificationSettingsList -> msg)
    -> Cmd msg
getNotifyDueItems flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.NotificationSettingsList.decoder
        }


submitNotifyDueItems :
    Flags
    -> NotificationSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
submitNotifyDueItems flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NotificationSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- CalEvent


checkCalEvent :
    Flags
    -> CalEventCheck
    -> (Result Http.Error CalEventCheckResult -> msg)
    -> Cmd msg
checkCalEvent flags input receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/calevent/check"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.CalEventCheck.encode input)
        , expect = Http.expectJson receive Api.Model.CalEventCheckResult.decoder
        }



--- Delete Attachment


deleteAttachment :
    Flags
    -> String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
deleteAttachment flags attachId receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/attachment/" ++ attachId
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Delete Attachments


deleteAttachments :
    Flags
    -> Set String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
deleteAttachments flags attachIds receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/attachments/delete"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (Set.toList attachIds |> IdList))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Attachment Metadata


getAttachmentMeta :
    Flags
    -> String
    -> (Result Http.Error AttachmentMeta -> msg)
    -> Cmd msg
getAttachmentMeta flags id receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/attachment/" ++ id ++ "/meta"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.AttachmentMeta.decoder
        }



--- Get Sent Mails


getSentMails :
    Flags
    -> String
    -> (Result Http.Error SentMails -> msg)
    -> Cmd msg
getSentMails flags item receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/email/sent/item/" ++ item
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.SentMails.decoder
        }



--- Mail Send


sendMail :
    Flags
    -> { conn : String, item : String, mail : SimpleMail }
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
sendMail flags opts receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/email/send/" ++ opts.conn ++ "/" ++ opts.item
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.SimpleMail.encode opts.mail)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Mail Settings


deleteMailSettings : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteMailSettings flags name receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/email/settings/smtp/" ++ name
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


deleteImapSettings : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteImapSettings flags name receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/email/settings/imap/" ++ name
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getMailSettings : Flags -> String -> (Result Http.Error EmailSettingsList -> msg) -> Cmd msg
getMailSettings flags query receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/email/settings/smtp?q=" ++ Url.percentEncode query
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.EmailSettingsList.decoder
        }


getImapSettings : Flags -> String -> (Result Http.Error ImapSettingsList -> msg) -> Cmd msg
getImapSettings flags query receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/email/settings/imap?q=" ++ Url.percentEncode query
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ImapSettingsList.decoder
        }


createMailSettings :
    Flags
    -> Maybe String
    -> EmailSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
createMailSettings flags mname ems receive =
    case mname of
        Just en ->
            Http2.authPut
                { url = flags.config.baseUrl ++ "/api/v1/sec/email/settings/smtp/" ++ en
                , account = getAccount flags
                , body = Http.jsonBody (Api.Model.EmailSettings.encode ems)
                , expect = Http.expectJson receive Api.Model.BasicResult.decoder
                }

        Nothing ->
            Http2.authPost
                { url = flags.config.baseUrl ++ "/api/v1/sec/email/settings/smtp"
                , account = getAccount flags
                , body = Http.jsonBody (Api.Model.EmailSettings.encode ems)
                , expect = Http.expectJson receive Api.Model.BasicResult.decoder
                }


createImapSettings :
    Flags
    -> Maybe String
    -> ImapSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
createImapSettings flags mname ems receive =
    case mname of
        Just en ->
            Http2.authPut
                { url = flags.config.baseUrl ++ "/api/v1/sec/email/settings/imap/" ++ en
                , account = getAccount flags
                , body = Http.jsonBody (Api.Model.ImapSettings.encode ems)
                , expect = Http.expectJson receive Api.Model.BasicResult.decoder
                }

        Nothing ->
            Http2.authPost
                { url = flags.config.baseUrl ++ "/api/v1/sec/email/settings/imap"
                , account = getAccount flags
                , body = Http.jsonBody (Api.Model.ImapSettings.encode ems)
                , expect = Http.expectJson receive Api.Model.BasicResult.decoder
                }



--- Upload


uploadAmend :
    Flags
    -> String
    -> List File
    -> (String -> Result Http.Error BasicResult -> msg)
    -> List (Cmd msg)
uploadAmend flags itemId files receive =
    let
        mkReq file =
            let
                fid =
                    Util.File.makeFileId file

                path =
                    "/api/v1/sec/upload/item/" ++ itemId
            in
            Http2.authPostTrack
                { url = flags.config.baseUrl ++ path
                , account = getAccount flags
                , body =
                    Http.multipartBody <|
                        [ Http.filePart "file[]" file ]
                , expect = Http.expectJson (receive fid) Api.Model.BasicResult.decoder
                , tracker = fid
                }
    in
    List.map mkReq files


upload :
    Flags
    -> Maybe String
    -> ItemUploadMeta
    -> List File
    -> (String -> Result Http.Error BasicResult -> msg)
    -> List (Cmd msg)
upload flags sourceId meta files receive =
    let
        metaStr =
            JsonEncode.encode 0 (Api.Model.ItemUploadMeta.encode meta)

        mkReq file =
            let
                fid =
                    Util.File.makeFileId file

                path =
                    Maybe.map ((++) "/api/v1/open/upload/item/") sourceId
                        |> Maybe.withDefault "/api/v1/sec/upload/item"
            in
            Http2.authPostTrack
                { url = flags.config.baseUrl ++ path
                , account = getAccount flags
                , body =
                    Http.multipartBody <|
                        [ Http.stringPart "meta" metaStr, Http.filePart "file[]" file ]
                , expect = Http.expectJson (receive fid) Api.Model.BasicResult.decoder
                , tracker = fid
                }
    in
    List.map mkReq files


uploadSingle :
    Flags
    -> Maybe String
    -> ItemUploadMeta
    -> String
    -> List File
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
uploadSingle flags sourceId meta track files receive =
    let
        metaStr =
            JsonEncode.encode 0 (Api.Model.ItemUploadMeta.encode meta)

        fileParts =
            List.map (\f -> Http.filePart "file[]" f) files

        allParts =
            Http.stringPart "meta" metaStr :: fileParts

        path =
            Maybe.map ((++) "/api/v1/open/upload/item/") sourceId
                |> Maybe.withDefault "/api/v1/sec/upload/item"
    in
    Http2.authPostTrack
        { url = flags.config.baseUrl ++ path
        , account = getAccount flags
        , body = Http.multipartBody allParts
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        , tracker = track
        }



--- Registration


register : Flags -> Registration -> (Result Http.Error BasicResult -> msg) -> Cmd msg
register flags reg receive =
    Http.post
        { url = flags.config.baseUrl ++ "/api/v1/open/signup/register"
        , body = Http.jsonBody (Api.Model.Registration.encode reg)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


newInvite : Flags -> GenInvite -> (Result Http.Error InviteResult -> msg) -> Cmd msg
newInvite flags req receive =
    Http.post
        { url = flags.config.baseUrl ++ "/api/v1/open/signup/newinvite"
        , body = Http.jsonBody (Api.Model.GenInvite.encode req)
        , expect = Http.expectJson receive Api.Model.InviteResult.decoder
        }



--- Login


openIdAuthLink : Flags -> String -> String
openIdAuthLink flags provider =
    flags.config.baseUrl ++ "/api/v1/open/auth/openid/" ++ provider


login : Flags -> UserPass -> (Result Http.Error AuthResult -> msg) -> Cmd msg
login flags up receive =
    Http.post
        { url = flags.config.baseUrl ++ "/api/v1/open/auth/login"
        , body = Http.jsonBody (Api.Model.UserPass.encode up)
        , expect = Http.expectJson receive Api.Model.AuthResult.decoder
        }


twoFactor : Flags -> SecondFactor -> (Result Http.Error AuthResult -> msg) -> Cmd msg
twoFactor flags sf receive =
    Http.post
        { url = flags.config.baseUrl ++ "/api/v1/open/auth/two-factor"
        , body = Http.jsonBody (Api.Model.SecondFactor.encode sf)
        , expect = Http.expectJson receive Api.Model.AuthResult.decoder
        }


logout : Flags -> (Result Http.Error () -> msg) -> Cmd msg
logout flags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/auth/logout"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectWhatever receive
        }


loginSession : Flags -> (Result Http.Error AuthResult -> msg) -> Cmd msg
loginSession flags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/auth/session"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.AuthResult.decoder
        }


refreshSession : Flags -> (Result Http.Error AuthResult -> msg) -> Cmd msg
refreshSession flags receive =
    case flags.account of
        Just acc ->
            if acc.success && acc.validMs > 30000 then
                let
                    delay =
                        acc.validMs - 30000 |> toFloat
                in
                Http2.executeIn delay receive (refreshSessionTask flags)

            else
                Cmd.none

        Nothing ->
            Cmd.none


refreshSessionTask : Flags -> Task.Task Http.Error AuthResult
refreshSessionTask flags =
    Http2.authTask
        { url = flags.config.baseUrl ++ "/api/v1/sec/auth/session"
        , method = "POST"
        , headers = []
        , account = getAccount flags
        , body = Http.emptyBody
        , resolver = Http2.jsonResolver Api.Model.AuthResult.decoder
        , timeout = Nothing
        }



--- Version


versionInfo : Flags -> (Result Http.Error VersionInfo -> msg) -> Cmd msg
versionInfo flags receive =
    Http.get
        { url = flags.config.baseUrl ++ "/api/info/version"
        , expect = Http.expectJson receive Api.Model.VersionInfo.decoder
        }



--- Collective


startClassifier :
    Flags
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
startClassifier flags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/collective/classifier/startonce"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


startEmptyTrash :
    Flags
    -> EmptyTrashSetting
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
startEmptyTrash flags setting receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/collective/emptytrash/startonce"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.EmptyTrashSetting.encode setting)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getTagCloud : Flags -> (Result Http.Error TagCloud -> msg) -> Cmd msg
getTagCloud flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/collective/tagcloud"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.TagCloud.decoder
        }


getInsights : Flags -> (Result Http.Error ItemInsights -> msg) -> Cmd msg
getInsights flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/collective/insights"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ItemInsights.decoder
        }


getCollective : Flags -> (Result Http.Error Collective -> msg) -> Cmd msg
getCollective flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/collective"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.Collective.decoder
        }


getCollectiveSettings : Flags -> (Result Http.Error CollectiveSettings -> msg) -> Cmd msg
getCollectiveSettings flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/collective/settings"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.CollectiveSettings.decoder
        }


setCollectiveSettings : Flags -> CollectiveSettings -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setCollectiveSettings flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/collective/settings"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.CollectiveSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Contacts


getContacts :
    Flags
    -> Maybe ContactType
    -> Maybe String
    -> (Result Http.Error ContactList -> msg)
    -> Cmd msg
getContacts flags kind q receive =
    let
        pk =
            case kind of
                Just k ->
                    [ "kind=" ++ Data.ContactType.toString k ]

                Nothing ->
                    []

        pq =
            case q of
                Just str ->
                    [ "q=" ++ str ]

                Nothing ->
                    []

        params =
            pk ++ pq

        query =
            case String.join "&" params of
                "" ->
                    ""

                str ->
                    "?" ++ str
    in
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/collective/contacts" ++ query
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ContactList.decoder
        }



--- Tags


getTags : Flags -> String -> TagOrder -> (Result Http.Error TagList -> msg) -> Cmd msg
getTags flags query order receive =
    Http2.authGet
        { url =
            flags.config.baseUrl
                ++ "/api/v1/sec/tag?sort="
                ++ Data.TagOrder.asString order
                ++ "&q="
                ++ Url.percentEncode query
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.TagList.decoder
        }


postTag : Flags -> Tag -> (Result Http.Error BasicResult -> msg) -> Cmd msg
postTag flags tag receive =
    let
        params =
            { url = flags.config.baseUrl ++ "/api/v1/sec/tag"
            , account = getAccount flags
            , body = Http.jsonBody (Api.Model.Tag.encode tag)
            , expect = Http.expectJson receive Api.Model.BasicResult.decoder
            }
    in
    if tag.id == "" then
        Http2.authPost params

    else
        Http2.authPut params


deleteTag : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteTag flags tag receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/tag/" ++ tag
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Equipments


getEquipments : Flags -> String -> EquipmentOrder -> (Result Http.Error EquipmentList -> msg) -> Cmd msg
getEquipments flags query order receive =
    Http2.authGet
        { url =
            flags.config.baseUrl
                ++ "/api/v1/sec/equipment?q="
                ++ Url.percentEncode query
                ++ "&sort="
                ++ Data.EquipmentOrder.asString order
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.EquipmentList.decoder
        }


getEquipment : Flags -> String -> (Result Http.Error Equipment -> msg) -> Cmd msg
getEquipment flags id receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/equipment/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.Equipment.decoder
        }


postEquipment : Flags -> Equipment -> (Result Http.Error BasicResult -> msg) -> Cmd msg
postEquipment flags equip receive =
    let
        params =
            { url = flags.config.baseUrl ++ "/api/v1/sec/equipment"
            , account = getAccount flags
            , body = Http.jsonBody (Api.Model.Equipment.encode equip)
            , expect = Http.expectJson receive Api.Model.BasicResult.decoder
            }
    in
    if equip.id == "" then
        Http2.authPost params

    else
        Http2.authPut params


deleteEquip : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteEquip flags equip receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/equipment/" ++ equip
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Organization


getOrgLight : Flags -> (Result Http.Error ReferenceList -> msg) -> Cmd msg
getOrgLight flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/organization"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ReferenceList.decoder
        }


getOrgFull : String -> Flags -> (Result Http.Error Organization -> msg) -> Cmd msg
getOrgFull id flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/organization/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.Organization.decoder
        }


getOrganizations :
    Flags
    -> String
    -> OrganizationOrder
    -> (Result Http.Error OrganizationList -> msg)
    -> Cmd msg
getOrganizations flags query order receive =
    Http2.authGet
        { url =
            flags.config.baseUrl
                ++ "/api/v1/sec/organization?full=true&q="
                ++ Url.percentEncode query
                ++ "&sort="
                ++ Data.OrganizationOrder.asString order
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.OrganizationList.decoder
        }


postOrg : Flags -> Organization -> (Result Http.Error BasicResult -> msg) -> Cmd msg
postOrg flags org receive =
    let
        params =
            { url = flags.config.baseUrl ++ "/api/v1/sec/organization"
            , account = getAccount flags
            , body = Http.jsonBody (Api.Model.Organization.encode org)
            , expect = Http.expectJson receive Api.Model.BasicResult.decoder
            }
    in
    if org.id == "" then
        Http2.authPost params

    else
        Http2.authPut params


deleteOrg : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteOrg flags org receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/organization/" ++ org
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Person


getPersonsLight : Flags -> (Result Http.Error ReferenceList -> msg) -> Cmd msg
getPersonsLight flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/person?full=false"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ReferenceList.decoder
        }


getPersonFull : String -> Flags -> (Result Http.Error Person -> msg) -> Cmd msg
getPersonFull id flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/person/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.Person.decoder
        }


getPersons : Flags -> String -> PersonOrder -> (Result Http.Error PersonList -> msg) -> Cmd msg
getPersons flags query order receive =
    Http2.authGet
        { url =
            flags.config.baseUrl
                ++ "/api/v1/sec/person?full=true&q="
                ++ Url.percentEncode query
                ++ "&sort="
                ++ Data.PersonOrder.asString order
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.PersonList.decoder
        }


postPerson : Flags -> Person -> (Result Http.Error BasicResult -> msg) -> Cmd msg
postPerson flags person receive =
    let
        params =
            { url = flags.config.baseUrl ++ "/api/v1/sec/person"
            , account = getAccount flags
            , body = Http.jsonBody (Api.Model.Person.encode person)
            , expect = Http.expectJson receive Api.Model.BasicResult.decoder
            }
    in
    if person.id == "" then
        Http2.authPost params

    else
        Http2.authPut params


deletePerson : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deletePerson flags person receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/person/" ++ person
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Sources


getSources : Flags -> (Result Http.Error SourceList -> msg) -> Cmd msg
getSources flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/source"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.SourceList.decoder
        }


postSource : Flags -> SourceAndTags -> (Result Http.Error BasicResult -> msg) -> Cmd msg
postSource flags source receive =
    let
        st =
            { source = source.source
            , tags = List.map .id source.tags.items
            }

        params =
            { url = flags.config.baseUrl ++ "/api/v1/sec/source"
            , account = getAccount flags
            , body = Http.jsonBody (Api.Model.SourceTagIn.encode st)
            , expect = Http.expectJson receive Api.Model.BasicResult.decoder
            }
    in
    if source.source.id == "" then
        Http2.authPost params

    else
        Http2.authPut params


deleteSource : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteSource flags src receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/source/" ++ src
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Users


getUsers : Flags -> (Result Http.Error UserList -> msg) -> Cmd msg
getUsers flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/user"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.UserList.decoder
        }


postNewUser : Flags -> User -> (Result Http.Error BasicResult -> msg) -> Cmd msg
postNewUser flags user receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/user"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.User.encode user)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


putUser : Flags -> User -> (Result Http.Error BasicResult -> msg) -> Cmd msg
putUser flags user receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/user"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.User.encode user)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


changePassword : Flags -> PasswordChange -> (Result Http.Error BasicResult -> msg) -> Cmd msg
changePassword flags cp receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/user/changePassword"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PasswordChange.encode cp)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


deleteUser : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteUser flags user receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/user/" ++ user
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getDeleteUserData : Flags -> String -> (Result Http.Error DeleteUserData -> msg) -> Cmd msg
getDeleteUserData flags username receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/user/" ++ username ++ "/deleteData"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.DeleteUserData.decoder
        }



--- Job Queue


setJobPrio : Flags -> String -> Priority -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setJobPrio flags jobid prio receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/queue/" ++ jobid ++ "/priority"
        , account = getAccount flags
        , body =
            Data.Priority.toName prio
                |> String.toLower
                |> JobPriority
                |> Api.Model.JobPriority.encode
                |> Http.jsonBody
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


cancelJob : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
cancelJob flags jobid receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/queue/" ++ jobid ++ "/cancel"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getJobQueueState : Flags -> (Result Http.Error JobQueueState -> msg) -> Cmd msg
getJobQueueState flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/queue/state"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.JobQueueState.decoder
        }


getJobQueueStateIn : Flags -> Float -> (Result Http.Error JobQueueState -> msg) -> Cmd msg
getJobQueueStateIn flags delay receive =
    case flags.account of
        Just acc ->
            if acc.success && delay > 100 then
                Http2.executeIn delay receive (getJobQueueStateTask flags)

            else
                Cmd.none

        Nothing ->
            Cmd.none


getJobQueueStateTask : Flags -> Task.Task Http.Error JobQueueState
getJobQueueStateTask flags =
    Http2.authTask
        { url = flags.config.baseUrl ++ "/api/v1/sec/queue/state"
        , method = "GET"
        , headers = []
        , account = getAccount flags
        , body = Http.emptyBody
        , resolver = Http2.jsonResolver Api.Model.JobQueueState.decoder
        , timeout = Nothing
        }



--- Item (Mulit Edit)


mergeItems :
    Flags
    -> List String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
mergeItems flags items receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/merge"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList items))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


reprocessMultiple :
    Flags
    -> Set String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
reprocessMultiple flags items receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/reprocess"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (Set.toList items |> IdList))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


confirmMultiple :
    Flags
    -> Set String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
confirmMultiple flags ids receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/confirm"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList (Set.toList ids)))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


unconfirmMultiple :
    Flags
    -> Set String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
unconfirmMultiple flags ids receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/unconfirm"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList (Set.toList ids)))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setTagsMultiple :
    Flags
    -> ItemsAndRefs
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setTagsMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/tags"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndRefs.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addTagsMultiple :
    Flags
    -> ItemsAndRefs
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
addTagsMultiple flags data receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/tags"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndRefs.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


removeTagsMultiple :
    Flags
    -> ItemsAndRefs
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
removeTagsMultiple flags data receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/tagsremove"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndRefs.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setNameMultiple :
    Flags
    -> ItemsAndName
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setNameMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/name"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndName.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setFolderMultiple :
    Flags
    -> ItemsAndRef
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setFolderMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/folder"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndRef.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setDirectionMultiple :
    Flags
    -> ItemsAndDirection
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setDirectionMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/direction"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndDirection.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setDateMultiple :
    Flags
    -> ItemsAndDate
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setDateMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/date"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndDate.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setDueDateMultiple :
    Flags
    -> ItemsAndDate
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setDueDateMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/duedate"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndDate.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setCorrOrgMultiple :
    Flags
    -> ItemsAndRef
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setCorrOrgMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/corrOrg"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndRef.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setCorrPersonMultiple :
    Flags
    -> ItemsAndRef
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setCorrPersonMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/corrPerson"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndRef.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setConcPersonMultiple :
    Flags
    -> ItemsAndRef
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setConcPersonMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/concPerson"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndRef.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setConcEquipmentMultiple :
    Flags
    -> ItemsAndRef
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setConcEquipmentMultiple flags data receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/concEquipment"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemsAndRef.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


deleteAllItems :
    Flags
    -> Set String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
deleteAllItems flags ids receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/deleteAll"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList (Set.toList ids)))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


restoreAllItems :
    Flags
    -> Set String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
restoreAllItems flags ids receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/restoreAll"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList (Set.toList ids)))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Item


reprocessItem :
    Flags
    -> String
    -> List String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
reprocessItem flags itemId attachIds receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ itemId ++ "/reprocess"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList attachIds))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


attachmentPreviewURL : String -> String
attachmentPreviewURL id =
    "/api/v1/sec/attachment/" ++ id ++ "/preview?withFallback=true"


itemBasePreviewURL : String -> String
itemBasePreviewURL itemId =
    "/api/v1/sec/item/" ++ itemId ++ "/preview?withFallback=true"


fileURL : String -> String
fileURL attachId =
    "/api/v1/sec/attachment/" ++ attachId


setAttachmentName :
    Flags
    -> String
    -> Maybe String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setAttachmentName flags attachId newName receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/attachment/" ++ attachId ++ "/name"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalText.encode (OptionalText newName))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


moveAttachmentBefore :
    Flags
    -> String
    -> MoveAttachment
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
moveAttachmentBefore flags itemId data receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ itemId ++ "/attachment/movebefore"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.MoveAttachment.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


itemIndexSearch :
    Flags
    -> ItemQuery
    -> (Result Http.Error ItemLightList -> msg)
    -> Cmd msg
itemIndexSearch flags query receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/searchIndex"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemQuery.encode query)
        , expect = Http.expectJson receive Api.Model.ItemLightList.decoder
        }


itemSearch : Flags -> ItemQuery -> (Result Http.Error ItemLightList -> msg) -> Cmd msg
itemSearch flags search receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/search"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemQuery.encode search)
        , expect = Http.expectJson receive Api.Model.ItemLightList.decoder
        }


itemSearchStats : Flags -> ItemQuery -> (Result Http.Error SearchStats -> msg) -> Cmd msg
itemSearchStats flags search receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/searchStats"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemQuery.encode search)
        , expect = Http.expectJson receive Api.Model.SearchStats.decoder
        }


itemDetail : Flags -> String -> (Result Http.Error ItemDetail -> msg) -> Cmd msg
itemDetail flags id receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ItemDetail.decoder
        }


setTags : Flags -> String -> StringList -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setTags flags item tags receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/tags"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.StringList.encode tags)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


toggleTags : Flags -> String -> StringList -> (Result Http.Error BasicResult -> msg) -> Cmd msg
toggleTags flags item tags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/tagtoggle"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.StringList.encode tags)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addTag : Flags -> String -> Tag -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addTag flags item tag receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/tags"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.Tag.encode tag)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setDirection : Flags -> String -> DirectionValue -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setDirection flags item dir receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/direction"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.DirectionValue.encode dir)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setFolder : Flags -> String -> OptionalId -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setFolder flags item id receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/folder"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalId.encode id)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setCorrOrg : Flags -> String -> OptionalId -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setCorrOrg flags item id receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/corrOrg"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalId.encode id)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addCorrOrg : Flags -> String -> Organization -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addCorrOrg flags item org receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/corrOrg"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.Organization.encode org)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setCorrPerson : Flags -> String -> OptionalId -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setCorrPerson flags item id receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/corrPerson"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalId.encode id)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addCorrPerson : Flags -> String -> Person -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addCorrPerson flags item person receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/corrPerson"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.Person.encode person)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setConcPerson : Flags -> String -> OptionalId -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setConcPerson flags item id receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/concPerson"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalId.encode id)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addConcPerson : Flags -> String -> Person -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addConcPerson flags item person receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/concPerson"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.Person.encode person)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setConcEquip : Flags -> String -> OptionalId -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setConcEquip flags item id receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/concEquipment"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalId.encode id)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addConcEquip : Flags -> String -> Equipment -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addConcEquip flags item equip receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/concEquipment"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.Equipment.encode equip)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setItemName : Flags -> String -> OptionalText -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setItemName flags item text receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/name"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalText.encode text)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setItemNotes : Flags -> String -> OptionalText -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setItemNotes flags item text receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/notes"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalText.encode text)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setItemDate : Flags -> String -> OptionalDate -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setItemDate flags item date receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/date"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalDate.encode date)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setItemDueDate : Flags -> String -> OptionalDate -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setItemDueDate flags item date receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/duedate"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalDate.encode date)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setConfirmed : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setConfirmed flags item receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/confirm"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setUnconfirmed : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setUnconfirmed flags item receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/unconfirm"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


restoreItem : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
restoreItem flags item receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/restore"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


deleteItem : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteItem flags item receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getItemProposals : Flags -> String -> (Result Http.Error ItemProposals -> msg) -> Cmd msg
getItemProposals flags item receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/proposals"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ItemProposals.decoder
        }



--- Client Settings


getClientSettings : Flags -> (Result Http.Error UiSettings -> msg) -> Cmd msg
getClientSettings flags receive =
    let
        defaults =
            Data.UiSettings.defaults

        decoder =
            JsonDecode.map (\s -> Data.UiSettings.merge s defaults)
                Data.UiSettings.storedUiSettingsDecoder
    in
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/clientSettings/webClient"
        , account = getAccount flags
        , expect = Http.expectJson receive decoder
        }


saveClientSettings : Flags -> UiSettings -> (Result Http.Error BasicResult -> msg) -> Cmd msg
saveClientSettings flags settings receive =
    let
        storedSettings =
            Data.UiSettings.toStoredUiSettings settings

        encode =
            Data.UiSettings.storedUiSettingsEncode storedSettings
    in
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/clientSettings/webClient"
        , account = getAccount flags
        , body = Http.jsonBody encode
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- OTP


getOtpState : Flags -> (Result Http.Error OtpState -> msg) -> Cmd msg
getOtpState flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/user/otp/state"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.OtpState.decoder
        }


initOtp : Flags -> (Result Http.Error OtpResult -> msg) -> Cmd msg
initOtp flags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/user/otp/init"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.OtpResult.decoder
        }


confirmOtp : Flags -> OtpConfirm -> (Result Http.Error BasicResult -> msg) -> Cmd msg
confirmOtp flags confirm receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/user/otp/confirm"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OtpConfirm.encode confirm)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


disableOtp : Flags -> OtpConfirm -> (Result Http.Error BasicResult -> msg) -> Cmd msg
disableOtp flags otp receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/user/otp/disable"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OtpConfirm.encode otp)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Share


getShares : Flags -> (Result Http.Error ShareList -> msg) -> Cmd msg
getShares flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/share"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ShareList.decoder
        }


getShare : Flags -> String -> (Result Http.Error ShareDetail -> msg) -> Cmd msg
getShare flags id receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/share/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ShareDetail.decoder
        }


addShare : Flags -> ShareData -> (Result Http.Error IdResult -> msg) -> Cmd msg
addShare flags share receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/share"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ShareData.encode share)
        , expect = Http.expectJson receive Api.Model.IdResult.decoder
        }


updateShare : Flags -> String -> ShareData -> (Result Http.Error BasicResult -> msg) -> Cmd msg
updateShare flags id share receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/share/" ++ id
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ShareData.encode share)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


deleteShare : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteShare flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/share/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


verifyShare : Flags -> ShareSecret -> (Result Http.Error ShareVerifyResult -> msg) -> Cmd msg
verifyShare flags secret receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/open/share/verify"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ShareSecret.encode secret)
        , expect = Http.expectJson receive Api.Model.ShareVerifyResult.decoder
        }


searchShare : Flags -> String -> ItemQuery -> (Result Http.Error ItemLightList -> msg) -> Cmd msg
searchShare flags token search receive =
    Http2.sharePost
        { url = flags.config.baseUrl ++ "/api/v1/share/search/query"
        , token = token
        , body = Http.jsonBody (Api.Model.ItemQuery.encode search)
        , expect = Http.expectJson receive Api.Model.ItemLightList.decoder
        }


searchShareStats : Flags -> String -> ItemQuery -> (Result Http.Error SearchStats -> msg) -> Cmd msg
searchShareStats flags token search receive =
    Http2.sharePost
        { url = flags.config.baseUrl ++ "/api/v1/share/search/stats"
        , token = token
        , body = Http.jsonBody (Api.Model.ItemQuery.encode search)
        , expect = Http.expectJson receive Api.Model.SearchStats.decoder
        }


itemDetailShare : Flags -> String -> String -> (Result Http.Error ItemDetail -> msg) -> Cmd msg
itemDetailShare flags token itemId receive =
    Http2.shareGet
        { url = flags.config.baseUrl ++ "/api/v1/share/item/" ++ itemId
        , token = token
        , expect = Http.expectJson receive Api.Model.ItemDetail.decoder
        }


shareAttachmentPreviewURL : String -> String
shareAttachmentPreviewURL id =
    "/api/v1/share/attachment/" ++ id ++ "/preview?withFallback=true"


shareItemBasePreviewURL : String -> String
shareItemBasePreviewURL itemId =
    "/api/v1/share/item/" ++ itemId ++ "/preview?withFallback=true"


shareFileURL : String -> String
shareFileURL attachId =
    "/api/v1/share/attachment/" ++ attachId



--- Helper


getAccount : Flags -> AuthResult
getAccount flags =
    Maybe.withDefault Api.Model.AuthResult.empty flags.account
