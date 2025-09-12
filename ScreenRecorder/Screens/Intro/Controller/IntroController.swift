//
//  IntroController.swift
//  ScreenRecorder_Into
//
//  Created by Tonmoy on 8/31/25.
//

import UIKit

class IntroController: UIViewController {

    @IBOutlet weak var vwBtnNext: UIView! {
        didSet { vwBtnNext.layer.cornerRadius = 8 }
    }
    @IBOutlet weak var vwBtnBack: UIView! {
        didSet { vwBtnBack.layer.cornerRadius = 8 }
    }
    @IBOutlet weak var vwBtnThankU: UIView!{
        didSet{ vwBtnThankU.layer.cornerRadius = 8 }
    }
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imgThankU: UIImageView!
    @IBOutlet weak var pageControl: AdvancedPageControlView!
    @IBOutlet weak var collectionOfIntros: UICollectionView! {
        didSet {
            collectionOfIntros.delegate = self
            collectionOfIntros.dataSource = self
            collectionOfIntros.register(IntroFirstPageCVCell.nib(),
                                        forCellWithReuseIdentifier: IntroFirstPageCVCell.identifier)
            collectionOfIntros.contentInset = .zero
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        vwBtnBack.alpha = 0
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        setUpPageControl()
        updateButtons(for: 0)
    }

    private func setUpPageControl() {
        let drawer = ExtendedDotDrawer(
            numberOfPages: intros.count,
            height: 6,
            width: 6,
            space: 8,
            raduis: 3,
            indicatorColor: UIColor(named: "btnColor"),
            dotsColor: UIColor.lightGray,
            isBordered: false,
            borderWidth: 0.0,
            indicatorBorderColor: .clear,
            indicatorBorderWidth: 0.0
        )
        pageControl.drawer = drawer
        pageControl.setPage(0)
    }

    // MARK: - Actions

    @IBAction func btnNext(_ sender: UIButton) {
        let next = min(currentIndex + 1, intros.count - 1)
        goToPage(next)
    }

    @IBAction func btnBack(_ sender: UIButton) {
        let prev = max(currentIndex - 1, 0)
        goToPage(prev)
    }
    
    @IBAction func btnThankU(_ btn: UIButton) {
        self.imgThankU.isHidden = true
        DELEGATE.requestReview()
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            if AppData.premiumUser {
                AppData.isIntroFinished = true
                if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                    delegate.setOnboardingAsRoot()
                }
            } else {
                
                if let vc = UIStoryboard(name: "IAP", bundle: nil).instantiateViewController(withIdentifier: "IAPController") as? IAPController {
                    if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                        delegate.window?.rootViewController = vc
                        delegate.window?.makeKeyAndVisible()
                        
                        delegate.window?.alpha = CGFloat(0.5)
                        UIView.transition(with:  delegate.window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
                            delegate.window?.alpha  = CGFloat(1)
                            
                        }, completion: nil)
                    }
                    
//                    vc.modalPresentationStyle = .fullScreen
//                    vc.modalTransitionStyle = .crossDissolve
//                    self.present(vc, animated: true)
                }
            }
        }
    }

    // MARK: - Helpers

    private var currentIndex: Int {
        let width = collectionOfIntros.bounds.width > 0 ? collectionOfIntros.bounds.width : 1
        let idx = Int(round(collectionOfIntros.contentOffset.x / width))
        return max(0, min(idx, max(0, intros.count - 1)))
    }

    private func goToPage(_ index: Int, animated: Bool = true) {
        guard intros.indices.contains(index) else { return }
        let indexPath = IndexPath(item: index, section: 0)
        collectionOfIntros.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)

        // Update page control (animated)
        pageControl.setPage(index)
    }

    private func updateButtons(for index: Int) {
        UIView.animate(withDuration: 0.25) {
            
            if index == intros.count - 1 {
                self.vwBtnBack.alpha = 0
                self.vwBtnNext.alpha = 0
                self.vwBtnThankU.alpha = 1
            } else {
                self.vwBtnBack.alpha = (index == 0) ? 0 : 1
            }
        }
    }
}

// MARK: - CollectionView

extension IntroController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return intros.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: IntroFirstPageCVCell.identifier,
            for: indexPath
        ) as? IntroFirstPageCVCell {
            cell.setView(intros[indexPath.row], indexPath.row)
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat { 0 }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat { 0 }
}

// MARK: - Sync page control on swipe

extension IntroController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === collectionOfIntros else { return }
        let width = scrollView.frame.width
        guard width > 0 else { return }
        let offsetRatio = scrollView.contentOffset.x / width

        pageControl.setPageOffset(offsetRatio)

        let idx = Int(round(offsetRatio))
        updateButtons(for: idx)
    }
}
