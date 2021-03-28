module Messages.UserManageComp exposing (..)

import Messages.Basics
import Messages.UserFormComp
import Messages.UserTableComp


type alias Texts =
    { userTable : Messages.UserTableComp.Texts
    , userForm : Messages.UserFormComp.Texts
    , users : String
    , newUser : String
    , addNewUser : String
    , reallyDeleteUser : String
    , createNewUser : String
    , basics : Messages.Basics.Texts
    , deleteThisUser : String
    , pleaseCorrectErrors : String
    }


gb : Texts
gb =
    { userTable = Messages.UserTableComp.gb
    , userForm = Messages.UserFormComp.gb
    , basics = Messages.Basics.gb
    , users = "Users"
    , newUser = "New user"
    , addNewUser = "Add new user"
    , reallyDeleteUser = "Really delete this user?"
    , createNewUser = "Create new user"
    , deleteThisUser = "Delete this user"
    , pleaseCorrectErrors = "Please correct the errors in the form."
    }


de : Texts
de =
    gb
