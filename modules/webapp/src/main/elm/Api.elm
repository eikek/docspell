{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Api exposing
    ( addBookmark
    , addConcEquip
    , addConcPerson
    , addCorrOrg
    , addCorrPerson
    , addDashboard
    , addMember
    , addRelatedItems
    , addRelatedItemsTask
    , addShare
    , addTag
    , addTagsMultiple
    , addonRunConfigDelete
    , addonRunConfigGet
    , addonRunConfigSet
    , addonRunExistingItem
    , addonsDelete
    , addonsGetAll
    , addonsInstall
    , addonsUpdate
    , attachmentPreviewURL
    , bookmarkNameExists
    , cancelJob
    , changeFolderName
    , changePassword
    , checkCalEvent
    , clientSettingsShare
    , confirmMultiple
    , confirmOtp
    , createChannel
    , createHook
    , createImapSettings
    , createMailSettings
    , createNewFolder
    , createNotifyDueItems
    , createPeriodicQuery
    , createScanMailbox
    , deleteAllItems
    , deleteAttachment
    , deleteAttachments
    , deleteBookmark
    , deleteChannel
    , deleteCustomField
    , deleteCustomValue
    , deleteCustomValueMultiple
    , deleteDashboard
    , deleteEquip
    , deleteFolder
    , deleteHook
    , deleteImapSettings
    , deleteItem
    , deleteMailSettings
    , deleteNotifyDueItems
    , deleteOrg
    , deletePeriodicQueryTask
    , deletePerson
    , deleteScanMailbox
    , deleteShare
    , deleteSource
    , deleteTag
    , deleteUser
    , disableOtp
    , downloadAllLink
    , downloadAllPrefetch
    , downloadAllSubmit
    , fileURL
    , getAllDashboards
    , getAttachmentMeta
    , getBookmarks
    , getChannels
    , getChannelsIgnoreError
    , getClientSettings
    , getClientSettingsRaw
    , getCollective
    , getCollectiveSettings
    , getContacts
    , getCustomFields
    , getDeleteUserData
    , getEquipment
    , getEquipments
    , getFolderDetail
    , getFolders
    , getHooks
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
    , getPeriodicQuery
    , getPersonFull
    , getPersons
    , getPersonsLight
    , getRelatedItems
    , getScanMailbox
    , getSentMails
    , getShare
    , getShares
    , getSources
    , getTagCloud
    , getTags
    , getTagsIgnoreError
    , getUsers
    , initOtp
    , itemBasePreviewURL
    , itemDetail
    , itemDetailShare
    , itemIndexSearch
    , itemSearch
    , itemSearchBookmark
    , itemSearchStats
    , itemSearchStatsBookmark
    , login
    , loginSession
    , logout
    , mergeItems
    , mergeItemsTask
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
    , removeRelatedItem
    , removeRelatedItems
    , removeTagsMultiple
    , replaceDashboard
    , reprocessItem
    , reprocessMultiple
    , restoreAllItems
    , restoreItem
    , sampleEvent
    , saveClientSettings
    , saveUserClientSettingsBy
    , searchShare
    , searchShareStats
    , sendMail
    , setAttachmentExtractedText
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
    , shareDownloadAllLink
    , shareDownloadAllPrefetch
    , shareDownloadAllSubmit
    , shareFileURL
    , shareItemBasePreviewURL
    , shareSendMail
    , startClassifier
    , startEmptyTrash
    , startOnceNotifyDueItems
    , startOncePeriodicQuery
    , startOnceScanMailbox
    , startReIndex
    , submitNotifyDueItems
    , submitPeriodicQuery
    , testHook
    , toggleTags
    , twoFactor
    , unconfirmMultiple
    , updateBookmark
    , updateChannel
    , updateHook
    , updateNotifyDueItems
    , updatePeriodicQuery
    , updateScanMailbox
    , updateShare
    , upload
    , uploadAmend
    , uploadSingle
    , verifyJsonFilter
    , verifyShare
    , versionInfo
    )

import Api.Model.AddonList exposing (AddonList)
import Api.Model.AddonRegister exposing (AddonRegister)
import Api.Model.AddonRunConfig exposing (AddonRunConfig)
import Api.Model.AddonRunConfigList exposing (AddonRunConfigList)
import Api.Model.AddonRunExistingItem exposing (AddonRunExistingItem)
import Api.Model.AttachmentMeta exposing (AttachmentMeta)
import Api.Model.AuthResult exposing (AuthResult)
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.BookmarkedQuery exposing (BookmarkedQuery)
import Api.Model.CalEventCheck exposing (CalEventCheck)
import Api.Model.CalEventCheckResult exposing (CalEventCheckResult)
import Api.Model.Collective exposing (Collective)
import Api.Model.CollectiveSettings exposing (CollectiveSettings)
import Api.Model.ContactList exposing (ContactList)
import Api.Model.CustomFieldList exposing (CustomFieldList)
import Api.Model.CustomFieldValue exposing (CustomFieldValue)
import Api.Model.DeleteUserData exposing (DeleteUserData)
import Api.Model.DirectionValue exposing (DirectionValue)
import Api.Model.DownloadAllRequest exposing (DownloadAllRequest)
import Api.Model.DownloadAllSummary exposing (DownloadAllSummary)
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
import Api.Model.ItemLightGroup exposing (ItemLightGroup)
import Api.Model.ItemLightList exposing (ItemLightList)
import Api.Model.ItemLinkData exposing (ItemLinkData)
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
import Api.Model.NotificationChannelTestResult exposing (NotificationChannelTestResult)
import Api.Model.NotificationHook exposing (NotificationHook)
import Api.Model.NotificationSampleEventReq exposing (NotificationSampleEventReq)
import Api.Model.OptionalDate exposing (OptionalDate)
import Api.Model.OptionalId exposing (OptionalId)
import Api.Model.OptionalText exposing (OptionalText)
import Api.Model.Organization exposing (Organization)
import Api.Model.OrganizationList exposing (OrganizationList)
import Api.Model.OtpConfirm exposing (OtpConfirm)
import Api.Model.OtpResult exposing (OtpResult)
import Api.Model.OtpState exposing (OtpState)
import Api.Model.PasswordChange exposing (PasswordChange)
import Api.Model.PeriodicDueItemsSettings exposing (PeriodicDueItemsSettings)
import Api.Model.PeriodicQuerySettings exposing (PeriodicQuerySettings)
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
import Api.Model.SimpleShareMail exposing (SimpleShareMail)
import Api.Model.SourceAndTags exposing (SourceAndTags)
import Api.Model.SourceList exposing (SourceList)
import Api.Model.SourceTagIn
import Api.Model.StringList exposing (StringList)
import Api.Model.StringValue exposing (StringValue)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagCloud exposing (TagCloud)
import Api.Model.TagList exposing (TagList)
import Api.Model.User exposing (User)
import Api.Model.UserList exposing (UserList)
import Api.Model.UserPass exposing (UserPass)
import Api.Model.VersionInfo exposing (VersionInfo)
import Data.AccountScope exposing (AccountScope)
import Data.Bookmarks exposing (AllBookmarks, Bookmarks)
import Data.ContactType exposing (ContactType)
import Data.CustomFieldOrder exposing (CustomFieldOrder)
import Data.Dashboard exposing (Dashboard)
import Data.Dashboards exposing (AllDashboards, Dashboards)
import Data.EquipmentOrder exposing (EquipmentOrder)
import Data.EventType exposing (EventType)
import Data.Flags exposing (Flags)
import Data.FolderOrder exposing (FolderOrder)
import Data.NotificationChannel exposing (NotificationChannel)
import Data.OrganizationOrder exposing (OrganizationOrder)
import Data.PersonOrder exposing (PersonOrder)
import Data.Priority exposing (Priority)
import Data.TagOrder exposing (TagOrder)
import Data.UiSettings exposing (StoredUiSettings, UiSettings)
import File exposing (File)
import Http
import Json.Decode as JsonDecode
import Json.Encode as JsonEncode
import Set exposing (Set)
import Task
import Url
import Util.File
import Util.Http as Http2
import Util.Result



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
    -> PeriodicDueItemsSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
startOnceNotifyDueItems flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems/startonce"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PeriodicDueItemsSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


updateNotifyDueItems :
    Flags
    -> PeriodicDueItemsSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
updateNotifyDueItems flags settings receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PeriodicDueItemsSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


createNotifyDueItems :
    Flags
    -> PeriodicDueItemsSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
createNotifyDueItems flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PeriodicDueItemsSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getNotifyDueItems :
    Flags
    -> (Result Http.Error (List PeriodicDueItemsSettings) -> msg)
    -> Cmd msg
getNotifyDueItems flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems"
        , account = getAccount flags
        , expect = Http.expectJson receive (JsonDecode.list Api.Model.PeriodicDueItemsSettings.decoder)
        }


