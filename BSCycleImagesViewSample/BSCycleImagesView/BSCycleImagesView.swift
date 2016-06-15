//
//  BSCycleImagesView.swift
//  VehicleGroup
//
//  Created by 张亚东 on 16/5/4.
//  Copyright © 2016年 doyen. All rights reserved.
//

import UIKit
import SwiftyTimer
import AlamofireImage

private struct Constants {
    static let CollectionReuseCellIdentifier = "BSCycleImagesCollectionCell"
}

public class BSCycleImagesView: UIView {
    
    public typealias ImageClosure = (index: Int) -> Void
    public typealias Closure = () -> Void
    
    public var imageDidSelectedClousure: ImageClosure?
    public var imageDidStartDownload: Closure? {
        didSet {
            if isDownloading {
                imageDidStartDownload?()
            }
        }
    }
    public var imageDidFinishDownload: Closure?
    
    //set images, images == 1 cannot cycle play
    public var images: [UIImage] = [] {
        didSet {
            
            pageControl.numberOfPages = images.count
            
            if images.count <= 1 {
                pageControl.hidden = true
            } else {
                pageControl.hidden = false
                
                images.insert(images.last!, atIndex: 0)
                images.insert(images[1], atIndex: images.count)
            }
            collectionView.reloadData()
            
            if images.count > 1 {
                collectionView.contentOffset = CGPoint(x: collectionView.bounds.size.width, y: 0)
            }
            
            restartTimer()
        }
    }
    
    public var imageURLs: [String] = [] {
        didSet {
            startDownloadImages()
        }
    }
    
    //set timeinterval to start cycle play, 0 = stop, default is 0
    public var timeInterval: NSTimeInterval = 0
    
    public var pageScale: CGFloat! {
        didSet {
            pageControl.transform = CGAffineTransformMakeScale(pageScale, pageScale)
        }
    }
    
    private var imageDownloader = ImageDownloader()
    private var isDownloading = false
    
    private var timer: NSTimer!
    
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .Horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        return flowLayout
    }()

    private lazy var collectionView: UICollectionView = {
        
        let collection: UICollectionView = UICollectionView(frame: self.bounds, collectionViewLayout: self.flowLayout)
        collection.dataSource = self
        collection.delegate = self
        collection.pagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.registerClass(BSCycleImagesCollectionCell.self, forCellWithReuseIdentifier: Constants.CollectionReuseCellIdentifier)
        collection.backgroundColor = UIColor.clearColor()
        return collection
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pc: UIPageControl = UIPageControl()
        pc.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height - 12)
        return pc
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        
        flowLayout.itemSize = bounds.size
        flowLayout.estimatedItemSize = bounds.size
        collectionView.frame = bounds
        pageControl.center = CGPoint(x: bounds.size.width/2, y: bounds.size.height - 12)
        
        if images.count > 1 {
            collectionView.contentOffset = CGPoint(x: collectionView.bounds.size.width, y: 0)
        }
    }

}

extension BSCycleImagesView {
    
    func setup() {
    
        addSubview(collectionView)
        addSubview(pageControl)
    }
    
    func startDownloadImages() {
        
        guard imageURLs.count != 0 else {
            return
        }
        
        isDownloading = true
        imageDidStartDownload?()
        
        var URLStringAndImage: [String : UIImage] = [:]
        imageURLs.forEach {
            let request = NSURLRequest(URL: NSURL(string: $0)!)
            imageDownloader.downloadImage(URLRequest: request) { [weak self] (response) in
                
                guard let strongSelf = self else {
                    return
                }
                strongSelf.isDownloading = false
                
                if case .Success(let image) = response.result {
                    let URLString = response.response!.URL!.absoluteString
                    URLStringAndImage[URLString] = image
                } else if case .Failure(let error) = response.result {
                    print(error)
                }
                
                if URLStringAndImage.count == strongSelf.imageURLs.count {
                    strongSelf.imageDidFinishDownload?()
                    strongSelf.images = strongSelf.imageURLs.map({ (URLString: String) -> UIImage in
                        URLStringAndImage[URLString]!
                    })
                }
            }
        }
    }
    
    func restartTimer() {
        guard images.count > 1 else {
            return
        }
        
        timer?.invalidate()
        
        if timeInterval != 0 {
            startTimer()
        }
    }

    func startTimer() {
        
        timer = NSTimer.new(every: self.timeInterval, { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            let offsetX = strongSelf.collectionView.contentOffset.x
            let width = strongSelf.collectionView.bounds.size.width
            let index = offsetX/width
            
            strongSelf.collectionView.setContentOffset(CGPoint(x: strongSelf.collectionView.bounds.width * CGFloat(index + 1), y: 0), animated: true)
        })
        timer?.start(modes: NSRunLoopCommonModes)
    }
    
    func adjustImagePosition() {
        
        let offsetX = collectionView.contentOffset.x
        let width = collectionView.bounds.size.width
        let index = offsetX/width
        
        if index >= CGFloat(images.count - 1) {
            collectionView.setContentOffset(CGPoint(x: width, y: 0), animated: false)
        } else if index < 1 {
            collectionView.setContentOffset(CGPoint(x: width * CGFloat(images.count - 2), y: 0), animated: false)
        }
    }
}


extension BSCycleImagesView: UICollectionViewDataSource {
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.CollectionReuseCellIdentifier, forIndexPath: indexPath) as! BSCycleImagesCollectionCell
        cell.cycleImage = images[indexPath.row]
        return cell
    }
}

extension BSCycleImagesView: UICollectionViewDelegate {
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var index = indexPath.row - 1
        if images.count <= 1 {
            index += 1
        }
        imageDidSelectedClousure?(index: index)
    }
}

extension BSCycleImagesView: UIScrollViewDelegate {
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        adjustImagePosition()
        
        if timeInterval != 0 {
            restartTimer()
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        adjustImagePosition()
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if timeInterval != 0 {
            timer?.invalidate()
        }
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        guard images.count > 1 else {
            return
        }
        
        layoutIfNeeded()
        let offsetX = collectionView.contentOffset.x
        let width = collectionView.bounds.size.width
        let floatIndex = Float(offsetX/width)
        var index = Int(offsetX/width)
        
        if index == images.count - 1 {
            index = 1
        } else if index == 0 {
            index = images.count - 1
        }
        
        pageControl.currentPage = Int(round(floatIndex)) - 1
        
        let a = Float(0.5)
        let b = Float(images.count - 2) + 0.5
        
        if floatIndex >= b {
            pageControl.currentPage = 0
        } else if floatIndex <= a {
            pageControl.currentPage = Int(b - 0.5)
        }
        
    }
    
}

