//
//  MainVC.swift
//  SafariWebBrowser
//
//

import UIKit
import Combine

enum Status {
    case grid
    case fullScreen
    case scalingVertical
    case scrollingHorizontal
}

class MainVC: UIViewController {
    
    @IBOutlet weak var imvBackground: UIImageView!
    @IBOutlet weak var vstackCollectionTabs: UIStackView!
    @IBOutlet weak var colvTabs: UICollectionView!
    @IBOutlet weak var lblTabs: UILabel!
    @IBOutlet weak var viewBottomTabs: UIStackView!
    @IBOutlet weak var viewBottomBackForward: UIStackView!
    
    
    var tabs: [WebViewModel] = [WebViewModel]()
    var currentTab: Int?
    
//    var verticalLayout = UICollectionViewFlowLayout()
//    var horizontalLayout = UICollectionViewFlowLayout()

    @Published var offsetX: CGFloat = 0
    @Published var scale: CGFloat = 0
    
    var subscription = Set<AnyCancellable>()
    var status = Status.grid {
        didSet {
            switch status {
            case .fullScreen, .scrollingHorizontal:
                viewBottomBackForward.isHidden = false
                viewBottomTabs.isHidden = true
                break
            case .grid, .scalingVertical:
                viewBottomBackForward.isHidden = true
                viewBottomTabs.isHidden = false
                break
            }
        }
    }
    
    var currentModel: WebViewModel? {
        return currentTab != nil && currentTab! < tabs.count ? tabs[currentTab!] : nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initializeData()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NOTIFICATION_CENTER.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main) { (noti) in
            guard let userInfo = noti.userInfo as NSDictionary? else { return }
            guard let keyboardFrame = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as? NSValue else { return }
            self.willShowKeyboard(frame: keyboardFrame.cgRectValue)
        }
        NOTIFICATION_CENTER.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) { (noti) in
            self.willHideKeyboard()
        }

    }
    
    func willShowKeyboard (frame: CGRect) {
        print("willShowKeyboard frame: ", frame)
        currentModel?.heightKeyboard = frame.height
    }
    
    func willHideKeyboard (){
        print("willHideKeyboard")
        currentModel?.heightKeyboard = 0.0
    }


    //MARK: - User Action Handlers
    @IBAction func actionPlus(_ sender: Any) {
        let newTab = WebViewModel()
        newTab.searchUrl = ""
        tabs.append(newTab)
        
        currentTab = tabs.count - 1
        colvTabs.reloadItems(at: [IndexPath(row: currentTab!, section: 0)])
        lblTabs.text = "\(tabs.count) Tabs"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.moveToFullScreen(IndexPath(row: self.currentTab!, section: 0))
        }

    }
    
    @IBAction func actionDone(_ sender: Any) {
        if tabs.count > 0 {
            currentTab = tabs.count - 1
            moveToFullScreen(IndexPath(row: currentTab!, section: 0))
        }
    }
    
    @IBAction func actionBack(_ sender: Any) {
        currentModel?.webNavigationSubject.send(.BACK)
    }
    
    @IBAction func actionForward(_ sender: Any) {
        currentModel?.webNavigationSubject.send(.FORWARD)
    }
    
    @IBAction func actionRefresh(_ sender: Any) {
        currentModel?.webNavigationSubject.send(.REFRESH)
    }
    
    //MARK: - Private Method
    private func initializeData() {
        $scale
            .removeDuplicates()
            .filter { $0 > 0.0 }
            .sink { [weak self] value in
                print("pan trans offsetY : ", value)
                self?.view.endEditing(true)
                self?.status = .scalingVertical
                self?.scaleCollectionView(scale: value)
            }.store(in: &subscription)
    }
    
    private func setupUI() {
        // Backgroud Image
        let blurEffect = UIBlurEffect(style: .dark)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = imvBackground.bounds
        blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imvBackground.addSubview(blurredEffectView)
        
        // Collection View
        colvTabs.register(UINib(nibName: "WebCollectionCell", bundle: nil), forCellWithReuseIdentifier: "WebCollectionCell")
        colvTabs.delegate = self
        colvTabs.dataSource = self
        colvTabs.dragDelegate = self
        colvTabs.dropDelegate = self
        colvTabs.dragInteractionEnabled = status == .grid
        
//        verticalLayout.scrollDirection = .vertical
//        horizontalLayout.scrollDirection = .horizontal
//        colvTabs.collectionViewLayout = verticalLayout

        // Bottom
        status = .grid
    }
    
    private func switchTo(status: Status) {
        self.status = status

        // Drag and Drop
        colvTabs.dragInteractionEnabled = status == .grid
        
        // Pagenation
        colvTabs.isPagingEnabled = status != .grid
        
        colvTabs.alwaysBounceVertical = status == .grid
        colvTabs.alwaysBounceHorizontal = status != .grid

        // Scroll Direction
        if let flowLayout = colvTabs.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = status == .grid ? .vertical : .horizontal
            colvTabs.setCollectionViewLayout(flowLayout, animated: true)
        }
        
