module Database.Message.DataChange exposing (ChangeType(..), DataChange, decodeDataChange, encodeDataChange)

import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode exposing ((|:))
import Database.Message.Message as Message exposing (WithRequestNumber)


type ChangeType
    = Merge
    | Push


type alias DataChange =
    { changeType : ChangeType
    , path : String
    , data : Value
    }


decodeChangeType : String -> Decoder ChangeType
decodeChangeType changeType =
    case changeType of
        "d" ->
            Decode.succeed Push

        "m" ->
            Decode.succeed Merge

        _ ->
            Decode.fail <| "Unknown change type '" ++ changeType ++ "'"


decodeDataChange : Decoder DataChange
decodeDataChange =
    Decode.succeed DataChange
        |: (Decode.at [ "d", "a" ] Decode.string
                |> Decode.andThen decodeChangeType
           )
        |: Decode.at [ "d", "b", "p" ] Decode.string
        |: Decode.at [ "d", "b", "d" ] Decode.value


encodeChangeType : ChangeType -> Value
encodeChangeType changeType =
    case changeType of
        Merge ->
            Encode.string "m"

        Push ->
            Encode.string "d"


encodeDataChange : WithRequestNumber DataChange -> Value
encodeDataChange options =
    Message.encodeBase
        Message.Database
        [ ( "r", Encode.int options.requestNumber )
        , ( "a", encodeChangeType options.changeType )
        , ( "b"
          , Encode.object
                [ ( "p", Encode.string options.path )
                , ( "d", options.data )
                ]
          )
        ]
