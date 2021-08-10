# CommandInterface

A Swift package for interacting with command line interfaces.

## Creating an Interface

Create an interface with
1) the URL to the executable,
2) an, optional, URL to the executable's working directory,
3) and an, optional, dictionary of environment variables.

```swift
let interface = Interface(executableURL: ...)
```

## Creating Commands

Create a command by implementing the `Command` and `CommandResponse` protocols.

```swift
struct VersionCommand: Command {
  typealias Response = VersionCommandResponse
  
  var arguments: [String] {
    return ["--version"]
  }
}

public struct VersionCommandResponse: CommandResponse {
  public let version: String
  
  public init?(response: String?) {
    guard let response = response else { return nil }
    version = response
  }
}
```

## Sending Commands

Send commands to the executable through the interface.

```swift
do {
  try interface.send(VersionCommand()) { response, error in
    print("Version: \(response.version ?? "N/A")")
  }
}
catch {
  print("Error sending command: \(error)")
}
```
