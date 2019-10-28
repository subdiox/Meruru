//
//  Extension.swift
//  Meruru
//
//  Created by subdiox on 2019/10/28.
//  Copyright © 2019 castaneai. All rights reserved.
//

import Cocoa
import Alamofire

extension URL {
    func appending(pathComponents: [String]) -> URL {
        var url = self
        for component in pathComponents {
            url = url.appendingPathComponent(component)
        }
        return url
    }
}

extension Request {
    func debugLog() -> Self {
        #if DEBUG
        debugPrint(self)
        #endif
        return self
    }
}

extension Array where Element == Service {
    func getChannelTypes() -> [String] {
        var channelTypes: [String] = []
        for element in self {
            let service = element as Service
            if !channelTypes.contains(service.channel.type) {
                channelTypes.append(service.channel.type)
            }
        }
        return channelTypes
    }
}
