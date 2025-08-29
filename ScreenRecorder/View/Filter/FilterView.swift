//
//  FilterView.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 19/3/25.
//

import UIKit

var CIFilterNames = ["",
                     "",
                     "CIDepthOfField",
                     "CIPhotoEffectInstant",
                     "CIEdges",
                     "CIPhotoEffectNoir",
                     "CIPhotoEffectProcess",
                     "CIPhotoEffectTonal",
                     "CIPhotoEffectTransfer",
                     "CIEdgeWork",
                     "CIGloom",
                     "CIHeightFieldFromMask",
                     "CIHexagonalPixellate",
                     "CIHighlightShadowAdjust",
                     "CILineOverlay",
                     "CIPixellate",
                     "CIPointillize",
                     "CISpotLight",
                     "CIKaleidoscope",
                     "CIBarsSwipeTransition",
                     "CIDissolveTransition",
                     "CIPageCurlTransition",
                     "CIPageCurlTransition",
                     "CIPageCurlWithShadowTransition",
                     "CIBoxBlur",
                     "CIDiscBlur",
                     "CIGaussianBlur",
                     "CIMaskedVariableBlur",
                     "CIMotionBlur",
                     "CINoiseReduction",
                     "CIColorClamp",
                     "CIColorControls",
                     "CIColorMatrix",
                     "CIColorPolynomial",
                     "CIExposureAdjust",
                     "CIGammaAdjust",
                     "CIHueAdjust",
                     "CILinearToSRGBToneCurve",
                     "CISRGBToneCurveToLinear",
                     "CITemperatureAndTint",
                     "CIToneCurve",
                     "CIVibrance",
                     "CIWhitePointAdjust",
                     "CIColorCrossPolynomial",
                     "CIColorCube",
                     "CIColorCubeWithColorSpace",
                     "CIColorInvert",
                     "CIColorMonochrome",
                     "CIColorPosterize",
                     "CIFalseColor",
                     "CIMaskToAlpha",
                     "CIMaximumComponent",
                     "CIMinimumComponent",
                     "CISepiaTone",
                     "CIVignette",
                     "CIVignetteEffect",
                     "CIBumpDistortion",
                     "CIBumpDistortionLinear",
                     "CICircularWrap",
                     "CIDisplacementDistortion",
                     "CIGlassDistortion",
                     "CIGlassLozenge"
]

var filterPropertyList: [String:String] = [
    "Original":"No Filter",
    "Chrome":"CIPhotoEffectChrome",
    "Fade":"CIPhotoEffectFade",
    "Instant":"CIPhotoEffectInstant",
    "Mono":"CIPhotoEffectMono",
    "Noir":"CIPhotoEffectNoir",
    "Process":"CIPhotoEffectProcess",
    "Tonal":"CIPhotoEffectTonal",
    "Transfer":"CIPhotoEffectTransfer",
    "Tone":"CILinearToSRGBToneCurve",
    "Linear":"CISRGBToneCurveToLinear",
    "Bloom":"CIBloom",
    "Comic":"CIComicEffect",
    "Luminance":"CISharpenLuminance",
    "Crystallize":"CICrystallize",
    "Field":"CIDepthOfField",
    "Gloom":"CIGloom",
    "Pixellate":"CIHexagonalPixellate",
    "Adjust":"CIHighlightShadowAdjust",
    "Late":"CIPixellate",
    "Pointillize":"CIPointillize",
    "Transition":"CIBarsSwipeTransition"
]

let filterNames = [
    "Original",
    "Chrome",
    "Fade",
    "Instant",
    "Mono",
    "Noir",
    "Process",
    "Tonal",
    "Transfer",
    "Tone",
    "Linear",
    "Bloom",
    "Comic",
    "Luminance",
    "Crystallize",
    "Field",
    "Gloom",
    "Pixellate",
    "Adjust",
    "Late",
    "Pointillize",
    "Transition",
]


