module Message.Handshake exposing (ServerHandshake)

import Json.Encode as Encode
import Json.Decode as Decode

type alias WithRequestNumber data =
    { data | requestNumber : Int }


type alias ServerHandshake =
    { timestamp : Int
    , protocolVersion : String
    , host : String
    , session : String
    }


type alias ClientHandshake =
    WithRequestNumber
        { packageVersion : String
        }


serverHandshake : ServerHandshake -> String
serverHandshake options =
