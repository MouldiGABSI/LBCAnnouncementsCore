//
//  APIError.swift
//  LBCAnnouncementsCore
//
//  Created by Mouldi GABSI on 02/02/2021.
//

import Foundation

public struct APIError: Error, CustomStringConvertible {
    
    public enum ErrorType {
        /// Payment Denied: the payment hasn't been approuved by the server
        case networkFailure
        /// Login Failed: The user could not be logged in
        case cannotFetch
        /// NotFound: the ressource was not found
        case notFound
        /// EmptyData: the result can not be parsed
        case emptyData
        /// RequestFailed: the api sent an error message
        case requestFailed
        /// ObjectMapping: the service could not map data
        case objectMapping
        /// Could not perform request, authentication is required
        case authenticationRequired
        /// Could not build request
        case badRequest
        /// Custom server errors
        case serverError
        /// Custom error for APIContentRequest
        case badType
       
    }
    
    let type: ErrorType
    let message: String
    let code: Int
    
    public init(type: ErrorType, message: String, code: Int = 0) {
        self.type = type
        self.message = message
        self.code = code
    }
    
    public var description: String {
        return self.message
    }
}
