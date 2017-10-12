## About

Firebase perfers to communicate over WebSockets for a fast, realtime communication. Every message will be a JSON object, and all messages must have a `"t"` and `"d"` key, for 'message type' and 'data' respectivly.

(Note that there is also a REST API, but it has limited functionality)

The "client library" refers to the [firebase-js-sdk](https://github.com/firebase/firebase-js-sdk)

## Database Messages

Messages about the database, eg updates

### "response"

```javascript
{
  t: 'd', // d for database
  d: {
    r: number, // request number
    b: ? // body
  }
}
```

A response from the server (responding to a message from the client, presumably ourselves). The request number indicates which request is being responded to.

See the handler in [PersistentConnection.ts](https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/core/PersistentConnection.ts#L583-L591)

### Data Push

These indicate data modification

See the handler in [PersistentConnection.ts](https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/core/PersistentConnection.ts#L600-L630)

#### Push Data

```javascript
{
  t: 'd',
  d: {
    a: 'd', 
    b: {
      p: string, // path
      d: object | string | number | null(?) // any valid firebase value
    }
  }
}
```

It appears that this is a data overrite (as opposed to a merge).

See the handler in [PersistentConnection.ts](https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/core/PersistentConnection.ts#L602-L608)

#### Merge Data

```javascript
{
  t: 'd',
  d: {
    a: 'm', 
    b: {
      p: string, // path
      d: object | string | number | null(?) // any valid firebase value
    }
  }
}
```

It looks like the [Firebase server emulator](https://github.com/urish/firebase-server/blob/master/index.js) never sends this message. But the client handles it as a 'merge'. See the handler in [PersistentConnection.ts](https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/core/PersistentConnection.ts#L609-L615)

#### Listen Revoked

```javascript
{
  t: 'd',
  d: {
    a: 'c', 
    b: {
      p: string, // path
      q: ? // query
    }
  }
}
```

The client treats it as a "permission_denied" error. See the handler in [PersistentConnection.ts](https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/core/PersistentConnection.ts#L616-L617)

#### Auth Revoked

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

Indicates that the auth token has expired. See the handler in [PersistentConnection.ts](https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/core/PersistentConnection.ts#L913-L932)

#### Security Debug

```javascript
{
  t: 'd',
  d: {
    a: 'sd', 
    b: {
      msg: string
    }
  }
}
```

Probably not used much, if at all. It logs directly to the console, but I've never seen this type of message from Firebase. See the handler in [PersistentConnection.ts](https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/core/PersistentConnection.ts#L934-L942)


### Error

```javascript
{
  t: 'd', // d for database
  d: {
    error: string // probably string
  }
}
```
See the handler in [PersistentConnection.ts](https://github.com/firebase/firebase-js-sdk/blob/master/packages/database/src/core/PersistentConnection.ts#L592-L593)

## Control Messages

Messages related to the connection, server, or client

### Handshake (first message from server)

```javascript
{ 
  t: 'c', // c for control
  d: {
    t: 'h', // h for handshake or hello
    d: {
      ts: number, // timestamp
      v: string, // version
      h: string, // host
      s: string // session id
    }
  }
}
```
It appears that the host (`h`) is some kind of long-term connection that the client library is instructed to use. Once the handshake is recieved, the client connects to the new host (also using a websocket) and stores the host in localStorage to use for future connections.

See the handler in [Connection.ts](https://github.com/firebase/firebase-js-sdk/blob/31d0f8dce31d73b4419459548b1b9081a3d9dbed/packages/database/src/realtime/Connection.ts#L368-L389)

### "CONTROL_SHUTDOWN"

```javascript
{
  t: 'c'
  d: {
    t: 's', // s for shutdown
    d: string // reason for shutdown. Generally human-readable
  }
}
```

It's unclear exactly why this would happen

See the handler in [Connection.ts](https://github.com/firebase/firebase-js-sdk/blob/31d0f8dce31d73b4419459548b1b9081a3d9dbed/packages/database/src/realtime/Connection.ts#L506-L519)

### "END_TRANSMISSION"

```javascript
{
  t: 'c'
  d: {
    t: 'n', // n for, uh, eNd transmission?
    d: // Unknown, the client library doesn't use this payload if it's there
  }
}
```

This inidicates a websocket connection should close. The client library automatically switches to the second "host" websocket if possible.

See the handler in [Connection.ts](https://github.com/firebase/firebase-js-sdk/blob/31d0f8dce31d73b4419459548b1b9081a3d9dbed/packages/database/src/realtime/Connection.ts#L336-L343)

### "CONTROL_RESET"

```javascript
{
  t: 'c'
  d: {
    t: 'r', // r for reset
    d: string // host url
  }
}
```

Indicates that the host should be immediately switched. The current connection should be closed.

See the handler in [Connection.ts](https://github.com/firebase/firebase-js-sdk/blob/31d0f8dce31d73b4419459548b1b9081a3d9dbed/packages/database/src/realtime/Connection.ts#L422-L434)

### Server Error

```javascript
{
  t: 'c',
  d: {
    t: 'e', // r for error
    d: string // I assume it's a string, it's not clear from the client library
  }
}
```

See handler in [Connection.ts](https://github.com/firebase/firebase-js-sdk/blob/31d0f8dce31d73b4419459548b1b9081a3d9dbed/packages/database/src/realtime/Connection.ts#L351-L352)

### "CONTROL_PONG"

```javascript
{
  t: 'c',
  d: {
    t: 'o',
    d: // Unknown, the client library doesn't use this payload if it's there
  }
}
```
