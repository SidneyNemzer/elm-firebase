module Database.LocalRepo.Test exposing (main)

import Html exposing (Html, div, text)
import Database.LocalRepo.LocalRepo as LocalRepo


myList : List String
myList =
    []


main : Html Never
main =
    div [] [ text <| toString <| LocalRepo.heads myList ]