submitNotifyDueItems :
    Flags
    -> PeriodicDueItemsSettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
submitNotifyDueItems flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PeriodicDueItemsSettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- PeriodicQueryTask


deletePeriodicQueryTask :
    Flags
    -> String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
deletePeriodicQueryTask flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/periodicquery/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


startOncePeriodicQuery :
    Flags
    -> PeriodicQuerySettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
startOncePeriodicQuery flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/periodicquery/startonce"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PeriodicQuerySettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


updatePeriodicQuery :
    Flags
    -> PeriodicQuerySettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
updatePeriodicQuery flags settings receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/periodicquery"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PeriodicQuerySettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


createPeriodicQuery :
    Flags
    -> PeriodicQuerySettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
createPeriodicQuery flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/periodicquery"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PeriodicQuerySettings.encode settings)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getPeriodicQuery :
    Flags
    -> (Result Http.Error (List PeriodicQuerySettings) -> msg)
    -> Cmd msg
getPeriodicQuery flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/periodicquery"
        , account = getAccount flags
        , expect = Http.expectJson receive (JsonDecode.list Api.Model.PeriodicQuerySettings.decoder)
        }


submitPeriodicQuery :
    Flags
    -> PeriodicQuerySettings
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
submitPeriodicQuery flags settings receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/periodicquery"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PeriodicQuerySettings.encode settings)
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


