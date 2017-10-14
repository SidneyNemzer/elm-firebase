module Database.Message.Handshake exposing (ServerHandshake, ClientHandshake, encodeClientHandshake, decodeServerHandshake)

import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode exposing ((|:))
import Database.Message.Message as Message


type alias ServerHandshake =
    { timestamp : Int
    , protocolVersion : String
    , host : String
    , session : String
    }


type alias ClientHandshake =
    { requestNumber : Int
    , packageVersion : String
    }


encodeClientHandshake : ClientHandshake -> Value
encodeClientHandshake options =
    Message.encodeBase
        Message.Database
        [ ( "r", Encode.int options.requestNumber )
        , ( "a", Encode.string "s" )
        , ( "b"
          , Encode.object
                [ ( "c"
                  , Encode.object
                        [ ( "sdk.elm." ++ options.packageVersion, Encode.int 1 ) ]
                  )
                ]
          )
        ]


decodeServerHandshake : Decoder ServerHandshake
decodeServerHandshake =
    Decode.at [ "d", "t" ] Decode.string
        |> Decode.andThen
            (\messageType ->
                if messageType == "h" then
                    Decode.succeed ServerHandshake
                        |: Decode.at [ "d", "d", "ts" ] Decode.int
                        |: Decode.at [ "d", "d", "v" ] Decode.string
                        |: Decode.at [ "d", "d", "h" ] Decode.string
                        |: Decode.at [ "d", "d", "s" ] Decode.string
                else
                    Decode.fail "This isn't a server handshake message"
            )
