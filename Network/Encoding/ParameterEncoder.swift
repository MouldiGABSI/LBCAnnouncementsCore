//
//  ParameterEncoder.swift
//  LBCAnnouncementsCore
//
//  Created by Mouldi GABSI on 01/02/2021.
//

import Foundation

public protocol ParameterEncoder {
    func encode(urlRequest: inout URLRequest, with parameters: [APIQueryParam]) throws
}

public enum ParameterEncoding {
    
    case urlEncoding
    case jsonEncoding
    case urlAndJsonEncoding
    
    func encode(urlRequest: inout URLRequest,
                bodyParameters: [APIQueryParam]?,
                urlParameters: [APIQueryParam]?) throws {
        do {
            switch self {
            case .urlEncoding:
                guard let urlParameters = urlParameters else { return }
                try URLParameterEncoder().encode(urlRequest: &urlRequest, with: urlParameters)
                
            case .jsonEncoding:
                guard let bodyParameters = bodyParameters else { return }
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: bodyParameters)
                
            case .urlAndJsonEncoding:
                guard let bodyParameters = bodyParameters,
                      let urlParameters = urlParameters else { return }
                try URLParameterEncoder().encode(urlRequest: &urlRequest, with: urlParameters)
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: bodyParameters)
                
            }
        }catch {
            throw error
        }
    }
}


public enum NetworkError : String, Error {
    case parametersNil = "Parameters were nil."
    case encodingFailed = "Parameter encoding failed."
    case missingURL = "URL is nil."
}
