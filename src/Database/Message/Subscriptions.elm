module Database.Message.Subscriptions exposing (Subscribe, Unsubscribe, encodeSubscribe, encodeUnsubscribe)

import Json.Encode as Encode exposing (Value)
import Database.Message.Message as Message exposing (WithRequestNumber)


type alias Subscribe =
    { requestNumber : Int
    , path : String
    , hash : String
    }


type alias Unsubscribe =
    { requestNumber : Int
    , path : String
    }


encodeSubscribe : Subscribe -> Value
encodeSubscribe options =
    Message.encodeBase
        Message.Database
        [ ( "r", Encode.int options.requestNumber )
        , ( "a", Encode.string "q" )
        , ( "b"
          , Encode.object
                [ ( "p", Encode.string options.path )
                , ( "h", Encode.string options.hash )
                ]
          )
        ]


encodeUnsubscribe : Unsubscribe -> Value
encodeUnsubscribe options =
    Message.encodeBase
        Message.Database
        [ ( "r", Encode.int options.requestNumber )
        , ( "a", Encode.string "n" )
        , ( "b"
          , Encode.object
                [ ( "p", Encode.string options.path )
                ]
          )
        ]