getTagsTask : Flags -> String -> TagOrder -> Task.Task Http.Error TagList
getTagsTask flags query order =
    Http2.authTask
        { url =
            flags.config.baseUrl
                ++ "/api/v1/sec/tag?sort="
                ++ Data.TagOrder.asString order
                ++ "&q="
                ++ Url.percentEncode query
        , method = "GET"
        , headers = []
        , account = getAccount flags
        , body = Http.emptyBody
        , resolver = Http2.jsonResolver Api.Model.TagList.decoder
        , timeout = Nothing
        }


getTags : Flags -> String -> TagOrder -> (Result Http.Error TagList -> msg) -> Cmd msg
getTags flags query order receive =
    getTagsTask flags query order |> Task.attempt receive


getTagsIgnoreError : Flags -> String -> TagOrder -> (TagList -> msg) -> Cmd msg
getTagsIgnoreError flags query order tagger =
    getTagsTask flags query order
        |> Task.attempt (Result.map tagger >> Result.withDefault (tagger Api.Model.TagList.empty))


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


mergeItemsTask : Flags -> List String -> Task.Task Http.Error BasicResult
mergeItemsTask flags ids =
    Http2.authTask
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/merge"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList ids))
        , method = "POST"
        , headers = []
        , resolver = Http2.jsonResolver Api.Model.BasicResult.decoder
        , timeout = Nothing
        }


mergeItems :
    Flags
    -> List String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
mergeItems flags items receive =
    mergeItemsTask flags items |> Task.attempt receive


reprocessMultiple :
    Flags
    -> List String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
reprocessMultiple flags items receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/reprocess"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList items))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


confirmMultiple :
    Flags
    -> List String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
confirmMultiple flags ids receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/confirm"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList ids))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


unconfirmMultiple :
    Flags
    -> List String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
unconfirmMultiple flags ids receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/unconfirm"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList ids))
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
    -> List String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
deleteAllItems flags ids receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/deleteAll"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList ids))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


restoreAllItems :
    Flags
    -> List String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
restoreAllItems flags ids receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/items/restoreAll"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.IdList.encode (IdList ids))
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


setAttachmentExtractedText :
    Flags
    -> String
    -> Maybe String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setAttachmentExtractedText flags attachId newName receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/attachment/" ++ attachId ++ "/extracted-text"
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


