module Database.LocalRepo.LocalRepo exposing (LocalRepo, Value(..), Path, empty, set, get, update, toJson, toString)

import Dict exposing (Dict)
import Json.Encode as Encode


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


combineTuble2 : ( Maybe a, Maybe b ) -> Maybe ( a, b )
combineTuble2 tuple =
    case tuple of
        ( Just a, Just b ) ->
            Just ( a, b )

        ( _, _ ) ->
            Nothing


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


set : Path -> LocalRepo -> Value -> LocalRepo
set path repo value =
    case combineTuble2 ( List.head path, List.tail path ) of
        -- Set the value in the current tree
        Just ( segment, [] ) ->
            Dict.insert segment value repo

        -- Find the next segment of the current tree
        Just ( segment, remainingPath ) ->
            case Dict.get segment repo of
                -- Update the tree and continue down
                Just (Tree tree) ->
                    Dict.insert
                        segment
                        (Tree <| set remainingPath tree value)
                        repo

                -- Value isn't a tree, overwrite and continue down
                _ ->
                    Dict.insert
                        segment
                        (Tree <| set remainingPath Dict.empty value)
                        repo

        -- Path is empty
        Nothing ->
            Debug.crash "Invalid path"


{-| Combines two trees, overwriting the values of the first if necesarry
-}
update : LocalRepo -> LocalRepo -> LocalRepo
update baseTree updateTree =
    Dict.merge
        Dict.insert
        (\segment baseValue updateValue resultTree ->
            case ( baseValue, updateValue ) of
                ( Tree tree1, Tree tree2 ) ->
                    Dict.insert segment (Tree <| update tree1 tree2) resultTree

                _ ->
                    Dict.insert segment (Tree updateTree) resultTree
        )
        Dict.insert
        baseTree
        updateTree
        Dict.empty


encodeTree : LocalRepo -> Encode.Value
encodeTree =
    Dict.toList
        >> List.map
            (\( key, value ) ->
                case value of
                    Tree tree ->
                        ( key, encodeTree tree )

                    String string ->
                        ( key, Encode.string string )

                    Int int ->
                        ( key, Encode.int int )

                    Float float ->
                        ( key, Encode.float float )

                    Bool bool ->
                        ( key, Encode.bool bool )

                    Null ->
                        ( key, Encode.null )
            )
        >> Encode.object


toJson : LocalRepo -> String
toJson =
    encodeTree >> Encode.encode 2


toString : Value -> String
toString value =
    case value of
        Tree tree ->
            toJson tree

        String string ->
            string

        Int int ->
            Basics.toString int

        Float float ->
            Basics.toString float

        Bool bool ->
            Basics.toString bool

        Null ->
            "null"
