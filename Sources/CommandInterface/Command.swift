//
//  Command.swift
//  MedinaCommandInterface
//
//  Created by Colin Campbell on 8/9/21.
//

import Foundation

/// A response from medina from a command.
public protocol CommandResponse {
  
  /// Initializes a command response from a response string.
  /// - Parameter response: The response string read from medina.
  init?(response: Data)
}

/// A command that can be sent to medina.
public protocol Command {
  
  /// The command's response type.
  associatedtype Response: CommandResponse
  
  /// An indication as to whether or not the command will use `sudo`.
  var sudo: Bool { get }
  
  /// The command's arguments.
  var arguments: [String] { get }
}

extension Command {
  
  /// Parses the response string from medina for the command's response.
  /// - Parameter response: The response string read from medina.
  /// - Returns: The command's response.
  func parse(_ response: Data) -> Response? {
    return Response(response: response)
  }
  
}
