module Test exposing (..)

import Html exposing (Html, div, text, input, button, label, form, textarea)
import Html.Attributes exposing (value, type_, style, checked, disabled, name)
import Html.Events exposing (onInput, onClick, onSubmit)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import WebSocket
import Database.Message.Decoder as MessageDecoder
import Database.Message.Message as Message exposing (WithRequestNumber)
import Database.Message.DataChange as DataChange exposing (DataChange, ChangeType(..))
import Database.Message.Handshake as Handshake exposing (ClientHandshake)
import Database.Message.Subscriptions as Subscriptions exposing (Subscribe, Unsubscribe)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


protocolVersion : String
protocolVersion =
    "5"


projectId : String
projectId =
    "sidneys-test-project"


defaultWebsocketDomain : String
defaultWebsocketDomain =
    projectId ++ ".firebaseio.com"


queryParam : String -> String -> String
queryParam key value =
    key ++ "=" ++ value


queryParams : List ( String, String ) -> List String
queryParams =
    List.map (\( key, value ) -> queryParam key value)


websocketUrl : String -> String -> List ( String, String ) -> String
websocketUrl domain version params =
    "wss://"
        ++ domain
        ++ "/.ws?"
        ++ (( "v", version )
                :: params
                |> queryParams
                |> String.join "&"
           )


type alias SimpleDataChange =
    { requestNumber : Int
    , changeType : ChangeType
    , path : String
    , data : String
    }


type MessageForm
    = DataChange SimpleDataChange
    | Subscribe Subscribe
    | Unsubscribe Unsubscribe
    | Handshake ClientHandshake


type alias CustomWebsocketUrl =
    { domain : String
    , session : String
    }


type WebsocketUrl
    = Default
    | Custom CustomWebsocketUrl


isDataChange : MessageForm -> Bool
isDataChange messageForm =
    case messageForm of
        DataChange _ ->
            True

        Subscribe _ ->
            False

        Unsubscribe _ ->
            False

        Handshake _ ->
            False


isSubscribe : MessageForm -> Bool
isSubscribe messageForm =
    case messageForm of
        DataChange _ ->
            False

        Subscribe _ ->
            True

        Unsubscribe _ ->
            False

        Handshake _ ->
            False


isUnsubscribe : MessageForm -> Bool
isUnsubscribe messageForm =
    case messageForm of
        DataChange _ ->
            False

        Subscribe _ ->
            False

        Unsubscribe _ ->
            True

        Handshake _ ->
            False


isHandshake : MessageForm -> Bool
isHandshake messageForm =
    case messageForm of
        DataChange _ ->
            False

        Subscribe _ ->
            False

        Unsubscribe _ ->
            False

        Handshake _ ->
            True


type alias Model =
    { log : List String
    , connect : Bool
    , websocketUrl : WebsocketUrl
    , messageForm : MessageForm
    , requestNumber : Int
    }


type Msg
    = WebSocketFrame String
    | Send
    | ToggleConnect
    | FormUpdate MessageForm
    | UpdateWebsocketUrl WebsocketUrl


init : ( Model, Cmd Msg )
init =
    { log = [ "info: Not connected" ]
    , connect = False
    , websocketUrl = Default
    , messageForm = Handshake (ClientHandshake 1 "")
    , requestNumber = 1
    }
        ! []


log : String -> String -> List String -> List String
log label message logs =
    List.append logs [ label ++ ": " ++ message ]


handleWebsocketFrame : Model -> String -> ( Model, Cmd Msg )
handleWebsocketFrame model message =
    case MessageDecoder.decode message of
        Ok serverMessage ->
            { model
                | log = log "recieve" message model.log |> log "serverMessage" (toString serverMessage)
            }
                ! []

        Err error ->
            { model
                | log = log "recieve" message model.log |> log "failed to decode" error
            }
                ! []


buildWebsocket : WebsocketUrl -> String
buildWebsocket urlType =
    case urlType of
        Default ->
            websocketUrl defaultWebsocketDomain protocolVersion []

        Custom customWebsocketUrl ->
            websocketUrl
                customWebsocketUrl.domain
                protocolVersion
                [ ( "ls", customWebsocketUrl.session )
                , ( "ns", projectId )
                ]


