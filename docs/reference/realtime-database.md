# Connecting

## Endpoints

The first time the client connects to the Firebase Realtime WebSocket, the URL is based on the project's URL:

```
wss://[project-id].firebaseio.com/.ws?v=[version]
```

* `[project-id]` is replaced with the project ID
* `[version]`is replaced with the Realtime WebSocket protocol version; this documentation is based on version 5

The server's first message (server hello) will include a host URL, which the client should use for future connections.

That URL looks like this:

```
wwss://s-usc1c-nss-210.firebaseio.com/.ws?v=[version]&ns=[project-id]&ls=[session]
```

* `[session]` is replaced with the previous session ID, if the client has reconnected from the same browser session

> Note: I'm not sure why the long-term host system is used, or what would happen if the client always used the project ID-based URL. Any explaination is welcome.

## Handshake

The server always sends the first message

```javascript
{
  t: 'c', // type = control
  d: {
    t: 'h', // type = handshake
    d: {
      ts: number, // Server timestamp
      v: string, // Version number; presumably the same as [version] in the URL
      h: string // Host domain -- The client should use this for future connections
      s: string // session ID -- included by the client in the URL when reconnection from the same browser session
    }
  }
}
```

Client's response:

```javascript
{
  t: 'd', // type = database (not sure why)
  d: {
    r: number, // request number
    a: 's', // action = stats
    b: { // body
      c: {
        [client info]: 1
      }
    }
  }
}
```

The JavaScript SDK library always sends this as its first message. The client won't create the WebSocket connection until a write or read is requested locally; the operation is queued while connecting, then that message will be sent right after the "client hello".

The client info for the JS SDK looks like this: `sdk.js.4-1-3`. `js` is the client (would be set to `admin_node` or `node`), `sdk` is just 'software development kit' (may be accompanined by `framework.cordova: 1` or `framework.reactnative: 1`. The numbers are just the sdk version (with periods replaced with dashes). This info is constructed by the JS SDK in [PersistentConnection.ts](https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/core/PersistentConnection.ts#L971-L995).


# Database Interactions

## Create or Set data

This will overrite existing data

#### Request:

```javascript
{
  t: 'd'
  d: {
    r: number, // Must be set to a unique request number
    a: 'p', // action = put
    b: { // body
      p: string, // path
      d: object | string | number // data
    }
  }
}
```

#### Good Response:

```javascript
{
  t: 'd'
  d: {
    r: number, // Same request number
    a: 'p', // action = put
    b: { // body
      s: 'ok', // status = ok
      d: "" // seems to always be an empty string
    }
  }
}
```

## Read data

### Listen for changes

#### Request:

```javascript
{
  t: 'd'
  d: {
    r: number, // Must be set to a unique request number
    a: 'q', // action = query
    b: { // body
      p: string, // path
      h: string // hash
    }
  }
}
```

#### Good Response:

Confirms request:

```javascript
{
  t: 'd'
  d: {
    r: number, // Same request number
    a: 'p', // action = put
    b: { // body
      s: 'ok', // status = ok
      d: "" // seems to always be an empty string
    }
  }
}
```

Sends data:

```javascript
{
  t: 'd'
  d: {
    a: 'd', // action = push data; client should re-create local cache
    b: { // body
      p: string // path
      d: object | string | number | null // data
    }
  }
}
```

### Once

#### Request:

```javascript
{
  t: 'd'
  d: {
    r: number, // Must be set to a unique request number
    a: 'p', // action = put
    b: { // body
      p: string, // path
      d: object | string | number // data
    }
  }
}
```

Send this right after the server has responded with the data:

```javascript
{
  t: 'd'
  d: {
    r: number, // Must be set to a unique request number
    a: 'n', // action = remove listener
    b: { // body
      p: string, // path, same as first request
    }
  }
}
```

#### Good Response:

Confirms the listen request:

```javascript
{
  t: 'd'
  d: {
    r: number, // Same listen request number
    a: 'p', // action = put
    b: { // body
      s: 'ok', // status = ok
      d: "" // seems to always be an empty string
    }
  }
}
```

Sends data:

```javascript
{
  t: 'd'
  d: {
    a: 'd', // action = push data; client should re-create local cache
    b: { // body
      p: string // path
      d: object | string | number | null // data
    }
  }
}
```

Confirms the stop listening request:

```javascript
{
  t: 'd'
  d: {
    r: number, // Same stop listen request number
    a: 'p', // action = put
    b: { // body
      s: 'ok', // status = ok
      d: "" // seems to always be an empty string
    }
  }
}
```

## Update data

#### Request:

```javascript
{
  t: 'd'
  d: {
    r: number, // Must be set to a unique request number
    a: 'm' // action = merge
    b: {
      p: string, // path
      d: object
    }
  }
}
```

#### Good Response:

```javascript
{
  t: 'd'
  d: {
    r: number, // Same stop listen request number
    b: { // body
      s: 'ok', // status = ok
      d: "" // seems to always be an empty string
    }
  }
}
```

## Delete data

#### Request:

```javascript
{
  t: 'd'
  d: {
    r: number, // Must be set to a unique request number
    a: 'p', // action = put
    b: { // body
      p: string, // path
      d: null
    }
  }
}
```

#### Good Response:

```javascript
{
  t: 'd'
  d: {
    r: number, // Same request number
    b: { // body
      s: 'ok', // status = ok
      d: "" // seems to always be an empty string
    }
  }
}
```
