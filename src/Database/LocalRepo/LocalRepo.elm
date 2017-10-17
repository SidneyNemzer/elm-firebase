module Database.LocalRepo.LocalRepo exposing (LocalRepo, Value(..), Path, heads)

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


getFromHead : Path -> LocalRepo -> Value
getFromHead path repo =
    List.head path
        |> Maybe.andThen
            (\segment ->
                Dict.get segment repo
            )
        |> Maybe.withDefault Null

get : Path -> LocalRepo -> Value
get path repo =
    let
        value =
            getFromHead path repo

        maybeRemainingPath =
            List.tail path
    in
        case ( value, maybeRemainingPath ) of
            ( Tree tree, Just remainingPath ) ->
                get remainingPath repo

            ( _, Just _ ) ->
                Null

            ( _, Nothing ) ->
                value


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



set : Path -> LocalRepo -> Value -> LocalRepo
set path repo value =
    case List.head path of
        Just segment ->
            case Dict.get segment repo of
                Tree tree ->
                    case List.tail path of
                        Just remainingPath ->
                            set remainingPath tree value
                        Nothing ->

        Nothing ->
            value
    -- case heads path of
    --     Just ([], child) ->
    --         Dict.set child repo
    --
    --     Just (parent, child) ->
    --         case getFromHead parent repo of
    --             Tree tree ->
    --                 -- continue down
    --
    --             _ ->
    --                 -- make dict and continue down
    --
    --     Nothing ->
    --         -- empty path
