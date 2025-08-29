//
//  IntroVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/2/25.
//

import UIKit

struct IntroModel {
    var image: String
    var title: String
    var subTitle: String
}

class IntroCVCell: UICollectionViewCell {
    
    @IBOutlet weak var introImgView: UIImageView!
    override class func awakeFromNib() {
        
    }
}


class IntroVC: UIViewController {
    
    var lastContentOffset: CGFloat = 0.0
    
    private var selectedIndex = 0
    private var currentindex = 0
    var lastIndex = 0
    var scrollCount = 0
    var requestFromManual = false
    
    var items: [IntroModel] = [IntroModel(image: "bgImage1", title: "screen recorder", subTitle: "Record your Screen\nGames, Apps, Tutorial, Everything."),IntroModel(image: "bgImage3", title: "video editor", subTitle: "The Powerful\nVideo Editing Experience."),IntroModel(image: "bgImage2", title: "Video Cropper", subTitle: "Optimized\nFor Social Media."),IntroModel(image: "bgImage4", title: "photo to video", subTitle: "Turn your favorite\nPhotos into Video! "),IntroModel(image: "bgImage5", title: "live broadcast", subTitle: "Easily Live Streams\nto Facebook, YouTube, Twitch, and other Platforms at the Same Time.")]
    //"Live Stream\nto all Platforms"
    //"Easily broadcast Live streams to Facebook, YouTube, Twitch and others platforms at the same time"
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var titleLbl: UILabel!{
        didSet{
            titleLbl.text = items[0].title.uppercased()
        }
    }
    @IBOutlet weak var subTitleLbl: UILabel!{
        didSet{
            subTitleLbl.text = items[0].subTitle
        }
    }
    @IBOutlet weak var previousBtn: UIView!{
        didSet{
            previousBtn.isHidden = true
        }
    }
    @IBOutlet weak var introCollectionView: UICollectionView!{
        didSet{
            introCollectionView.dataSource = self
            introCollectionView.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    @IBAction func nextBtnAction(){
        
        self.introCollectionView.isPagingEnabled = false
        if selectedIndex + 1 < 5{
            hepticFeedBack()
            self.introCollectionView.scrollToItem(at: IndexPath(item: selectedIndex+1, section: 0), at: .right, animated: true)
            selectedIndex = selectedIndex + 1
            previousBtn.isHidden = !(selectedIndex > 0)
            DispatchQueue.main.async {
                self.titleLbl.text = self.items[self.selectedIndex].title.uppercased()
                self.subTitleLbl.text = self.items[self.selectedIndex].subTitle
            }
            requestFromManual = true
        }else{
            if self.selectedIndex == items.count - 1{
                if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPVC") as? IAPVC {
                    iapViewController.modalPresentationStyle = .fullScreen
                    //self.present(iapViewController, animated: true, completion: nil)
                    self.navigationController?.pushViewController(iapViewController, animated: true)
                }
            }

        }
        pageControl.currentPage = selectedIndex
        self.introCollectionView.isPagingEnabled = true
    }
    @IBAction func previousBtnAction(){
        self.introCollectionView.isPagingEnabled = false
        if selectedIndex - 1 >= 0{
            hepticFeedBack()
            self.introCollectionView.scrollToItem(at: IndexPath(item: selectedIndex-1, section: 0), at: .left, animated: true)
            selectedIndex = selectedIndex - 1
            previousBtn.isHidden = (selectedIndex == 0)
            DispatchQueue.main.async {
                self.titleLbl.text = self.items[self.selectedIndex].title.uppercased()
                self.subTitleLbl.text = self.items[self.selectedIndex].subTitle
            }
        }
        pageControl.currentPage = selectedIndex
        self.introCollectionView.isPagingEnabled = true
    }
    @IBAction func skipBtnAction(){
        
        hepticFeedBack()
        
        if AppData.premiumUser{
            
//            if let navVC = loadVCfromStoryBoard(name: "Main", identifier: "LightNavVC") as? LightNavVC{
//                DELEGATE.window?.rootViewController = navVC
//                UIView.transition(with: DELEGATE.window!, duration: 0.7, options: .transitionCrossDissolve, animations: nil, completion: nil)
//            }
            
        }else{
            if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPVC") as? IAPVC {
                iapViewController.modalPresentationStyle = .fullScreen
                //self.present(iapViewController, animated: true, completion: nil)
                self.navigationController?.pushViewController(iapViewController, animated: true)
            }
        }
    }
}

extension IntroVC: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! IntroCVCell
        cell.introImgView.image = UIImage(named: self.items[indexPath.item].image)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
}


extension IntroVC: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: DEVICE_WIDTH, height: DEVICE_HEIGHT)
    }
}

extension IntroVC: UIScrollViewDelegate{
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView){
        
        let visibleRect = CGRect(origin: introCollectionView.contentOffset, size: introCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        if let visibleIndexPath = introCollectionView.indexPathForItem(at: visiblePoint){
            selectedIndex = visibleIndexPath.item
            
            if selectedIndex != lastIndex{
                lastIndex = selectedIndex
                hepticFeedBack()
                DispatchQueue.main.async {
                    
                    self.titleLbl.text = self.items[self.selectedIndex].title.uppercased()
                    self.subTitleLbl.text = self.items[self.selectedIndex].subTitle

                }
                
            }
                
            if selectedIndex == 0{
                previousBtn.isHidden = true
            }else{
                previousBtn.isHidden = false
            }
            pageControl.currentPage = selectedIndex
        }
        
        requestFromManual = false
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if lastContentOffset > scrollView.contentOffset.x {
            print("Scrolling left")
        } else if lastContentOffset < scrollView.contentOffset.x && !requestFromManual{
            print("Scrolling right")
            if self.selectedIndex == items.count - 1{
                if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPVC") as? IAPVC {
                    iapViewController.modalPresentationStyle = .fullScreen
                    //self.present(iapViewController, animated: true, completion: nil)
                    self.navigationController?.pushViewController(iapViewController, animated: true)
                }
            }
            
        }

        lastContentOffset = scrollView.contentOffset.x
    }
}