protocol FilterViewDelegate: AnyObject {
    func filterSelected(_ filter: VideoFilter)
    func dismissFilterView()
    func doneFilter()
}

class FilterView: UIView {
    
    var sourceImage: UIImage?
    private let contexts = CIContext(options: nil)
    let identifier = "FilterCollectionViewCell"
    private var filters = [VideoFilter]()
    weak var delegate: FilterViewDelegate?

    var selectedIndexPath : IndexPath?

    @IBOutlet weak var videoFilterCollectionView:UICollectionView!{
        didSet{
            self.videoFilterCollectionView.delegate = self
            self.videoFilterCollectionView.dataSource = self
            self.videoFilterCollectionView.register(UINib(nibName: identifier, bundle: nil), forCellWithReuseIdentifier: identifier)
            self.videoFilterCollectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    /// It is used when you create the view programmatically.
    init(frame: CGRect, sourceImage: UIImage) {
        super.init(frame: frame)
        
        self.sourceImage = sourceImage
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
        
        self.loadFilters()
    }

    
    private func loadFilters(){
        
        filters = filterNames.map { filterName in
            return VideoFilter(filterName: filterPropertyList[filterName] ?? "No Filter", filterDisplayName: filterName, isSelected: false)
        }
        self.filters[0].isSelected = true
        self.videoFilterCollectionView.reloadData()
    }
    
    private func createFilteredImage(filterName: String, image: UIImage) -> UIImage? {
        // 1 - create source image
        let sourceImage = CIImage(image: image)
        
        // 2 - create filter using name
        let filter = CIFilter(name: filterName)
        
        
        if let filter = filter{
            filter.setDefaults()
            
            // 3 - set source image
            filter.setValue(sourceImage, forKey: kCIInputImageKey)
            
            // 4 - output filtered image as cgImage with dimension.
            if let outputImage = filter.outputImage,let outputCGImage = contexts.createCGImage((outputImage), from: (outputImage.extent)){
                
                // 5 - convert filtered CGImage to UIImage
                let filteredImage = UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
                
                return filteredImage
            }
            
            
            
        }
        
        return nil
    }
    
    @IBAction func dismiss(){
        self.delegate?.dismissFilterView()
    }
    @IBAction func done(){
        self.delegate?.doneFilter()
    }
}

extension FilterView :UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! FilterCollectionViewCell
        
        let filter = self.filters[indexPath.item]
        
        if let sourceImage = self.sourceImage{
            
            if indexPath.item == 0{
                cell.imgView.image = sourceImage
            }else{
                cell.imgView.image = self.createFilteredImage(filterName: filter.filterName, image: sourceImage)
            }
        }
        cell.lbl.text = filter.filterDisplayName
        
        cell.lbl.textColor = .gray
        cell.lbl.textColor = (selectedIndexPath != nil && indexPath == selectedIndexPath) ? .white : .gray
        cell.selectedImgView.isHidden = (selectedIndexPath != nil && indexPath == selectedIndexPath) ? false : true
        return cell
    }
}

extension FilterView :UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.filterSelected(self.filters[indexPath.item])

        let cell = videoFilterCollectionView.cellForItem(at: indexPath) as! FilterCollectionViewCell
        cell.selectedImgView.isHidden = false
        cell.lbl.textColor = .white
        cell.lbl.textColor = .white
        self.selectedIndexPath = indexPath
        scrollCollectionViewToIndex(itemIndex: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = videoFilterCollectionView.cellForItem(at: indexPath) as? FilterCollectionViewCell {
            cell.selectedImgView.isHidden = true
            cell.lbl.textColor = .gray
            selectedIndexPath = nil
        }
    }
    
    func scrollCollectionViewToIndex(itemIndex: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let indexPath = IndexPath(item: itemIndex, section: 0)
            self.videoFilterCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

extension FilterView :UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 62, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

