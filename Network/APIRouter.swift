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
    associatedtype EndPoint: APIProtocol
    func request<N>(_ route: EndPoint, completion: @escaping (Result<N, APIError>) -> Void) where N : Decodable
    func cancel()
}

public typealias APIProtocol = APIEndPointProtocol & MockAPIProtocol

public class Router<EndPoint: APIProtocol>: NetworkRouter {
    
    public init() {}
    
    private var task: URLSessionTask?
    
    public func request<N>(_ route: EndPoint, completion: @escaping (Result<N, APIError>) -> Void) where N : Decodable {
        
        if let fileName = route.jsonFileName {
            self.returnMockFrom(fileName: fileName, completion: completion)
        } else {
            self.performNetworkRequest(route, completion: completion)
        }
        
    }
    
    private func returnMockFrom<N>(fileName: String,  completion: @escaping (Result<N, APIError>) -> Void) where N : Decodable {
        
        if let jsonData = JSONFileReader.readFile(fileName) {
            do {
                print("readed json  ----> \(jsonData)")
                let apiResponse = try JSONDecoder().decode(N.self, from: jsonData)
                completion(.success(apiResponse))
            }catch {
                print(error)
                print("readed json  error ----> \(error)")
                completion(.failure(APIError(type: .objectMapping, message: NetworkResponse.unableToDecode.rawValue)))
                
            }
        } else {
            completion(.failure(APIError(type: .objectMapping, message: "Invalid JSON File!")))
        }
    }
    
    private func performNetworkRequest<N>(_ route: EndPoint, completion: @escaping (Result<N, APIError>) -> Void) where N : Decodable {
        
        
        let session = URLSession.shared
        do {
            let request = try self.buildRequest(from: route)
            if let _request = request {
                NetworkLogger.log(request: _request)
                task = session.dataTask(with: _request, completionHandler: { data, response, error in
                    
                    if error != nil {
                        completion(.failure(APIError(type: .badRequest, message: "Please check your network connection.")))
                        
                    }
                    
                    if let response = response as? HTTPURLResponse {
                        let result = self.handleNetworkResponse(response)
                        switch result {
                        case .success:
                            guard let responseData = data else {
                                if N.self == Void.self {
                                    if let voidResponse = () as? N {
                                        completion(.success(voidResponse))
                                    }
                                } else {
                                    completion(.failure(APIError(type: .emptyData, message: "No data returned!")))
                                }
                                return
                            }
                            do {
                                print(responseData)
                                let jsonData = try JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
                                print(jsonData)
                                let apiResponse = try JSONDecoder().decode(N.self, from: responseData)
                                completion(.success(apiResponse))
                            }catch {
                                print(error)
                                completion(.failure(APIError(type: .objectMapping, message: NetworkResponse.unableToDecode.rawValue)))
                                
                            }
                        case .failure(let networkFailureError, let statusCode):
                            completion(.failure(APIError(type: .networkFailure, message: networkFailureError, code: statusCode)))
                            
                        }
                    }
                    
                })
            } else {
                completion(.failure(APIError(type: .badRequest, message: "empty Request Fields")))
            }
            
        }catch {
            completion(.failure(APIError(type: .badRequest, message: error.localizedDescription)))
        }
        self.task?.resume()
    }
    
    public func cancel() {
        self.task?.cancel()
    }
    
    fileprivate func buildRequest(from route: EndPoint) throws -> URLRequest? {
        guard let baseURL = route.baseURL, let path = route.path, let httpMethod = route.httpMethod, let task = route.task else {
            print("empty Request items")
            return nil
        }
        var request = URLRequest(url: baseURL.appendingPathComponent(path),
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 10.0)
        
        request.httpMethod = httpMethod.rawValue
        do {
            switch task {
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
