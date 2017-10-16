module Database.Message.Decoder exposing (ServerMessage, decode)

import Json.Decode as Decode exposing (Decoder)
import Database.Message.DataChange as DataChange exposing (DataChange)
import Database.Message.Handshake as Handshake exposing (ServerHandshake)
import Database.Message.Response as Response exposing (ServerResponse)


type ServerMessage
    = DataChange DataChange
    | Handshake ServerHandshake
    | Response ServerResponse


decode : String -> Result String ServerMessage
decode =
    Decode.decodeString <|
        Decode.oneOf
            [ Decode.map DataChange DataChange.decodeDataChange
            , Decode.map Handshake Handshake.decodeServerHandshake
            , Decode.map Response Response.decodeServerResponse
            ]
