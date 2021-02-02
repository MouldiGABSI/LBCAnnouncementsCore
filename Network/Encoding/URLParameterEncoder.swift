//
//  URLParameterEncoder.swift
//  LBCAnnouncementsCore
//
//  Created by Mouldi GABSI on 01/02/2021.
//

import Foundation

struct URLParameterEncoder: ParameterEncoder {
     func encode(urlRequest: inout URLRequest, with parameters: [APIQueryParam]) throws {
        
        guard let url = urlRequest.url else { throw NetworkError.missingURL }
        
        if var urlComponents = URLComponents(url: url,
                                             resolvingAgainstBaseURL: false), !parameters.isEmpty {
            
            urlComponents.queryItems = [URLQueryItem]()
            
            parameters.forEach({ (param) in
                if let value = param.value {
                    let queryItem = URLQueryItem(name: param.key,
                                                 value: "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
                    urlComponents.queryItems?.append(queryItem)
                }
            })
            urlRequest.url = urlComponents.url
        }
        
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        
    }
}
