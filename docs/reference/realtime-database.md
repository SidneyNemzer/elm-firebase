# Connecting

*TODO*

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
