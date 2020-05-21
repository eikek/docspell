module Api exposing
    ( cancelJob
    , changePassword
    , checkCalEvent
    , createImapSettings
    , createMailSettings
    , createScanMailbox
    , deleteAttachment
    , deleteEquip
    , deleteImapSettings
    , deleteItem
    , deleteMailSettings
    , deleteOrg
    , deletePerson
    , deleteScanMailbox
    , deleteSource
    , deleteTag
    , deleteUser
    , getAttachmentMeta
    , getCollective
    , getCollectiveSettings
    , getContacts
    , getEquipments
    , getImapSettings
    , getInsights
    , getItemProposals
    , getJobQueueState
    , getJobQueueStateIn
    , getMailSettings
    , getNotifyDueItems
    , getOrgLight
    , getOrganizations
    , getPersons
    , getPersonsLight
    , getScanMailbox
    , getSentMails
    , getSources
    , getTags
    , getUsers
    , itemDetail
    , itemSearch
    , login
    , loginSession
    , logout
    , newInvite
    , postEquipment
    , postNewUser
    , postOrg
    , postPerson
    , postSource
    , postTag
    , putUser
    , refreshSession
    , register
    , sendMail
    , setCollectiveSettings
    , setConcEquip
    , setConcPerson
    , setConfirmed
    , setCorrOrg
    , setCorrPerson
    , setDirection
    , setItemDate
    , setItemDueDate
    , setItemName
    , setItemNotes
    , setTags
    , setUnconfirmed
    , startOnceNotifyDueItems
    , startOnceScanMailbox
    , submitNotifyDueItems
    , updateScanMailbox
    , upload
    , uploadSingle
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
import Api.Model.DirectionValue exposing (DirectionValue)
import Api.Model.EmailSettings exposing (EmailSettings)
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Api.Model.Equipment exposing (Equipment)
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.GenInvite exposing (GenInvite)
import Api.Model.ImapSettings exposing (ImapSettings)
import Api.Model.ImapSettingsList exposing (ImapSettingsList)
import Api.Model.InviteResult exposing (InviteResult)
import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ItemInsights exposing (ItemInsights)
import Api.Model.ItemLightList exposing (ItemLightList)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.ItemSearch exposing (ItemSearch)
import Api.Model.ItemUploadMeta exposing (ItemUploadMeta)
import Api.Model.JobQueueState exposing (JobQueueState)
import Api.Model.NotificationSettings exposing (NotificationSettings)
import Api.Model.OptionalDate exposing (OptionalDate)
import Api.Model.OptionalId exposing (OptionalId)
import Api.Model.OptionalText exposing (OptionalText)
import Api.Model.Organization exposing (Organization)
import Api.Model.OrganizationList exposing (OrganizationList)
import Api.Model.PasswordChange exposing (PasswordChange)
import Api.Model.Person exposing (Person)
import Api.Model.PersonList exposing (PersonList)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.Registration exposing (Registration)
import Api.Model.ScanMailboxSettings exposing (ScanMailboxSettings)
import Api.Model.ScanMailboxSettingsList exposing (ScanMailboxSettingsList)
import Api.Model.SentMails exposing (SentMails)
import Api.Model.SimpleMail exposing (SimpleMail)
import Api.Model.Source exposing (Source)
import Api.Model.SourceList exposing (SourceList)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Api.Model.User exposing (User)
import Api.Model.UserList exposing (UserList)
import Api.Model.UserPass exposing (UserPass)
import Api.Model.VersionInfo exposing (VersionInfo)
import Data.ContactType exposing (ContactType)
import Data.Flags exposing (Flags)
import File exposing (File)
import Http
import Json.Encode as JsonEncode
import Task
import Url
import Util.File
import Util.Http as Http2



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


getNotifyDueItems :
    Flags
    -> (Result Http.Error NotificationSettings -> msg)
    -> Cmd msg
getNotifyDueItems flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/usertask/notifydueitems"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.NotificationSettings.decoder
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


upload : Flags -> Maybe String -> ItemUploadMeta -> List File -> (String -> Result Http.Error BasicResult -> msg) -> List (Cmd msg)
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


uploadSingle : Flags -> Maybe String -> ItemUploadMeta -> String -> List File -> (Result Http.Error BasicResult -> msg) -> Cmd msg
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


login : Flags -> UserPass -> (Result Http.Error AuthResult -> msg) -> Cmd msg
login flags up receive =
    Http.post
        { url = flags.config.baseUrl ++ "/api/v1/open/auth/login"
        , body = Http.jsonBody (Api.Model.UserPass.encode up)
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


versionInfo : Flags -> (Result Http.Error VersionInfo -> msg) -> Cmd msg
versionInfo flags receive =
    Http.get
        { url = flags.config.baseUrl ++ "/api/info/version"
        , expect = Http.expectJson receive Api.Model.VersionInfo.decoder
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



-- Tags


getTags : Flags -> String -> (Result Http.Error TagList -> msg) -> Cmd msg
getTags flags query receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/tag?q=" ++ Url.percentEncode query
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



-- Equipments


getEquipments : Flags -> String -> (Result Http.Error EquipmentList -> msg) -> Cmd msg
getEquipments flags query receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/equipment?q=" ++ Url.percentEncode query
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.EquipmentList.decoder
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



-- Organization


getOrgLight : Flags -> (Result Http.Error ReferenceList -> msg) -> Cmd msg
getOrgLight flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/organization"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ReferenceList.decoder
        }


getOrganizations : Flags -> String -> (Result Http.Error OrganizationList -> msg) -> Cmd msg
getOrganizations flags query receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/organization?full=true&q=" ++ Url.percentEncode query
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



-- Person


getPersonsLight : Flags -> (Result Http.Error ReferenceList -> msg) -> Cmd msg
getPersonsLight flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/person?full=false"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ReferenceList.decoder
        }


getPersons : Flags -> String -> (Result Http.Error PersonList -> msg) -> Cmd msg
getPersons flags query receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/person?full=true&q=" ++ Url.percentEncode query
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


postSource : Flags -> Source -> (Result Http.Error BasicResult -> msg) -> Cmd msg
postSource flags source receive =
    let
        params =
            { url = flags.config.baseUrl ++ "/api/v1/sec/source"
            , account = getAccount flags
            , body = Http.jsonBody (Api.Model.Source.encode source)
            , expect = Http.expectJson receive Api.Model.BasicResult.decoder
            }
    in
    if source.id == "" then
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



-- Users


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



-- Job Queue


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



-- Item


itemSearch : Flags -> ItemSearch -> (Result Http.Error ItemLightList -> msg) -> Cmd msg
itemSearch flags search receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/search"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ItemSearch.encode search)
        , expect = Http.expectJson receive Api.Model.ItemLightList.decoder
        }


