module Database.LocalRepo.LocalRepo exposing (LocalRepo, Value(..), Path)

import Dict exposing (Dict)


type Value
    = Tree Tree
    | String String
    | Int Int
    | Float Float
    | Bool Bool
    | Null


type alias Tree =
    Dict String Value


type alias LocalRepo =
    Tree


type alias Path =
    List String


pathFromUri : String -> Path
pathFromUri =
    String.split "/"


get : Path -> LocalRepo -> Value
get path repo =
    let
        value =
            List.head path
                |> Maybe.andThen
                    (\segment ->
                        Dict.get segment repo
                    )
                |> Maybe.withDefault Null

        maybeRemainingPath =
            List.tail path
    in
        case ( value, maybeRemainingPath ) of
            ( Tree tree, Just remainingPath ) ->
                get remainingPath repo

            ( _, Just _ ) ->
                Null

            ( _, _ ) ->
                value



-- set : Path -> LocalRepo -> Value -> LocalRepo
-- set path repo value =
