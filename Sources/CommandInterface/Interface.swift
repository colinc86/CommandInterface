//
//  Interface.swift
//  MedinaCommandInterface
//
//  Created by Colin Campbell on 8/9/21.
//

import Foundation
import SwiftShell

public class Interface {
  
  typealias DataHandler = (_ data: Data) -> Void
  
  public enum ResponseError: Error, CustomStringConvertible {
    case string(_ string: String)
    
    public var description: String {
      switch self {
      case .string(let string):
        return string
      }
    }
  }
  
  public let context: Context
  
  public var currentCommand: AsyncCommand?
  
  // MARK: Initializers
  
  public init(context: Context) {
    self.context = context
  }
  
  public convenience init?(workingDirectory: URL? = nil, environment: [String: String]? = nil) {
    var context = CustomContext(main)
    
    // Set the working directory
    if let workingDirectory = workingDirectory {
      context.currentdirectory = workingDirectory.path
    }
    
    // Set the env vars
    if let environment = environment {
      context.env = environment
    }
    
    self.init(context: context)
  }
  
}

// MARK: - Public methods

extension Interface {
  
  public func send<T: Command>(
    command: T,
    password: String? = nil,
    _ output: ((_ data: Data) -> Void)? = nil,
    _ completion: ((_ exitCode: Int, _ reason: Process.TerminationReason, _ output: T.Response?, _ error: Error?) -> Void)? = nil) throws
  {
    // Stop any current command execution
    if currentCommand?.isRunning == true {
      currentCommand?.stop()
    }
    
    // Set the output handler
    context.stdin.onOutput { stream in
      output?(stream.readSomeData() ?? Data())
    }
    
    // Run the command
    currentCommand = context.stdin.runAsync(command.terms).onCompletion {cmd in
      var error: Error?
      if let errorString = String(data: cmd.stderror.readData(), encoding: .utf8), !errorString.isEmpty {
        error = ResponseError.string(errorString)
      }
      
      completion?(
        cmd.exitcode(),
        cmd.terminationReason(),
        command.parse(cmd.stdout.readData()),
        error)
    }
    
    // Send a password if needed
    if command.sudo, let password = password {
      context.stdout.write(password + "\n")
    }
  }
  
}
