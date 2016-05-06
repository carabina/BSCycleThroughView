//
//  BSCyclePlayCollectionCell.swift
//  VehicleGroup
//
//  Created by 张亚东 on 16/5/4.
//  Copyright © 2016年 doyen. All rights reserved.
//

import UIKit

class BSCyclePlayCollectionCell: UICollectionViewCell {
    
    var cyclePlayImage: UIImage! {
        didSet {
            imgView.image = cyclePlayImage
        }
    }
    
    lazy var imgView: UIImageView = {
        let imgView: UIImageView = UIImageView(frame: self.bounds)
        imgView.contentMode = .ScaleAspectFill
        return imgView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BSCyclePlayCollectionCell {
    
    func setup() {
        addSubview(imgView)
    }
}
