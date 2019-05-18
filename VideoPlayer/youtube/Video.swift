//
//  Video.swift
//  youtube
//
//  Created by Brian Voong on 6/9/16.
//  Copyright © 2016 letsbuildthatapp. All rights reserved.
//

import UIKit

struct Video: Decodable {
    
    var thumbnailImageName: String?
    var title: String?
    var numberOfViews: Int?
    var uploadDate: Date?
    
    var channel: Channel?
    
}

struct Channel: Decodable {
    var name: String?
    var profileImageName: String?
}
