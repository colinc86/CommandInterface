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
  
  // MARK: Types
  
  public enum ResponseError: Error, CustomStringConvertible {
    case string(_ string: String)
    
    public var description: String {
      switch self {
      case .string(let string):
        return string
      }
    }
  }
  
  // MARK: Private properties
  
  /// The process.
  private var process: Process?
  
  /// The output handler that will be called.
  private var outputHandler: ((Data) -> Void)?
  
  /// The error handler that will be called.
  private var errorHandler: ((Data) -> Void)?
  
  /// The completion handler to be called.
  private var completionHandler: ((Int32, Process.TerminationReason) -> Void)? = nil
  
  /// The accumulated output data.
  private var outputData = Data()
  
  /// The accumulated error data.
  private var errorData = Data()
  
  /// The process's environment variables.
  private var environment: [String: String]?
  
  /// The current directory URL (initial working directory).
  private var currentDirectoryURL: URL?
  
  /// The URL of the executable binary file.
  private var executableURL: URL?
  
  /// The output pipe.
  private lazy var outputPipe: Pipe = {
    let pipe = Pipe()
    let handle = pipe.fileHandleForReading
    handle.readabilityHandler = outputPipeReadabilityHandler
    return pipe
  }()
  
  /// The error pipe.
  private lazy var errorPipe: Pipe = {
    let pipe = Pipe()
    let handle = pipe.fileHandleForReading
    handle.readabilityHandler = errorPipeReadabilityHandler
    return pipe
  }()
  
  // MARK: Initializers
  
  /// Initializes an interface with the given environment.
  ///
  /// Will return `nil` if the file at the path given by `executableURL` is
  /// non-existant or not an executable file.
  /// - Parameters:
  ///   - executableURL: The URL to the interface's executable file.
  ///   - currentDirectoryURL: The current working directory of the executable.
  ///   - environment: The environment to apply to the interface.
  public init?(
    executableURL: URL,
    currentDirectoryURL: URL? = nil,
    environment: [String: String]? = nil
  ) {
    guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
      return nil
    }
    
    // Set up the process.
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
  ///   - output: Called each time output data is received from the output pipe.
  ///   - error: Called each time output data is received from the error pipe.
  ///   - completion: Called after the command has completed.
  /// - Throws: An error if the interface is unable to find the executable.
  public func send<T: Command>(
    command: T,
    _ output: ((_ data: Data) -> Void)? = nil,
    _ error: ((_ errorData: Data) -> Void)? = nil,
    _ completion: ((_ status: Int32, _ reason: Process.TerminationReason, _ output: T.Response?, _ error: Error?) -> Void)? = nil) throws {
    // Send the command.
    try send(arguments: command.arguments, output, error) { [weak self] status, reason in
      guard let self = self else {
        completion?(1, Process.TerminationReason.uncaughtSignal, nil, nil)
        return
      }
      
      var error: Error?
      if let errorString = String(data: self.errorData, encoding: .utf8), !errorString.isEmpty {
        error = ResponseError.string(errorString)
      }
      
      completion?(status, reason, command.parse(self.outputData), error)
      
      // Clean up
      if let process = self.process {
        process.terminate()
      }
    }
  }
  
  /// Terminates the current process if it is running.
  public func terminateExecution() {
    if process?.isRunning == true {
      process?.terminate()
    }
  }
  
}

// MARK: - Private methods
@available(macOS 10.13, *)
extension Interface {
  
  /// Sends the given arguments as a command to medina and waits for a response.
  /// - Parameters:
  ///   - arguments: The arguments to send to medina.
  ///   - output: Called each time output data is received from the output pipe.
  ///   - error: Called each time output data is received from the error pipe.
  ///   - completion: Called after the command has completed.
  /// - Throws: An error if the interface is unable to find the executable.
  private func send(
    arguments: [String],
    _ output: ((_ data: Data) -> Void)? = nil,
    _ error: ((_ errorData: Data) -> Void)? = nil,
    _ completion: ((_ status: Int32, _ reason: Process.TerminationReason) -> Void)? = nil) throws
  {
    // Set up the process
    if process == nil {
      process = Process()
      process?.executableURL = executableURL
      process?.standardOutput = outputPipe
      process?.standardError = errorPipe
      process?.currentDirectoryURL = currentDirectoryURL
      process?.environment = environment
      process?.terminationHandler = terminationHandler
    }
    
    outputHandler = output
    errorHandler = error
    completionHandler = completion
    process?.arguments = arguments
    
    outputData.removeAll()
    errorData.removeAll()
    
    if let process = process {
      try process.run()
    }
    else {
      completion?(0, .exit)
    }
  }
  
  /// The output pipe handler.
  private func outputPipeReadabilityHandler(_ fileHandle: FileHandle) {
    let data = fileHandle.availableData
    outputData.append(data)
    outputHandler?(data)
  }
  
  /// The error pipe handler.
  private func errorPipeReadabilityHandler(_ fileHandle: FileHandle) {
    let data = fileHandle.availableData
    errorData.append(data)
    errorHandler?(data)
  }
  
  /// The termination handler.
  private func terminationHandler(_ process: Process) {
    let status = process.terminationStatus
    let reason = process.terminationReason

    if #available(macOS 10.15.4, *) {
      do {
        _ = try outputPipe.fileHandleForReading.readToEnd()
        try outputPipe.fileHandleForReading.close()
        
        _ = try errorPipe.fileHandleForReading.readToEnd()
        try errorPipe.fileHandleForReading.close()
      }
      catch {
        print("Error reading to end: \(error)")
      }
    } else {
      // Fallback on earlier versions
      _ = outputPipe.fileHandleForReading.readDataToEndOfFile()
      outputPipe.fileHandleForReading.closeFile()
      
      _ = errorPipe.fileHandleForReading.readDataToEndOfFile()
      errorPipe.fileHandleForReading.closeFile()
    }
    
    completionHandler?(
      status,
      reason
    )
  }
  
}
