## About

Firebase perfers to communicate over WebSockets for a fast, realtime communication. Every message will be a JSON object, and all messages must have a `"t"` and `"d"` key, for 'message type' and 'data' respectivly.

(Note that there is also a REST API, but it has limited functionality)

### Handshake (first message from server)

```javascript
{
  t: 'h', // h for handshake
  d: {
    ts: number, // timestamp
    v: string, // version
    h: string, // host
    s: string // session id
  }
}
```

It looks like the host (`h`) is a new connection URL, which is cached by the client library. That host is connected to, also via websocket, as soon as possible, and for future connections.

See https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/realtime/Connection.ts#L368-L389
