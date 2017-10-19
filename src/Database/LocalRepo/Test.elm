module Database.LocalRepo.Test exposing (main)

import Html exposing (Html, div, text)
import Database.LocalRepo.LocalRepo as LocalRepo exposing (Value(..), LocalRepo)


database : LocalRepo
database =
    LocalRepo.set [ "a", "b", "c" ] LocalRepo.empty (LocalRepo.Bool True)
        |> (\repo -> LocalRepo.set [ "a", "m", "l" ] repo (Bool True))


updateDatabase : LocalRepo
updateDatabase =
    LocalRepo.set [ "a", "b", "d", "e" ] LocalRepo.empty (LocalRepo.Bool True)


lines : List String -> List (Html Never)
lines =
    List.map (\lineText -> div [] [ text lineText ])


pre : String -> Html Never
pre =
    text >> List.singleton >> Html.pre []


main : Html Never
main =
    div []
        [ pre <| LocalRepo.toJson <| database
        , pre <| LocalRepo.toString <| LocalRepo.get [ "a" ] (Tree database)
        , pre <| LocalRepo.toJson <| LocalRepo.update database updateDatabase
        ]
