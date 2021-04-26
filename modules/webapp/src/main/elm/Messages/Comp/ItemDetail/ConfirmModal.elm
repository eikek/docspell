module Messages.Comp.ItemDetail.ConfirmModal exposing
    ( Texts
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , confirmReprocessItem : String -> String
    , confirmReprocessFile : String -> String
    , confirmDeleteItem : String
    , confirmDeleteFile : String
    , confirmDeleteAllFiles : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , confirmReprocessItem =
        \state ->
            if state == "created" then
                "Reprocessing this item may change its metadata, "
                    ++ "since it is unconfirmed. Do you want to proceed?"

            else
                "Reprocessing this item will not change its metadata, "
                    ++ "since it has been confirmed. Do you want to proceed?"
    , confirmReprocessFile =
        \state ->
            if state == "created" then
                "Reprocessing this file may change metadata of "
                    ++ "this item, since it is unconfirmed. Do you want to proceed?"

            else
                "Reprocessing this file will not change metadata of "
                    ++ "this item, since it has been confirmed. Do you want to proceed?"
    , confirmDeleteItem =
        "Really delete this item? This cannot be undone."
    , confirmDeleteFile = "Really delete this file?"
    , confirmDeleteAllFiles = "Really delete these files?"
    }
