//
//  TrendingCell.swift
//  youtube
//
//  Created by Brian Voong on 10/15/18.
//  Copyright © 2018 letsbuildthatapp. All rights reserved.
//

import UIKit

class TrendingCell: FeedCell {
    
    override func fetchVideos() {
        ApiService.shared.fetchTrendingFeed { (videos) in
            self.videos = videos
            self.collectionView.reloadData()
        }
    }
    
}