itemSearchTask : Flags -> ItemQuery -> Task.Task Http.Error ItemLightList
itemSearchTask flags search =
    Http2.authTask
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/search"
        , method = "POST"
        , headers = []
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemQuery.encode search)
        , resolver = Http2.jsonResolver Api.Model.ItemLightList.decoder
        , timeout = Nothing
        }


itemSearch : Flags -> ItemQuery -> (Result Http.Error ItemLightList -> msg) -> Cmd msg
itemSearch flags search receive =
    itemSearchTask flags search |> Task.attempt receive


{-| Same as `itemSearch` but interprets the `query` field as a bookmark id.
-}
itemSearchBookmark : Flags -> ItemQuery -> (Result Http.Error ItemLightList -> msg) -> Cmd msg
itemSearchBookmark flags bmSearch receive =
    let
        getBookmark =
            getBookmarkByIdTask flags bmSearch.query
                |> Task.map (\bm -> { bmSearch | query = bm.query })

        search q =
            itemSearchTask flags q
    in
    Task.andThen search getBookmark
        |> Task.attempt receive


itemSearchStatsTask : Flags -> ItemQuery -> Task.Task Http.Error SearchStats
itemSearchStatsTask flags search =
    Http2.authTask
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/searchStats"
        , method = "POST"
        , headers = []
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemQuery.encode search)
        , resolver = Http2.jsonResolver Api.Model.SearchStats.decoder
        , timeout = Nothing
        }


itemSearchStats : Flags -> ItemQuery -> (Result Http.Error SearchStats -> msg) -> Cmd msg
itemSearchStats flags search receive =
    itemSearchStatsTask flags search |> Task.attempt receive


itemSearchStatsBookmark : Flags -> ItemQuery -> (Result Http.Error SearchStats -> msg) -> Cmd msg
itemSearchStatsBookmark flags search receive =
    let
        getBookmark =
            getBookmarkByIdTask flags search.query
                |> Task.map (\bm -> { search | query = bm.query })

        getStats q =
            itemSearchStatsTask flags q
    in
    Task.andThen getStats getBookmark
        |> Task.attempt receive


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


uiSettingsPath : AccountScope -> String
uiSettingsPath scope =
    Data.AccountScope.fold "/api/v1/sec/clientSettings/user/webClient"
        "/api/v1/sec/clientSettings/collective/webClient"
        scope


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


getClientSettingsTaskFor : Flags -> AccountScope -> Task.Task Http.Error StoredUiSettings
getClientSettingsTaskFor flags scope =
    let
        path =
            uiSettingsPath scope
    in
    Http2.authTask
        { method = "GET"
        , url = flags.config.baseUrl ++ path
        , account = getAccount flags
        , body = Http.emptyBody
        , resolver = Http2.jsonResolver Data.UiSettings.storedUiSettingsDecoder
        , headers = []
        , timeout = Nothing
        }


getClientSettingsRaw : Flags -> (Result Http.Error ( StoredUiSettings, StoredUiSettings ) -> msg) -> Cmd msg
getClientSettingsRaw flags receive =
    let
        coll =
            getClientSettingsTaskFor flags Data.AccountScope.Collective

        user =
            getClientSettingsTaskFor flags Data.AccountScope.User
    in
    Task.map2 Tuple.pair coll user |> Task.attempt receive


saveClientSettingsTask :
    Flags
    -> StoredUiSettings
    -> AccountScope
    -> Task.Task Http.Error BasicResult
saveClientSettingsTask flags settings scope =
    let
        encoded =
            Data.UiSettings.storedUiSettingsEncode settings

        path =
            uiSettingsPath scope
    in
    Http2.authTask
        { method = "PUT"
        , url = flags.config.baseUrl ++ path
        , account = getAccount flags
        , body = Http.jsonBody encoded
        , resolver = Http2.jsonResolver Api.Model.BasicResult.decoder
        , headers = []
        , timeout = Nothing
        }


saveClientSettings :
    Flags
    -> StoredUiSettings
    -> AccountScope
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
saveClientSettings flags settings scope receive =
    saveClientSettingsTask flags settings scope |> Task.attempt receive


saveUserClientSettingsBy :
    Flags
    -> (StoredUiSettings -> StoredUiSettings)
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
saveUserClientSettingsBy flags modify receive =
    let
        readTask =
            getClientSettingsTaskFor flags Data.AccountScope.User

        save s =
            saveClientSettingsTask flags s Data.AccountScope.User
    in
    Task.andThen (modify >> save) readTask |> Task.attempt receive



