module Database.LocalRepo.LocalRepo exposing (LocalRepo, Value(..), Path, heads, empty, set, get)

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


empty : LocalRepo
empty =
    Dict.empty


pathFromUri : String -> Path
pathFromUri =
    String.split "/"


get : Path -> Value -> Value
get path repo =
    case repo of
        Tree tree ->
            case combineTuble2 ( List.head path, List.tail path ) of
                -- Set the value in the current tree
                Just ( segment, [] ) ->
                    Dict.get segment tree
                        |> Maybe.withDefault Null

                -- Find the next segment of the current tree
                Just ( segment, remainingPath ) ->
                    case Dict.get segment tree of
                        -- Update the tree and continue down
                        Just value ->
                            get remainingPath value

                        _ ->
                            Null

                -- Path is empty
                Nothing ->
                    Tree tree

        _ ->
            Null


heads : List a -> Maybe ( List a, a )
heads list =
    let
        reversed =
            List.reverse list

        maybeBoth =
            ( List.tail reversed |> Maybe.map List.reverse
            , List.head reversed
            )
    in
        case maybeBoth of
            ( Just a, Just b ) ->
                Just ( a, b )

            ( _, _ ) ->
                Nothing


combineTuble2 : ( Maybe a, Maybe b ) -> Maybe ( a, b )
combineTuble2 tuple =
    case tuple of
        ( Just a, Just b ) ->
            Just ( a, b )

        ( _, _ ) ->
            Nothing


set : Path -> LocalRepo -> Value -> Value
set path repo value =
    case combineTuble2 ( List.head path, List.tail path ) of
        -- Set the value in the current tree
        Just ( segment, [] ) ->
            Tree <| Dict.insert segment value repo

        -- Find the next segment of the current tree
        Just ( segment, remainingPath ) ->
            case Dict.get segment repo of
                -- Update the tree and continue down
                Just (Tree tree) ->
                    Tree <|
                        Dict.insert
                            segment
                            (set remainingPath tree value)
                            repo

                -- Value isn't a tree, overwrite and continue down
                _ ->
                    Tree <|
                        Dict.insert
                            segment
                            (set remainingPath Dict.empty value)
                            repo

        -- Path is empty
        Nothing ->
            value