itemDetail : Flags -> String -> (Result Http.Error ItemDetail -> msg) -> Cmd msg
itemDetail flags id receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ItemDetail.decoder
        }


setTags : Flags -> String -> ReferenceList -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setTags flags item tags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/tags"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ReferenceList.encode tags)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setDirection : Flags -> String -> DirectionValue -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setDirection flags item dir receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/direction"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.DirectionValue.encode dir)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setCorrOrg : Flags -> String -> OptionalId -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setCorrOrg flags item id receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/corrOrg"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalId.encode id)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setCorrPerson : Flags -> String -> OptionalId -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setCorrPerson flags item id receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/corrPerson"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalId.encode id)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setConcPerson : Flags -> String -> OptionalId -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setConcPerson flags item id receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/concPerson"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalId.encode id)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setConcEquip : Flags -> String -> OptionalId -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setConcEquip flags item id receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/concEquipment"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalId.encode id)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setItemName : Flags -> String -> OptionalText -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setItemName flags item text receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/name"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalText.encode text)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setItemNotes : Flags -> String -> OptionalText -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setItemNotes flags item text receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/notes"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalText.encode text)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setItemDate : Flags -> String -> OptionalDate -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setItemDate flags item date receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v1/sec/item/" ++ item ++ "/date"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.OptionalDate.encode date)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setItemDueDate : Flags -> String -> OptionalDate -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setItemDueDate flags item date receive =
    Http2.authPost
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



-- Helper


getAccount : Flags -> AuthResult
getAccount flags =
    Maybe.withDefault Api.Model.AuthResult.empty flags.account