--- Dashboards


dashboardsUrl : Flags -> AccountScope -> String
dashboardsUrl flags scope =
    let
        part =
            Data.AccountScope.fold "user" "collective" scope
    in
    flags.config.baseUrl ++ "/api/v1/sec/clientSettings/" ++ part ++ "/webClientDashboards"


getDashboardsScopeTask : Flags -> AccountScope -> Task.Task Http.Error Dashboards
getDashboardsScopeTask flags scope =
    Http2.authTask
        { method = "GET"
        , url = dashboardsUrl flags scope
        , account = getAccount flags
        , body = Http.emptyBody
        , resolver = Http2.jsonResolver Data.Dashboards.decoder
        , headers = []
        , timeout = Nothing
        }


pushDashbordsScopeTask : Flags -> AccountScope -> Dashboards -> Task.Task Http.Error BasicResult
pushDashbordsScopeTask flags scope boards =
    Http2.authTask
        { method = "PUT"
        , url = dashboardsUrl flags scope
        , account = getAccount flags
        , body = Http.jsonBody (Data.Dashboards.encode boards)
        , resolver = Http2.jsonResolver Api.Model.BasicResult.decoder
        , headers = []
        , timeout = Nothing
        }


getAllDashboardsTask : Flags -> Task.Task Http.Error AllDashboards
getAllDashboardsTask flags =
    let
        coll =
            getDashboardsScopeTask flags Data.AccountScope.Collective

        user =
            getDashboardsScopeTask flags Data.AccountScope.User
    in
    Task.map2 AllDashboards coll user


getAllDashboards : Flags -> (Result Http.Error AllDashboards -> msg) -> Cmd msg
getAllDashboards flags receive =
    getAllDashboardsTask flags |> Task.attempt receive


saveDashboardTask : Flags -> String -> Dashboard -> AccountScope -> Bool -> Task.Task Http.Error BasicResult
saveDashboardTask flags original board scope isDefault =
    let
        boardsTask =
            getAllDashboardsTask flags

        setDefault all =
            if isDefault then
                Data.Dashboards.setDefaultAll board.name all

            else
                Data.Dashboards.unsetDefaultAll board.name all

        removeOriginal boards =
            Data.Dashboards.removeFromAll original boards

        insert all =
            Data.Dashboards.insertIn scope board all

        update all =
            let
                next =
                    (removeOriginal >> insert >> setDefault) all

                saveU =
                    if all.user == next.user then
                        Task.succeed (BasicResult True "")

                    else
                        pushDashbordsScopeTask flags Data.AccountScope.User next.user

                saveC =
                    if all.collective == next.collective then
                        Task.succeed (BasicResult True "")

                    else
                        pushDashbordsScopeTask flags Data.AccountScope.Collective next.collective
            in
            Task.map2 Util.Result.combine saveU saveC
    in
    Task.andThen update boardsTask


addDashboard : Flags -> Dashboard -> AccountScope -> Bool -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addDashboard flags board scope isDefault receive =
    saveDashboardTask flags board.name board scope isDefault |> Task.attempt receive


replaceDashboard : Flags -> String -> Dashboard -> AccountScope -> Bool -> (Result Http.Error BasicResult -> msg) -> Cmd msg
replaceDashboard flags originalName board scope isDefault receive =
    saveDashboardTask flags originalName board scope isDefault |> Task.attempt receive


deleteDashboardTask : Flags -> String -> AccountScope -> Task.Task Http.Error BasicResult
deleteDashboardTask flags name scope =
    let
        boardsTask =
            getDashboardsScopeTask flags scope

        remove boards =
            Data.Dashboards.remove name boards
    in
    Task.andThen (remove >> pushDashbordsScopeTask flags scope) boardsTask


deleteDashboard : Flags -> String -> AccountScope -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteDashboard flags name scope receive =
    deleteDashboardTask flags name scope |> Task.attempt receive



--- Query Bookmarks


bookmarkUri : Flags -> String
bookmarkUri flags =
    flags.config.baseUrl ++ "/api/v1/sec/querybookmark"


