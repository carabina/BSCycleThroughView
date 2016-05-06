//
//  BSCyclePlayView.swift
//  VehicleGroup
//
//  Created by 张亚东 on 16/5/4.
//  Copyright © 2016年 doyen. All rights reserved.
//

import UIKit
import SwiftyTimer

private struct Constants {
    static let CollectionReuseCellIdentifier = "BSCyclePlayCollectionCell"
}

class BSCyclePlayView: UIView {
    
    var cyclePlayImages: [UIImage]! {
        didSet {
            layoutIfNeeded()
            pageControl.numberOfPages = cyclePlayImages.count
            
            if cyclePlayImages.count > 1 {
                cyclePlayImages.insert(cyclePlayImages.last!, atIndex: 0)
                cyclePlayImages.insert(cyclePlayImages[1], atIndex: cyclePlayImages.count)
            }
            collectionView.reloadData()
            
            if cyclePlayImages.count > 1 {
                collectionView.contentOffset = CGPoint(x: collectionView.bounds.size.width, y: 0)
            }
        }
    }
    
    var timeInterval: NSTimeInterval = 5 {
        didSet {
            timer?.invalidate()
            newTimerStart()
        }
    }
    
    var cyclePlayEnabled:Bool = false {
        didSet {
            if cyclePlayEnabled == true {
                guard cyclePlayImages.count > 1 else {
                    return
                }
                
                newTimerStart()
            } else {
                timer?.invalidate()
            }
        }
    }
    
    var pageScale: CGFloat! {
        didSet {
            pageControl.transform = CGAffineTransformMakeScale(pageScale, pageScale)
        }
    }
    
    private var timer: NSTimer!

    private lazy var collectionView: UICollectionView = {
        
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .Horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.itemSize = self.bounds.size
        flowLayout.estimatedItemSize = self.bounds.size
        
        let collection: UICollectionView = UICollectionView(frame: self.bounds, collectionViewLayout: flowLayout)
        collection.dataSource = self
        collection.delegate = self
        collection.pagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.registerClass(BSCyclePlayCollectionCell.self, forCellWithReuseIdentifier: Constants.CollectionReuseCellIdentifier)
        return collection
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pc: UIPageControl = UIPageControl()
        pc.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height - 12)
        return pc
    }()
    
    private lazy var numberFormatter: NSNumberFormatter = {
        let fo: NSNumberFormatter = NSNumberFormatter()
        fo.positiveFormat = "0"

        return fo
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

}

extension BSCyclePlayView {
    
    func setup() {
        layoutIfNeeded()
        addSubview(collectionView)
        addSubview(pageControl)
        
        collectionView.addObserver(self, forKeyPath: "contentOffset", options: .New, context: nil)
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        guard cyclePlayImages.count > 1 else {
            return
        }
        
        let offsetX = collectionView.contentOffset.x
        let width = collectionView.bounds.size.width
        let floatIndex = Float(offsetX/width)
        var index = Int(offsetX/width)
        
        if index == cyclePlayImages.count - 1 {
            index = 1
        } else if index == 0 {
            index = cyclePlayImages.count - 1
        }
        
        pageControl.currentPage = Int(numberFormatter.stringFromNumber(NSNumber(float: floatIndex))!)! - 1
        
    }
    
    func adjustContentOffsetX() {
        
        let offsetX = collectionView.contentOffset.x
        let width = collectionView.bounds.size.width
        let index = offsetX/width
        
        if index >= CGFloat(cyclePlayImages.count - 1) {
            collectionView.setContentOffset(CGPoint(x: width, y: 0), animated: false)
        } else if index < 1 {
            collectionView.setContentOffset(CGPoint(x: width * CGFloat(cyclePlayImages.count - 2), y: 0), animated: false)
        }
    }
    
    func newTimerStart() {
        
        timer = NSTimer.new(every: self.timeInterval, {
            
            let offsetX = self.collectionView.contentOffset.x
            let width = self.collectionView.bounds.size.width
            let index = offsetX/width
            
            self.collectionView.setContentOffset(CGPoint(x: self.collectionView.bounds.width * CGFloat(index + 1), y: 0), animated: true)
        })
        timer?.start(modes: NSRunLoopCommonModes)
        
    }
}


extension BSCyclePlayView: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cyclePlayImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.CollectionReuseCellIdentifier, forIndexPath: indexPath) as! BSCyclePlayCollectionCell
        cell.cyclePlayImage = cyclePlayImages[indexPath.row]
        return cell
    }
}

extension BSCyclePlayView: UICollectionViewDelegate {
    
}

extension BSCyclePlayView: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        adjustContentOffsetX()
        
        if cyclePlayEnabled == true {
            newTimerStart()
        }
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        adjustContentOffsetX()
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if cyclePlayEnabled == true {
            timer?.invalidate()
        }
    }
    
}