encode : (WithRequestNumber data -> Value) -> WithRequestNumber data -> ( String, Int )
encode encoder data =
    ( Encode.encode 0 <| encoder data
    , data.requestNumber
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WebSocketFrame message ->
            handleWebsocketFrame model message

        Send ->
            let
                result : Result String ( String, Int )
                result =
                    case model.messageForm of
                        DataChange dataChange ->
                            Decode.decodeString Decode.value dataChange.data
                                |> Result.map
                                    (\encodedData ->
                                        encode
                                            DataChange.encodeDataChange
                                            { requestNumber = dataChange.requestNumber
                                            , changeType = dataChange.changeType
                                            , path = dataChange.path
                                            , data = encodedData
                                            }
                                    )

                        Subscribe subscribe ->
                            Ok <| encode Subscriptions.encodeSubscribe subscribe

                        Unsubscribe unsubscribe ->
                            Ok <| encode Subscriptions.encodeUnsubscribe unsubscribe

                        Handshake clientHandshake ->
                            Ok <| encode Handshake.encodeClientHandshake clientHandshake
            in
                case result of
                    Ok ( message, requestNumber ) ->
                        { model
                            | log = log "send" message model.log
                            , requestNumber = requestNumber + 1
                        }
                            ! [ WebSocket.send (buildWebsocket model.websocketUrl) message ]

                    Err error ->
                        { model
                            | log = log "failed to decode" error model.log
                        }
                            ! []

        ToggleConnect ->
            let
                message =
                    if not model.connect then
                        "connected to " ++ buildWebsocket model.websocketUrl
                    else
                        "disconnected from " ++ buildWebsocket model.websocketUrl
            in
                { model
                    | connect = not model.connect
                    , log = log "info" message model.log
                }
                    ! []

        FormUpdate newForm ->
            { model | messageForm = newForm } ! []

        UpdateWebsocketUrl websocketUrl ->
            { model | websocketUrl = websocketUrl } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.connect then
        WebSocket.listen (buildWebsocket model.websocketUrl) WebSocketFrame
    else
        Sub.none


viewRadio : String -> (data -> MessageForm) -> data -> Bool -> Html Msg
viewRadio name messageForm data active =
    label []
        [ input
            [ type_ "radio"
            , onClick <| FormUpdate <| messageForm data
            , checked active
            ]
            []
        , text name
        ]


viewNumberInput : String -> (data -> MessageForm) -> (Int -> data) -> Int -> Html Msg
viewNumberInput name messageForm data currentValue =
    label []
        [ text name
        , input
            [ type_ "number"
            , onInput
                (\inputString ->
                    FormUpdate <|
                        messageForm <|
                            data <|
                                Result.withDefault 0 <|
                                    String.toInt inputString
                )
            , value <| toString currentValue
            ]
            []
        ]


viewTextInput : String -> (data -> MessageForm) -> (String -> data) -> String -> Html Msg
viewTextInput name messageForm data currentValue =
    label []
        [ text name
        , input
            [ onInput
                (\inputString ->
                    FormUpdate <|
                        messageForm <|
                            data inputString
                )
            , value currentValue
            ]
            []
        ]


viewUrlForm : Model -> Html Msg
viewUrlForm model =
    case model.websocketUrl of
        Default ->
            div [] []

        Custom customWebsocketUrl ->
            div []
                [ label []
                    [ text "Domain"
                    , input
                        [ onInput
                            (\inputString ->
                                UpdateWebsocketUrl <|
                                    Custom <|
                                        { customWebsocketUrl | domain = inputString }
                            )
                        , value customWebsocketUrl.domain
                        ]
                        []
                    ]
                , label []
                    [ text "Session"
                    , input
                        [ onInput
                            (\inputString ->
                                UpdateWebsocketUrl <|
                                    Custom <|
                                        { customWebsocketUrl | session = inputString }
                            )
                        , value customWebsocketUrl.session
                        ]
                        []
                    ]
                ]


viewMessageForm : Model -> Html Msg
viewMessageForm model =
    case model.messageForm of
        DataChange dataChange ->
            div []
                [ div []
                    [ text "Modification Type"
                    , viewRadio
                        "Merge"
                        DataChange
                        { dataChange | changeType = Merge }
                        (dataChange.changeType == Merge)
                    , viewRadio
                        "Push"
                        DataChange
                        { dataChange | changeType = Push }
                        (dataChange.changeType == Push)
                    ]
                , viewNumberInput
                    "Request Number"
                    DataChange
                    (\requestNumber -> { dataChange | requestNumber = requestNumber })
                    dataChange.requestNumber
                , viewTextInput
                    "Path"
                    DataChange
                    (\path -> { dataChange | path = path })
                    dataChange.path
                , label []
                    [ text "Data"
                    , textarea
                        [ onInput
                            (\inputString ->
                                FormUpdate <|
                                    DataChange <|
                                        { dataChange | data = inputString }
                            )
                        , value dataChange.data
                        ]
                        []
                    ]
                ]

        Subscribe subscribe ->
            div []
                [ viewNumberInput
                    "Request Number"
                    Subscribe
                    (\requestNumber -> { subscribe | requestNumber = requestNumber })
                    subscribe.requestNumber
                , viewTextInput
                    "Path"
                    Subscribe
                    (\path -> { subscribe | path = path })
                    subscribe.path
                , viewTextInput
                    "Hash"
                    Subscribe
                    (\hash -> { subscribe | hash = hash })
                    subscribe.hash
                ]

        Unsubscribe unsubscribe ->
            div []
                [ viewNumberInput
                    "Request Number"
                    Unsubscribe
                    (\requestNumber -> { unsubscribe | requestNumber = requestNumber })
                    unsubscribe.requestNumber
                , viewTextInput
                    "Path"
                    Unsubscribe
                    (\path -> { unsubscribe | path = path })
                    unsubscribe.path
                ]

        Handshake clientHandshake ->
            div []
                [ viewNumberInput
                    "Request Number"
                    Handshake
                    (\requestNumber -> { clientHandshake | requestNumber = requestNumber })
                    clientHandshake.requestNumber
                , viewTextInput
                    "Version string"
                    Handshake
                    (\packageVersion -> { clientHandshake | packageVersion = packageVersion })
                    clientHandshake.packageVersion
                ]


view : Model -> Html Msg
view model =
    div [ style [ ( "margin", "10px" ) ] ]
        [ div []
            [ label [] [ input [ type_ "checkbox", onClick ToggleConnect ] [], text "Connect" ]
            , div []
                [ label []
                    [ input
                        [ type_ "radio"
                        , onClick <| UpdateWebsocketUrl <| Default
                        , checked <| model.websocketUrl == Default
                        ]
                        []
                    , text "Default URL"
                    ]
                , label []
                    [ input
                        [ type_ "radio"
                        , onClick <| UpdateWebsocketUrl <| Custom { domain = "", session = "" }
                        , checked <| model.websocketUrl /= Default
                        ]
                        []
                    , text "Custom URL"
                    ]
                ]
            , viewUrlForm model
            , div []
                [ viewRadio
                    "Handshake"
                    Handshake
                    (ClientHandshake model.requestNumber "")
                    (isHandshake model.messageForm)
                , viewRadio
                    "Subscribe"
                    Subscribe
                    (Subscriptions.Subscribe model.requestNumber "" "")
                    (isSubscribe model.messageForm)
                , viewRadio
                    "Unsubscribe"
                    Unsubscribe
                    (Subscriptions.Unsubscribe model.requestNumber "")
                    (isUnsubscribe model.messageForm)
                , viewRadio
                    "Data Change"
                    DataChange
                    (SimpleDataChange model.requestNumber Merge "" "")
                    (isDataChange model.messageForm)
                ]
            , viewMessageForm model
            , button [ onClick Send, disabled <| not model.connect ] [ text "Send" ]
            ]
        , div
            []
          <|
            List.map
                (\message -> div [] [ text message ])
                model.log
        ]
