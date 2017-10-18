module Database.LocalRepo.Test exposing (main)

import Html exposing (Html, div, text)
import Database.LocalRepo.LocalRepo as LocalRepo exposing (Value)


database : Value
database =
    LocalRepo.set [ "a", "b", "c" ] LocalRepo.empty (LocalRepo.Bool True)


lines : List String -> List (Html Never)
lines =
    List.map (\lineText -> div [] [ text lineText ])


main : Html Never
main =
    div [] <|
        lines
            [ toString <| LocalRepo.get [ "a" ] database
            , toString <| database
            ]
