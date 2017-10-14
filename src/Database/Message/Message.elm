module Database.Message.Message exposing (MessageType(..), WithRequestNumber, encodeBase)

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


encodeBase : MessageType -> List ( String, Value ) -> Value
encodeBase messageType data =
    Encode.object
        [ ( "t", Encode.string <| encodeMessageType messageType )
        , ( "d", Encode.object data )
        ]
