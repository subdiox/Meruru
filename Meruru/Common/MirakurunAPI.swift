//
//  MirakurunApi.swift
//  Meruru
//
//  Created by castaneai on 2019/04/06.
//  Copyright © 2019 castaneai. All rights reserved.
//

import Alamofire
import Then

public struct Status: Codable {
    let version: String
}

public struct Service: Codable {
    let id: Int
    let serviceId: Int
    let networkId: Int
    let name: String
    let channel: Channel
}

public struct Channel: Codable {
    let type: String
    let channel: String
}

public struct Program : Codable {
    let name: String
    let startAt: Int64
    let duration: Int64
}

public class MirakurunAPI {
    
    private let baseURL: URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    private func process<T>(response: DataResponse<T, AFError>, resolve: (T) -> Void, reject: (Error) -> Void) {
        if let error = response.error {
            reject(error)
        } else {
            switch response.result {
            case .success(let data):
                resolve(data)
            case .failure(let error):
                reject(error)
            }
        }
    }
    
    public func getStreamURL(service: Service) -> URL {
        return baseURL.appending(pathComponents: ["channels", service.channel.type, service.channel.channel, "services", String(service.serviceId), "stream"])
    }
    
    public func fetchPrograms(service: Service) -> Promise<[Program]> {
        let url = baseURL.appendingPathComponent("programs")
        let params: Parameters = [
            "serviceId": service.serviceId,
        ]
        return Promise<[Program]> { resolve, reject in
            AF.request(url, parameters: params, encoding: URLEncoding.default)
                .validate(statusCode: 200..<300)
                .responseDecodable { response in
                    self.process(response: response, resolve: resolve, reject: reject)
                }
        }
        
    }
    
    public func fetchStatus() -> Promise<Status> {
        let url = baseURL.appendingPathComponent("status")
        return Promise<Status> { resolve, reject in
            AF.request(url)
                .validate(statusCode: 200..<300)
                .responseDecodable { response in
                    self.process(response: response, resolve: resolve, reject: reject)
                }
        }
    }
    
    public func fetchServices() -> Promise<[Service]> {
        let url = baseURL.appendingPathComponent("services")
        return Promise<[Service]> { resolve, reject in
            AF.request(url)
                .validate(statusCode: 200..<300)
                .responseDecodable { response in
                    self.process(response: response, resolve: resolve, reject: reject)
                }
        }
    }
}
