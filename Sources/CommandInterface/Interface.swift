//
//  Interface.swift
//  MedinaCommandInterface
//
//  Created by Colin Campbell on 8/9/21.
//

import Foundation

/// A command interface for interacting with medina.
@available(macOS 10.13, *)
public class Interface {
  
  // MARK: Public properties
  
  /// The URL to the interface's executable file.
  public let executableURL: URL
  
  /// The current working directory of the executable.
  public let currentDirectoryURL: URL?
  
  /// The interface's environment.
  public var environment: [String: String]?
  
  // MARK: Initializers
  
  /// Initializes an interface with the given environment.
  ///
  /// Will return `nil` if the file at the path given by `executableURL` is
  /// non-existant or not an executable file.
  /// - Parameters:
  ///   - executableURL: The URL to the interface's executable file.
  ///   - currentDirectoryURL: The current working directory of the executable.
  ///   - environment: The environment to apply to the interface.
  public init?(executableURL: URL, currentDirectoryURL: URL? = nil, environment: [String: String]? = nil) {
    guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
      return nil
    }
    
    self.executableURL = executableURL
    self.currentDirectoryURL = currentDirectoryURL
    self.environment = environment
  }
  
}

// MARK: - Public methods

@available(macOS 10.13, *)
extension Interface {
  
  /// Sends the given command to medina and waits for a response.
  /// - Parameters:
  ///   - command: The command to execute.
  ///   - completion: Called after the command has completed.
  /// - Throws: An error if the interface is unable to find the executable.
  public func send<T: Command>(command: T, completion: ((_ response: T.Response?, _ error: Error?) -> Void)? = nil) throws {
    try send(arguments: command.arguments) { output, error in
      completion?(command.parse(output), error)
    }
  }
  
}

// MARK: - Private methods

@available(macOS 10.13, *)
extension Interface {
  
  /// Sends the given arguments as a command to medina and waits for a response.
  /// - Parameters:
  ///   - arguments: The arguments to send to medina.
  ///   - completion: Called after the command has completed.
  /// - Throws: An error if the interface is unable to find the executable.
  private func send(arguments: [String], completion: ((_ output: String?, _ error: Error?) -> Void)? = nil) throws {
    let task = Process()
    
    // The output file handle
    let outputPipe = Pipe()
    let outputHandle = outputPipe.fileHandleForReading
    var outputData = Data()
    outputHandle.readabilityHandler = { fileHandle in
      outputData.append(fileHandle.readDataToEndOfFile())
    }
    
    // The error file handle
    let errorPipe = Pipe()
    let errorHandle = errorPipe.fileHandleForReading
    var errorData = Data()
    errorHandle.readabilityHandler = { fileHandle in
      errorData.append(fileHandle.readDataToEndOfFile())
    }
    
    // Set up the task
    task.executableURL = executableURL
    task.standardOutput = outputPipe
    task.standardError = errorPipe
    task.currentDirectoryURL = currentDirectoryURL
    task.environment = environment
    task.arguments = arguments
    task.terminationHandler = { process in
      completion?(
        outputData.count > 0 ? String(data: outputData, encoding: .utf8) : nil,
        errorData.count > 0 ? NSError(domain: "medina", code: 0, userInfo: [NSLocalizedDescriptionKey: String(data: errorData, encoding: .utf8) ?? ""]) : nil)
    }

    // Run the task
    try task.run()
  }
  
}
