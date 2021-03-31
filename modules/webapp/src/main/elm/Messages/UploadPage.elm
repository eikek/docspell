module Messages.UploadPage exposing (..)

import Messages.Basics
import Messages.DropzoneComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , dropzone : Messages.DropzoneComp.Texts
    , reset : String
    , allFilesOneItem : String
    , skipExistingFiles : String
    , language : String
    , languageInfo : String
    , uploadErrorMessage : String
    , successBox :
        { allFilesUploaded : String
        , line1 : String
        , itemsPage : String
        , line2 : String
        , processingPage : String
        , line3 : String
        , resetLine1 : String
        , reset : String
        , resetLine2 : String
        }
    , selectedFiles : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , dropzone = Messages.DropzoneComp.gb
    , reset = "Reset"
    , allFilesOneItem = "All files are one single item"
    , skipExistingFiles = "Skip files already present in docspell"
    , language = "Language"
    , languageInfo =
        "Used for text extraction and analysis. The collective's "
            ++ "default language is used if not specified here."
    , uploadErrorMessage = "There were errors uploading some files."
    , successBox =
        { allFilesUploaded = "All files uploaded"
        , line1 =
            "Your files have been successfully uploaded. "
                ++ "They are now being processed. Check the "
        , itemsPage = "Items Page"
        , line2 = " later where the files will arrive eventually. Or go to the "
        , processingPage = "Processing Page"
        , line3 = " to view the current processing state."
        , resetLine1 = " Click "
        , reset = "Reset"
        , resetLine2 = " to upload more files."
        }
    , selectedFiles = "Selected Files"
    }


de : Texts
de =
    gb
