# BinaryInitializable #

Simple Swift macro for instantiating structs and classes from binary data. 

Currently only supports numerical values.

## Usage

Use the `@BinaryInitializable` macro on your structs and classes to automatically conform them to the `BinaryInitialization` protocol. An appropriate initializer will be generated that takes your binary data and initializes the object's properties from the binary data *in source order*.

## Example

```
@BinaryInitializable
struct ScanResults {
  let distance: UInt32
  let speed: Double
}

// You will probably read your bytes from a file or external source
let bytes: [UInt8] = [0x0, 0x0, 0x9, 0xCA, 0x40, 0x3C, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCD]
let data = Data(bytes)

guard let results = try? ScanResults(binaryData: data) else {
  fatalError("In real life we should handle errors better!")
}

print("Our scan indicates you went \(results.distance) feet at an average speed of \(results.speed) MPH!")
// Output: Our scan indicates you went 2506 feet at an average speed of 28.8 MPH!
// Well, if we were less lazy with the number formatting.
```

If you have header data you want to ignore or only want to target a subset of bytes, `Data` subscripting is an easy shortcut.

```
// Ignore the first 4 bytes
let column = try? DataColumn(binaryData: data[4...])
```

What about endianness? By default, `BinaryInitializable` assumes your data is in little endian format. You can change this with the `bigEndian` flag.

```
@BinaryInitializable(bigEndian: true)
struct ScanResults {
  let distance: UInt32
  let speed: Double
}
```
