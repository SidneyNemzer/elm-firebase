module Database.Message.Response exposing (Status, ServerResponse, decodeServerResponse)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode exposing ((|:))


type Status
    = Ok
    | PermissionDenied


type alias ServerResponse =
    { requestNumber : Int
    , status : Status
    , explaination : String
    }


decodeStatus : String -> Decoder Status
decodeStatus status =
    case status of
        "ok" ->
            Decode.succeed Ok

        "permission_denied" ->
            Decode.succeed PermissionDenied

        _ ->
            Decode.fail <| "Unknown status '" ++ status ++ "'"


decodeServerResponse : Decoder ServerResponse
decodeServerResponse =
    Decode.succeed ServerResponse
        |: Decode.at [ "d", "r" ] Decode.int
        |: (Decode.at [ "d", "b", "s" ] Decode.string
                |> Decode.andThen decodeStatus
           )
        |: Decode.at [ "d", "b", "d" ] Decode.string
