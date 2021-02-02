//
//  APIRouter.swift
//  LBCAnnouncementsCore
//
//  Created by Mouldi GABSI on 02/02/2021.
//

import Foundation

public enum NetworkResponse:String {
    case success
    case authenticationError = "You need to be authenticated first."
    case badRequest = "Bad request"
    case outdated = "The url you requested is outdated."
    case failed = "Network request failed."
    case noData = "Response returned with no data to decode."
    case unableToDecode = "We could not decode the response."
}

public enum NetworkResult<String, Int>{
    case success
    case failure(String, Int)
}

public protocol NetworkRouter: class {
    associatedtype EndPoint: APIEndPointProtocol
    func request<N>(_ route: EndPoint) -> Result<N, APIError> where N : Decodable
    func cancel()
}


public class Router<EndPoint: APIEndPointProtocol>: NetworkRouter {
    
    public init() {}
    
    private var task: URLSessionTask?
    
    public func request<N>(_ route: EndPoint) -> Result<N, APIError>  where N : Decodable {
        
        //var returnedResult = try! Result<N, APIError>()
        var networkResponse : Result<N,APIError>
        let session = URLSession.shared
        do {
            let request = try self.buildRequest(from: route)
            NetworkLogger.log(request: request)
            task = session.dataTask(with: request, completionHandler: { data, response, error in
                
                if error != nil {
                    networkResponse =  .failure(APIError(type: .badRequest, message: "Please check your network connection."))
                    
                }
                
                if let response = response as? HTTPURLResponse {
                    let result = self.handleNetworkResponse(response)
                    switch result {
                    case .success:
                        guard let responseData = data else {
                            if N.self == Void.self {
                                if let voidResponse = () as? N {
                                    networkResponse = .success(voidResponse)
                                }
                            } else {
                                networkResponse = .failure(APIError(type: .emptyData, message: "No data returned!"))
                            }
                            return
                        }
                        do {
                            print(responseData)
                            let jsonData = try JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
                            print(jsonData)
                            let apiResponse = try JSONDecoder().decode(N.self, from: responseData)
                            networkResponse = .success(apiResponse)
                        }catch {
                            print(error)
                            networkResponse = .failure(APIError(type: .objectMapping, message: NetworkResponse.unableToDecode.rawValue))
                            
                        }
                    case .failure(let networkFailureError, let statusCode):
                        networkResponse = .failure(APIError(type: .networkFailure, message: networkFailureError, code: statusCode))
                        
                    }
                }
                
            })
        }catch {
            networkResponse = .failure(APIError(type: .badRequest, message: error.localizedDescription))
        }
        self.task?.resume()
        
        return networkResponse
    }
    
    public func cancel() {
        self.task?.cancel()
    }
    
    fileprivate func buildRequest(from route: EndPoint) throws -> URLRequest {
        
        var request = URLRequest(url: route.baseURL.appendingPathComponent(route.path),
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 10.0)
        
        request.httpMethod = route.httpMethod.rawValue
        do {
            switch route.task {
            case .request:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            case .requestParameters(let bodyParameters,
                                    let bodyEncoding,
                                    let urlParameters):
                
                try self.configureParameters(bodyParameters: bodyParameters,
                                             bodyEncoding: bodyEncoding,
                                             urlParameters: urlParameters,
                                             request: &request)
                
            case .requestParametersAndHeaders(let bodyParameters,
                                              let bodyEncoding,
                                              let urlParameters,
                                              let additionalHeaders):
                
                self.addAdditionalHeaders(additionalHeaders, request: &request)
                try self.configureParameters(bodyParameters: bodyParameters,
                                             bodyEncoding: bodyEncoding,
                                             urlParameters: urlParameters,
                                             request: &request)
            }
            return request
        } catch {
            throw error
        }
    }
    
    fileprivate func configureParameters(bodyParameters: [APIQueryParam]?,
                                         bodyEncoding: ParameterEncoding,
                                         urlParameters: [APIQueryParam]?,
                                         request: inout URLRequest) throws {
        do {
            try bodyEncoding.encode(urlRequest: &request,
                                    bodyParameters: bodyParameters, urlParameters: urlParameters)
        } catch {
            throw error
        }
    }
    
    fileprivate func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    fileprivate func handleNetworkResponse(_ response: HTTPURLResponse) -> NetworkResult<String, Int> {
        switch response.statusCode {
        case 200...299: return .success
        case 401...500: return .failure(NetworkResponse.authenticationError.rawValue, response.statusCode)
        case 501...599: return .failure(NetworkResponse.badRequest.rawValue, response.statusCode)
        case 600: return .failure(NetworkResponse.outdated.rawValue, response.statusCode)
        default: return .failure(NetworkResponse.failed.rawValue, response.statusCode)
        }
    }
    
}
