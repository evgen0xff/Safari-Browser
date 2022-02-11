//
//  WebCollectionCell.swift
//  SafariWebBrowser
//
//

import UIKit
import Combine

protocol WebCollectionCellDelegate {
    func onClose(cell: UICollectionViewCell?, model: WebViewModel?)
    func onPanGuestureOnBottom(cell: UICollectionViewCell, gesture: UIPanGestureRecognizer)
    func getPanGesture() -> UIPanGestureRecognizer?
}

class WebCollectionCell: UICollectionViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var viewWeb: UIView!
    @IBOutlet weak var viewBottomTitle: UIView!
    @IBOutlet weak var viewBottomSearch: UIView!
    @IBOutlet weak var webView: WebView!
    @IBOutlet weak var constWidth: NSLayoutConstraint!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var txtfSearch: UITextField!
    @IBOutlet weak var marginbottomSearch: NSLayoutConstraint!
    
    var viewModel: WebViewModel?
    var delegate: WebCollectionCellDelegate?
    var subscription = Set<AnyCancellable>()
    var panGestureBottom: UIPanGestureRecognizer?
    var offsetX: CGFloat = 0.0
    
    var status: Status = .grid {
        didSet {
            switch status {
            case .grid:
                layer.cornerRadius = 10.0
                viewWeb.layer.cornerRadius = 10.0
                btnClose.isHidden = false
                webView.isUserInteractionEnabled = false
                viewBottomTitle.isHidden = false
                viewBottomSearch.isHidden = true
                constWidth.constant = (MAIN_SCREEN_WIDTH - 60.0) / 2.0
                marginbottomSearch.constant = 0.0
                break
            case .fullScreen, .scrollingHorizontal:
                layer.cornerRadius = 0.0
                viewWeb.layer.cornerRadius = 0.0
                btnClose.isHidden = true
                webView.isUserInteractionEnabled = true
                viewBottomTitle.isHidden = true
                viewBottomSearch.isHidden = false
                constWidth.constant = MAIN_SCREEN_WIDTH
                break
            case .scalingVertical:
                layer.cornerRadius = 5.0
                viewWeb.layer.cornerRadius = 5.0
                btnClose.isHidden = true
                webView.isUserInteractionEnabled = false
                viewBottomTitle.isHidden = true
                viewBottomSearch.isHidden = true
                constWidth.constant = (MAIN_SCREEN_WIDTH - 60.0) / 2.0
                marginbottomSearch.constant = 0.0
                break
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let panGestureWeb = UIPanGestureRecognizer(target: self, action: #selector(handlePanWeb(_:)))
        panGestureBottom = UIPanGestureRecognizer(target:self, action: #selector(handlePanBottom(_:)))
        
        viewWeb.addGestureRecognizer(panGestureWeb)
        panGestureWeb.require(toFail: webView.scrollView.panGestureRecognizer)
        
        viewBottomSearch.addGestureRecognizer(panGestureBottom!)
        
        txtfSearch.delegate = self
    }
    
    @objc func handlePanWeb(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        print("translation : ", translation)

        if status == .grid {
            switch gesture.state {
            case .began:
                UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn) {
                    self.layer.zPosition = 1
                    self.bounds.size = CGSize(width: self.bounds.width + 20, height: self.bounds.height + 20)
                    self.alpha = 0.8
                }
                break
            case .changed:
                center.x += translation.x
                offsetX += translation.x
                gesture.setTranslation(.zero, in: self)
                break
            case .ended:
                UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut) {
                    self.layer.zPosition = 0
                    self.bounds.size = CGSize(width: self.bounds.width - 20, height: self.bounds.height - 20)
                    self.alpha = 1.0
                    if self.offsetX < -100 {
                        self.center.x = -self.bounds.width
                    }else {
                        self.center.x -= self.offsetX
                    }
                } completion: { isEnded in
                    if isEnded {
                        if self.offsetX < -100 {
                            self.isHidden = true
                            self.delegate?.onClose(cell: self, model: self.viewModel)
                        }
                        self.offsetX = 0
                    }
                }
                break
            default:
                break
            }
        }
    }
    @objc func handlePanBottom(_ gesture: UIPanGestureRecognizer) {
        delegate?.onPanGuestureOnBottom(cell: self, gesture: gesture)
    }

    @IBAction func actionClose(_ sender: Any) {
        delegate?.onClose(cell: self, model: viewModel)
    }
    
    func setData(_ model: WebViewModel?, status: Status, delegate: WebCollectionCellDelegate? = nil) {
        isHidden = false
        self.viewModel = model
        self.delegate = delegate
        self.status = status

        constWidth.constant = status == .fullScreen ? MAIN_SCREEN_WIDTH : (MAIN_SCREEN_WIDTH - 60.0) / 2.0
        
        if let panGesture = delegate?.getPanGesture() {
            panGestureBottom?.require(toFail: panGesture)
        }

        txtfSearch.text = model?.searchUrl
        lblTitle.text = ""

        webView.setData(model)
        
        viewModel?.webSiteTitleSubject
            .sink{ [weak self] value in
                self?.lblTitle.text = value
            }.store(in: &subscription)
        
        viewModel?.$searchUrl
            .sink{ [weak self] value in
                self?.txtfSearch.text = value
                self?.webView.isHidden = value.isEmpty
            }.store(in: &subscription)
        
        viewModel?.$heightKeyboard
            .sink{ [weak self] value in
                switch self?.status {
                case .fullScreen, .scrollingHorizontal:
                    if value > 0 {
                        self?.marginbottomSearch.constant = value - 44.0 - UIDevice.current.heightBottomNotch
                    }else {
                        self?.marginbottomSearch.constant = 0.0
                    }
                    break
                case .grid, .scalingVertical:
                    self?.marginbottomSearch.constant = 0.0
                    break
                default:
                    break
                }
            }.store(in: &subscription)

    }
    
    func scaleTo(containerRect: CGRect,
                          offset: CGPoint = .zero,
                          scale: CGFloat = 1.0,
                          sizePadding: CGSize = .zero,
                          animated: Bool = false) {
        
        let action = {
            let width = (containerRect.size.width - sizePadding.width) * scale
            let height = (containerRect.size.height - sizePadding.height) * scale
            let size = CGSize(width: width, height: height)
            self.center = CGPoint(x: containerRect.midX + offset.x , y: containerRect.midY + offset.y)
            self.bounds.size = size
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: action)
        }else {
            action()
        }
    }
}


extension WebCollectionCell : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let search = textField.text {
            viewModel?.searchUrl = search
            viewModel?.onChangedUrl()
        }
        endEditing(true)
        return true
    }
}
