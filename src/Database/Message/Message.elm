module Database.Message.Message exposing (MessageType(..), WithRequestNumber, encodeBase)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type MessageType
    = Control
    | Database


type alias WithRequestNumber data =
    { data | requestNumber : Int }


encodeMessageType : MessageType -> String
encodeMessageType messageType =
    case messageType of
        Control ->
            "c"

        Database ->
            "d"


decodeMessageType : String -> Decoder MessageType
decodeMessageType messageType =
    case messageType of
        "c" ->
            Decode.succeed Control

        "d" ->
            Decode.succeed Database

        _ ->
            Decode.fail <| "Unknown message type '" ++ messageType ++ "'"


encodeBase : MessageType -> List ( String, Value ) -> Value
encodeBase messageType data =
    Encode.object
        [ ( "t", Encode.string <| encodeMessageType messageType )
        , ( "d", Encode.object data )
        ]


decodeBase : Decoder MessageType
decodeBase =
    Decode.field "t" Decode.string
        |> Decode.andThen decodeMessageType
