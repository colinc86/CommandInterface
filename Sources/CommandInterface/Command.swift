//
//  Command.swift
//  MedinaCommandInterface
//
//  Created by Colin Campbell on 8/9/21.
//

import Foundation

/// A response from a command line interface (CLI).
public protocol CommandResponse {
  
  /// Initializes a command response from a response string.
  /// - Parameter response: The response string read from the CLI.
  init?(response: Data)
}

/// A command that can be sent to a CLI.
///
/// Commands are sent in the form
///
/// ```
/// [sudo] [command] [arguments]
/// ```
public protocol Command {
  
  /// The command's response type.
  associatedtype Response: CommandResponse
  
  /// An indication as to whether or not the command will use `sudo`.
  var sudo: Bool { get }
  
  /// The command's base command.
  var command: String { get }
  
  /// The command's arguments.
  var arguments: [String] { get }
}

extension Command {
  
  /// All of the command's terms.
  var terms: String {
    return (sudo ? "sudo " : "") + command + " " + arguments.joined(separator: " ")
  }
  
  /// Parses the response string from the CLI for the command's response.
  /// - Parameter response: The response string read from the CLI.
  /// - Returns: The command's response.
  func parse(_ response: Data) -> Response? {
    return Response(response: response)
  }
  
}