getBookmarksTask : Flags -> Task.Task Http.Error Bookmarks
getBookmarksTask flags =
    Http2.authTask
        { method = "GET"
        , url = bookmarkUri flags
        , account = getAccount flags
        , body = Http.emptyBody
        , resolver = Http2.jsonResolver Data.Bookmarks.bookmarksDecoder
        , headers = []
        , timeout = Nothing
        }


getBookmarkByIdTask : Flags -> String -> Task.Task Http.Error BookmarkedQuery
getBookmarkByIdTask flags id =
    let
        findBm all =
            Data.Bookmarks.findById id all

        mapNotFound maybeBookmark =
            Maybe.map Task.succeed maybeBookmark
                |> Maybe.withDefault (Task.fail (Http.BadStatus 404))
    in
    getBookmarksTask flags
        |> Task.map findBm
        |> Task.andThen mapNotFound


getBookmarks : Flags -> (Result Http.Error AllBookmarks -> msg) -> Cmd msg
getBookmarks flags receive =
    let
        bms =
            getBookmarksTask flags

        shares =
            getSharesTask flags "" False

        activeShare s =
            s.enabled && s.name /= Nothing

        combine bm bs =
            AllBookmarks (Data.Bookmarks.sort bm) (List.filter activeShare bs.items)
    in
    Task.map2 combine bms shares
        |> Task.attempt receive


addBookmark : Flags -> BookmarkedQuery -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addBookmark flags model receive =
    Http2.authPost
        { url = bookmarkUri flags
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.BookmarkedQuery.encode model)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


updateBookmark : Flags -> BookmarkedQuery -> (Result Http.Error BasicResult -> msg) -> Cmd msg
updateBookmark flags model receive =
    Http2.authPut
        { url = bookmarkUri flags
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.BookmarkedQuery.encode model)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


bookmarkNameExistsTask : Flags -> String -> Task.Task Http.Error Bool
bookmarkNameExistsTask flags name =
    let
        load =
            getBookmarksTask flags

        exists current =
            Data.Bookmarks.exists name current
    in
    Task.map exists load


bookmarkNameExists : Flags -> String -> (Result Http.Error Bool -> msg) -> Cmd msg
bookmarkNameExists flags name receive =
    bookmarkNameExistsTask flags name |> Task.attempt receive


deleteBookmark : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteBookmark flags id receive =
    Http2.authDelete
        { url = bookmarkUri flags ++ "/" ++ id
        , account = getAccount flags
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


getSharesTask : Flags -> String -> Bool -> Task.Task Http.Error ShareList
getSharesTask flags query owning =
    Http2.authTask
        { method =
            "GET"
        , url =
            flags.config.baseUrl
                ++ "/api/v1/sec/share?q="
                ++ Url.percentEncode query
                ++ (if owning then
                        "&owning"

                    else
                        ""
                   )
        , account = getAccount flags
        , body = Http.emptyBody
        , resolver = Http2.jsonResolver Api.Model.ShareList.decoder
        , headers = []
        , timeout = Nothing
        }


getShares : Flags -> String -> Bool -> (Result Http.Error ShareList -> msg) -> Cmd msg
getShares flags query owning receive =
    getSharesTask flags query owning |> Task.attempt receive


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


clientSettingsShare : Flags -> String -> (Result Http.Error UiSettings -> msg) -> Cmd msg
clientSettingsShare flags token receive =
    let
        defaults =
            Data.UiSettings.defaults

        decoder =
            JsonDecode.map (\s -> Data.UiSettings.merge s defaults)
                Data.UiSettings.storedUiSettingsDecoder
    in
    Http2.shareGet
        { url = flags.config.baseUrl ++ "/api/v1/share/clientSettings/webClient"
        , token = token
        , expect = Http.expectJson receive decoder
        }


shareSendMail :
    Flags
    -> { conn : String, mail : SimpleShareMail }
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
shareSendMail flags opts receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/share/email/send/" ++ opts.conn
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.SimpleShareMail.encode opts.mail)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
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



--- NotificationChannel


getChannelsTask : Flags -> Task.Task Http.Error (List NotificationChannel)
getChannelsTask flags =
    Http2.authTask
        { method = "GET"
        , url = flags.config.baseUrl ++ "/api/v1/sec/notification/channel"
        , account = getAccount flags
        , body = Http.emptyBody
        , resolver = Http2.jsonResolver (JsonDecode.list Data.NotificationChannel.decoder)
        , headers = []
        , timeout = Nothing
        }