//        colvTabs.setCollectionViewLayout(status == .grid ? verticalLayout : horizontalLayout, animated: true)
    }
    private func scaleCollectionView(scale: CGFloat = 1, animated: Bool = false, complete: ((Bool) -> Void)? = nil ) {
        let action = {
            self.tabs.enumerated().forEach { (itemIndex, itemModel) in
                guard let cell = self.colvTabs.cellForItem(at: IndexPath(row: itemIndex, section: 0)) as? WebCollectionCell else { return }

                let size = CGSize(width: self.colvTabs.bounds.size.width * scale, height: self.colvTabs.bounds.size.height * scale)
                let offsetX: CGFloat = itemIndex == self.currentTab ? 0 : (size.width + 10) * CGFloat(itemIndex) - (size.width + 10) * CGFloat(self.currentTab!)
                let offset = CGPoint(x: offsetX, y: 0)
                cell.status = self.status
                cell.scaleTo(containerRect: self.colvTabs.bounds,
                             offset: offset,
                             scale: scale,
                             sizePadding: CGSize(width: 20.0, height: 0.0))
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: action, completion: complete)
        }else {
            action()
            complete?(true)
        }
    }

    private func finishScaling() {
        if scale >= 0.5, scale <= 0.9 {
            moveToGridScreen()
        }else {
            status = .fullScreen
            scaleCollectionView(scale: 1.0, animated: true)
        }
    }

    private func moveToGridScreen() {
        switchTo(status: .grid)
        colvTabs.performBatchUpdates {
            colvTabs.reloadSections(IndexSet(integer: 0))
            if let index = currentTab {
                colvTabs.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredVertically, animated: false)
                currentTab = nil
            }
        }
    }
    
    private func moveToFullScreen(_ indexPath: IndexPath) {
        guard tabs.count > 0, indexPath.row < tabs.count else { return }

        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            
            guard let cell = self.colvTabs.cellForItem(at: indexPath) as? WebCollectionCell else { return }

            cell.layer.zPosition = 1
            cell.status = .fullScreen
            cell.scaleTo(containerRect: self.colvTabs.bounds, sizePadding: CGSize(width: 20.0, height: 0.0))
        }) { isEnded1 in
            
            guard isEnded1 == true else { return }
            
            self.switchTo(status: .fullScreen)
            self.colvTabs.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                self.tabs.enumerated().forEach { (itemIndex, itemModel) in
                    guard indexPath.row != itemIndex, let cell = self.colvTabs.cellForItem(at: IndexPath(row: itemIndex, section: indexPath.section)) as? WebCollectionCell else { return }
                    cell.status = .fullScreen
                    cell.scaleTo(containerRect: self.colvTabs.bounds,
                                 offset: CGPoint(x: self.colvTabs.bounds.width * CGFloat(itemIndex), y: 0.0),
                                 sizePadding: CGSize(width: 20.0, height: 0.0))
                }
            }) { isEnded2 in
                
                guard isEnded2 == true else { return }
                
                self.tabs.enumerated().forEach { (itemIndex, itemModel) in
                    guard let cell = self.colvTabs.cellForItem(at: IndexPath(row: itemIndex, section: indexPath.section)) as? WebCollectionCell else { return }
                    cell.layer.zPosition = 0
                }
                self.colvTabs.reloadData()
            }
        }
    }
    
    private func getScaleFrom(offsetY: CGFloat = 0.0) -> CGFloat {
        var scale = 3 * (offsetY / MAIN_SCREEN_HEIGHT) + 1
        if scale > 1.0 {
            scale = 1.0
        }
        if scale < 0.5 {
            scale = 0.5
        }
        return scale
    }
    
    func addBlankPage() {
        if let last = tabs.last, !last.searchUrl.isEmpty, currentTab == (tabs.count - 1) {
            let newWebVM = WebViewModel()
            newWebVM.searchUrl = ""
            tabs.append(newWebVM)
            colvTabs.reloadItems(at: [IndexPath(row: tabs.count - 1, section: 0)])
            lblTabs.text = "\(tabs.count) Tabs"
        }
    }

}

//MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension MainVC: UICollectionViewDelegate, UICollectionViewDataSource  {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell : UICollectionViewCell?
        
        if let webCell = collectionView.dequeueReusableCell(withReuseIdentifier: "WebCollectionCell", for: indexPath) as? WebCollectionCell {
            webCell.setData(tabs[indexPath.row], status: status, delegate: self)
            cell = webCell
        }

        return cell ?? UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if status == .grid {
            currentTab = indexPath.row
            moveToFullScreen(indexPath)
        }
    }
}

extension MainVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        switch status {
        case .fullScreen, .scrollingHorizontal:
            self.view.endEditing(true)
            let index = Int(scrollView.contentOffset.x / scrollView.bounds.width)
            if index < tabs.count {
                currentTab = index
                addBlankPage()
            }
            break
        default:
            break
        }
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension MainVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        var insets: UIEdgeInsets
        
        if status == .grid {
            insets = UIEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
        }else {
            insets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        }

        return insets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        var size: CGSize
        if status == .grid {
            let widthItemCell = (MAIN_SCREEN_WIDTH - 60.0) / 2.0
            size = CGSize(width: widthItemCell, height: 250)
        }else {
            size = CGSize(width: MAIN_SCREEN_WIDTH, height: collectionView.bounds.height)
        }

        return size
    }

}

extension MainVC: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = tabs[indexPath.row]
        let itemProvidder = NSItemProvider(object: item.id.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvidder)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        
        return parameters
    }
    
    
}
extension MainVC: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        }else {
            let row = collectionView.numberOfItems(inSection: 0)
            destinationIndexPath = IndexPath(item: row - 1 , section: 0)
        }
        
        if coordinator.proposal.operation == .move {
            reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
        }
    }
    
    fileprivate func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        if let item = coordinator.items.first,
           let sourceIndexPath = item.sourceIndexPath {
            collectionView.performBatchUpdates {
                self.tabs.remove(at: sourceIndexPath.item)
                self.tabs.insert(item.dragItem.localObject as! WebViewModel, at: destinationIndexPath.item)
                
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }
            
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }
    
    
}


extension MainVC: WebCollectionCellDelegate {
    func onClose(cell: UICollectionViewCell?, model: WebViewModel?) {
        if let index = tabs.firstIndex(where: { $0.id == model?.id }) {
            let indexPath = IndexPath(item: index, section: 0)
            colvTabs.performBatchUpdates({
                self.tabs.remove(at: index)
                self.colvTabs.deleteItems(at:[indexPath])
            }, completion: { isFinished in
                if isFinished {
                    self.lblTabs.text = "\(self.tabs.count) Tabs"
                }
            })
        }
    }
    
    func getPanGesture() -> UIPanGestureRecognizer? {
        return colvTabs.panGestureRecognizer
    }
    
    func onPanGuestureOnBottom(cell: UICollectionViewCell, gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: cell)
        switch gesture.state {
        case .began:
            break
        case .changed:
            scale = getScaleFrom(offsetY: translation.y)
            break
        case .ended:
            if status == .scalingVertical {
                finishScaling()
            }
            break
        default:
            break
        }
    }
}
