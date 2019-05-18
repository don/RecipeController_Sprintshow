//
//  SubscriptionCell.swift
//  youtube
//
//  Created by Brian Voong on 10/15/18.
//  Copyright © 2018 letsbuildthatapp. All rights reserved.
//

import UIKit

class SubscriptionCell: FeedCell {
    
    override func fetchVideos() {
        ApiService.shared.fetchSubscriptionFeed { (videos) in
            self.videos = videos
            self.collectionView.reloadData()
        }
    }
    
}