getChannelsIgnoreError : Flags -> (List NotificationChannel -> msg) -> Cmd msg
getChannelsIgnoreError flags tagger =
    getChannelsTask flags
        |> Task.attempt (Result.map tagger >> Result.withDefault (tagger []))


getChannels : Flags -> (Result Http.Error (List NotificationChannel) -> msg) -> Cmd msg
getChannels flags receive =
    getChannelsTask flags |> Task.attempt receive


deleteChannel : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteChannel flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/notification/channel/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


createChannel : Flags -> NotificationChannel -> (Result Http.Error BasicResult -> msg) -> Cmd msg
createChannel flags hook receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/notification/channel"
        , account = getAccount flags
        , body = Http.jsonBody (Data.NotificationChannel.encode hook)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


updateChannel : Flags -> NotificationChannel -> (Result Http.Error BasicResult -> msg) -> Cmd msg
updateChannel flags hook receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/notification/channel"
        , account = getAccount flags
        , body = Http.jsonBody (Data.NotificationChannel.encode hook)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- NotificationHook


getHooks : Flags -> (Result Http.Error (List NotificationHook) -> msg) -> Cmd msg
getHooks flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/notification/hook"
        , account = getAccount flags
        , expect = Http.expectJson receive (JsonDecode.list Api.Model.NotificationHook.decoder)
        }


deleteHook : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteHook flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/notification/hook/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


createHook : Flags -> NotificationHook -> (Result Http.Error BasicResult -> msg) -> Cmd msg
createHook flags hook receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/notification/hook"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NotificationHook.encode hook)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


updateHook : Flags -> NotificationHook -> (Result Http.Error BasicResult -> msg) -> Cmd msg
updateHook flags hook receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/notification/hook"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NotificationHook.encode hook)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


sampleEvent : Flags -> EventType -> (Result Http.Error String -> msg) -> Cmd msg
sampleEvent flags evt receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/notification/event/sample"
        , account = getAccount flags
        , body =
            Http.jsonBody
                (Api.Model.NotificationSampleEventReq.encode
                    (NotificationSampleEventReq <|
                        Data.EventType.asString evt
                    )
                )
        , expect = Http.expectString receive
        }


testHook :
    Flags
    -> NotificationHook
    -> (Result Http.Error NotificationChannelTestResult -> msg)
    -> Cmd msg
testHook flags hook receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/notification/hook/sendTestEvent"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.NotificationHook.encode hook)
        , expect = Http.expectJson receive Api.Model.NotificationChannelTestResult.decoder
        }


verifyJsonFilter : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
verifyJsonFilter flags query receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/notification/hook/verifyJsonFilter"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.StringValue.encode (StringValue query))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Item Links


getRelatedItems : Flags -> String -> (Result Http.Error ItemLightGroup -> msg) -> Cmd msg
getRelatedItems flags itemId receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/itemlink/" ++ itemId
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ItemLightGroup.decoder
        }


addRelatedItems : Flags -> ItemLinkData -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addRelatedItems flags data receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/itemlink/addAll"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemLinkData.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addRelatedItemsTask : Flags -> List String -> Task.Task Http.Error BasicResult
addRelatedItemsTask flags ids =
    let
        itemData =
            { item = List.head ids |> Maybe.withDefault ""
            , related = List.tail ids |> Maybe.withDefault []
            }
    in
    Http2.authTask
        { url = flags.config.baseUrl ++ "/api/v1/sec/itemlink/addAll"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemLinkData.encode itemData)
        , method = "POST"
        , headers = []
        , resolver = Http2.jsonResolver Api.Model.BasicResult.decoder
        , timeout = Nothing
        }


removeRelatedItems : Flags -> ItemLinkData -> (Result Http.Error BasicResult -> msg) -> Cmd msg
removeRelatedItems flags data receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/itemlink/removeAll"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemLinkData.encode data)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


removeRelatedItem : Flags -> String -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
removeRelatedItem flags item1 item2 receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/itemlink/" ++ item1 ++ "/" ++ item2
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- DownloadAll


