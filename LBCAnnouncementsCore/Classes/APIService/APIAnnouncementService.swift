//
//  APIAnnouncementService.swift
//  LBCAnnouncementsCore
//
//  Created by Mouldi GABSI on 02/02/2021.
//

import Foundation

public enum APIAnnouncementService {
    case getAnnouncementList
}

extension MockAPIProtocol {
    public var jsonFileName : String? { return nil }
}

extension APIAnnouncementService: APIProtocol {
    
    var urlString: String {
        switch APIConfig.shared.environment {
        case .prod: return APIConfig.shared.scheme.rawValue + APIConfig.shared.baseUrl
        case .dev: return APIConfig.shared.scheme.rawValue + APIConfig.shared.baseUrl
        }
    }
    
    public var baseURL: URL? {
        guard let url = URL(string: urlString) else { fatalError("baseURL could not be configured.")}
        return url
    }
    
    public var path: String? {
        return "/leboncoin/paperclip/master/listing.json"
    }
    
    public var httpMethod: HttpMethod? {
        return .get
    }
    
    public var task: HTTPTask? {
        return .request
    }
    
    public var headers: HTTPHeaders? {
        return nil
    }
    
    
}
