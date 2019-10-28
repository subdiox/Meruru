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
    public func debugLog() -> Self {
        #if DEBUG
        debugPrint(self)
        #endif
        return self
    }
}