downloadAllPrefetch : Flags -> DownloadAllRequest -> (Result Http.Error DownloadAllSummary -> msg) -> Cmd msg
downloadAllPrefetch flags req receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/downloadAll/prefetch"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.DownloadAllRequest.encode req)
        , expect = Http.expectJson receive Api.Model.DownloadAllSummary.decoder
        }


downloadAllSubmit : Flags -> DownloadAllRequest -> (Result Http.Error DownloadAllSummary -> msg) -> Cmd msg
downloadAllSubmit flags req receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/downloadAll/submit"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.DownloadAllRequest.encode req)
        , expect = Http.expectJson receive Api.Model.DownloadAllSummary.decoder
        }


downloadAllLink : Flags -> String -> String
downloadAllLink flags id =
    flags.config.baseUrl ++ "/api/v1/sec/downloadAll/file/" ++ id


shareDownloadAllPrefetch :
    Flags
    -> String
    -> DownloadAllRequest
    -> (Result Http.Error DownloadAllSummary -> msg)
    -> Cmd msg
shareDownloadAllPrefetch flags token req receive =
    Http2.sharePost
        { url = flags.config.baseUrl ++ "/api/v1/share/downloadAll/prefetch"
        , token = token
        , body = Http.jsonBody (Api.Model.DownloadAllRequest.encode req)
        , expect = Http.expectJson receive Api.Model.DownloadAllSummary.decoder
        }


shareDownloadAllSubmit :
    Flags
    -> String
    -> DownloadAllRequest
    -> (Result Http.Error DownloadAllSummary -> msg)
    -> Cmd msg
shareDownloadAllSubmit flags token req receive =
    Http2.sharePost
        { url = flags.config.baseUrl ++ "/api/v1/share/downloadAll/submit"
        , token = token
        , body = Http.jsonBody (Api.Model.DownloadAllRequest.encode req)
        , expect = Http.expectJson receive Api.Model.DownloadAllSummary.decoder
        }


shareDownloadAllLink : Flags -> String -> String
shareDownloadAllLink flags id =
    flags.config.baseUrl ++ "/api/v1/share/downloadAll/file/" ++ id



--- Addons


addonsGetAll : Flags -> (Result Http.Error AddonList -> msg) -> Cmd msg
addonsGetAll flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/addon/archive"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.AddonList.decoder
        }


addonsDelete : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addonsDelete flags addonId receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/addon/archive/" ++ addonId
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addonsInstall : Flags -> AddonRegister -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addonsInstall flags addon receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/addon/archive"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.AddonRegister.encode addon)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addonsUpdate : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addonsUpdate flags addonId receive =
    Http2.authPut
        { url = flags.config.baseUrl ++ "/api/v1/sec/addon/archive/" ++ addonId
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addonRunConfigGet : Flags -> (Result Http.Error AddonRunConfigList -> msg) -> Cmd msg
addonRunConfigGet flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/addon/run-config"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.AddonRunConfigList.decoder
        }


addonRunConfigSet :
    Flags
    -> AddonRunConfig
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
addonRunConfigSet flags cfg receive =
    if cfg.id == "" then
        Http2.authPost
            { url = flags.config.baseUrl ++ "/api/v1/sec/addon/run-config"
            , account = getAccount flags
            , body = Http.jsonBody (Api.Model.AddonRunConfig.encode cfg)
            , expect = Http.expectJson receive Api.Model.BasicResult.decoder
            }

    else
        Http2.authPut
            { url = flags.config.baseUrl ++ "/api/v1/sec/addon/run-config/" ++ cfg.id
            , account = getAccount flags
            , body = Http.jsonBody (Api.Model.AddonRunConfig.encode cfg)
            , expect = Http.expectJson receive Api.Model.BasicResult.decoder
            }


addonRunConfigDelete : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addonRunConfigDelete flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v1/sec/addon/run-config/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


addonRunExistingItem : Flags -> AddonRunExistingItem -> (Result Http.Error BasicResult -> msg) -> Cmd msg
addonRunExistingItem flags input receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/addon/run/existingitem"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.AddonRunExistingItem.encode input)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }



--- Helper


getAccount : Flags -> AuthResult
getAccount flags =
    Maybe.withDefault Api.Model.AuthResult.empty flags.account
