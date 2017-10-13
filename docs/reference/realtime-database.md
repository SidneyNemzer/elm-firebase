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

The client info for the JS SDK looks like this: `sdk.js.4-1-3`. This info is constructed by the JS SDK in [PersistentConnection.ts](https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/core/PersistentConnection.ts#L971-L995).


# Database Interactions

## Create or Set data

This will overwrite existing data, even sibling keys that are not specified in the write. Equivelent to `Reference#set`.

#### Client Message:

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

#### Client Message:

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

Note that the actual data is sent separatly, see the Data section

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

### Stop Listening for changes

#### Client Message:

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

### Data

> **Important**: These messages will be sent by the server without being requested (assuming the client has already sent a 'listen' message for the path)

"Push" messages are used when the client first begins listening to a path. Any updates to the data will be "Merge" messages, to reduce the required bandwidth.

Push:

```javascript
{
  t: 'd'
  d: {
    a: 'd', // action = push; client should re-create local cache
    b: { // body
      p: string // path
      d: object | string | number | null // data
    }
  }
}
```

Merge:

```javascript
{
  t: 'd'
  d: {
    a: 'm', // action = merge; client should update the local cache
    b: { // body
      p: string // path
      d: object | string | number | null // data
    }
  }
}
```

## Update data

#### Client Message:

```javascript
{
  t: 'd'
  d: {
    r: number, // Must be set to a unique request number
    a: 'm' // action = merge
    b: {
      p: string, // path
      d: object // The keys to update
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

## Delete data

#### Client Message:

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

# Errors

### Auth Revoked

Usually means the auth token has expired and should be refreshed

```javascript
{
  t: 'd',
  d: {
    a: 'ac', 
    b: {
      s: string, // status code
      d: string // explaination
    }
  }
}
```

### General Server Error

Basically a 500 error. Probably doesn't occur often.

```javascript
{
  t: 'c',
  d: {
    t: 'e', // e for error
    d: string // I assume it's a string, it's not clear from the client library
  }
}
```
