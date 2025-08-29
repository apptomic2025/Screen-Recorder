//
//  CustomCropView.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 19/3/25.
//

import UIKit

protocol CropViewDelegate: AnyObject {
    func cropSelected(_ crop: CropModel)
    func dismissCropView()
    func doneCrop()
}

class CustomCropView: UIView {
    
    weak var delegate: CropViewDelegate?
    var selectedIndexPath : IndexPath?
    
    var cropArray:[CropModel] = [CropModel(icon: "dOrginal", title: "Orginal",cellWidth: 30, ratio: 0),
                                 CropModel(icon: "dReels", title: "Reels",cellWidth: 30, ratio: 0.5625),
                                 CropModel(icon: "dStory", title: "Story",cellWidth: 30, ratio: 0.5625),
                                 CropModel(icon: "dTikTok", title: "TikTok",cellWidth: 30, ratio: 0.5625),
                                 CropModel(icon: "dSquare", title: "Square",cellWidth: 30, ratio: 1),
                                 CropModel(icon: "d3_4", title: "3:4",cellWidth: 30, ratio: 0.75),
                                 CropModel(icon: "d9_16", title: "9:16",cellWidth: 30, ratio: 0.5625),
                                 CropModel(icon: "dYouTube", title: "YouTube",cellWidth: 30, ratio: 1.78),
                                 CropModel(icon: "dSnapchat", title: "Snapchat",cellWidth: 30, ratio: 0.5625),
                                 CropModel(icon: "dShorts", title: "Shorts",cellWidth: 30, ratio: 0.8),
                                 CropModel(icon: "d16_9", title: "16:9",cellWidth: 30, ratio: 1.78),
                                 CropModel(icon: "d4_3", title: "4:3",cellWidth: 30, ratio: 1.33),
                                 CropModel(icon: "d5_4", title: "5:4",cellWidth: 30, ratio: 1.25)]
    
    let identifier = "CropCollectionViewCell"
    
    @IBOutlet weak var videoCropCollectionView:UICollectionView!{
        didSet{
            self.videoCropCollectionView.delegate = self
            self.videoCropCollectionView.dataSource = self
            self.videoCropCollectionView.register(UINib(nibName: identifier, bundle: nil), forCellWithReuseIdentifier: identifier)
            self.videoCropCollectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            self.videoCropCollectionView.backgroundColor = .white
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    /// It is used when you create the view programmatically.
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }

    private func commonInit() {
        /// Loading the nib
        guard let contentView = self.fromNib() else {
            debugPrint("View could not load from nib")
            return
        }
        
        contentView.frame = self.bounds
        addSubview(contentView)
        
       
    }

    
    @IBOutlet weak var navVView: UIView!
    
    @IBAction func dismiss(){
        self.delegate?.dismissCropView()
    }
    @IBAction func done(){
        self.delegate?.doneCrop()
    }
}

extension CustomCropView :UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cropArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CropCollectionViewCell
        
        let crop = self.cropArray[indexPath.item]
        cell.imgView.contentMode = .scaleAspectFit
        if let sourceImage = UIImage(named: crop.icon){
            cell.imgView.image = sourceImage
            cell.selectedImgView.image = UIImage(named: String(crop.icon.dropFirst()))
        }
        
        cell.lbl.text = crop.title
        cell.lbl.textColor = .gray
        cell.lbl.textColor = (selectedIndexPath != nil && indexPath == selectedIndexPath) ? .white : .gray
        cell.selectedImgView.isHidden = (selectedIndexPath != nil && indexPath == selectedIndexPath) ? false : true
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = videoCropCollectionView.cellForItem(at: indexPath) as? CropCollectionViewCell {
            cell.selectedImgView.isHidden = true
            cell.lbl.textColor = .gray
            selectedIndexPath = nil
        }
    }
    
}

extension CustomCropView :UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.cropSelected(self.cropArray[indexPath.item])

        let cell = videoCropCollectionView.cellForItem(at: indexPath) as! CropCollectionViewCell
        cell.selectedImgView.isHidden = false
        cell.lbl.textColor = .white
        self.selectedIndexPath = indexPath
        scrollCollectionViewToIndex(itemIndex: indexPath.item)
    }
    
    func scrollCollectionViewToIndex(itemIndex: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let indexPath = IndexPath(item: itemIndex, section: 0)
            self.videoCropCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

extension CustomCropView :UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 46, height: 45)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
}
