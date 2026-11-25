import UIKit

/// 根视图遵循 UIInputViewAudioFeedback，这样 UIDevice.current.playInputClick()
/// 才能生效，并且自动遵循系统「按键音」开关。
private final class KeyboardRootView: UIView, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { true }
}

final class KeyboardViewController: UIInputViewController {
    private let cellID = "ClipboardHistoryCell"
    private let migrationKey = "flatClipboardMigrationV1"
    private let portraitKeyboardHeight: CGFloat = 245
    private let landscapeKeyboardHeight: CGFloat = 175

    private var appData = AppData()
    private var keyboardHeightConstraint: NSLayoutConstraint?
    private var tableView: UITableView!
    private var emptyLabel: UILabel!
    private var lockButton: UIButton!
    private var newlineButton: UIButton!

    // 触感反馈生成器
    private let clickFeedback = UIImpactFeedbackGenerator(style: .light)
    private let deleteFeedback = UINotificationFeedbackGenerator()

    private var keyboardKeyColor: UIColor {
        UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(red: 58.0 / 255.0, green: 58.0 / 255, blue: 60.0 / 255, alpha: 1)
            }
            return .white
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        appData = SharedStore.shared.load()
        migrateLegacyItemsIfNeeded()
        refreshUI()
        registerLifecycleObservers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.superview?.backgroundColor = .clear
        tableView.layer.borderColor = UIColor.separator.withAlphaComponent(0.45).cgColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appData = SharedStore.shared.load()
        refreshUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureCurrentClipboard()
        DispatchQueue.main.async { [weak self] in
            self?.forceKeyboardRedraw()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func registerLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshDisplayAfterScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshDisplayAfterScreenshot),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func refreshDisplayAfterScreenshot() {
        refreshUI()
        forceKeyboardRedraw()
    }

    private func forceKeyboardRedraw() {
        guard let rootView = viewIfLoaded, rootView.window != nil else { return }
        rootView.setNeedsLayout()
        rootView.layoutIfNeeded()
        rootView.alpha = 0.99
        DispatchQueue.main.async {
            rootView.alpha = 1.0
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        keyboardHeightConstraint?.constant = size.width > size.height
            ? landscapeKeyboardHeight
            : portraitKeyboardHeight
    }

    override func loadView() {
        view = KeyboardRootView()
    }

    private func playClickFeedback() {
        UIDevice.current.playInputClick()
        clickFeedback.impactOccurred()
    }

    private func playDeleteFeedback() {
        deleteFeedback.notificationOccurred(.warning)
    }

    private func buildUI() {
        view.backgroundColor = .clear

        let heightConstraint = view.heightAnchor.constraint(equalToConstant: portraitKeyboardHeight)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true
        keyboardHeightConstraint = heightConstraint

        lockButton = UIButton(type: .system)
        lockButton.translatesAutoresizingMaskIntoConstraints = false
        lockButton.setImage(lockIcon(), for: .normal)
        lockButton.tintColor = .label
        styleKey(lockButton)
        lockButton.addTarget(self, action: #selector(toggleLockKeyboard), for: .touchUpInside)

        newlineButton = UIButton(type: .system)
        newlineButton.translatesAutoresizingMaskIntoConstraints = false
        newlineButton.setTitle("换行", for: .normal)
        newlineButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        newlineButton.setTitleColor(.label, for: .normal)
        styleKey(newlineButton)
        newlineButton.addTarget(self, action: #selector(insertNewline), for: .touchUpInside)

        view.addSubview(lockButton)
        view.addSubview(newlineButton)

        tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.backgroundColor = keyboardKeyColor
        tableView.layer.cornerRadius = 8
        tableView.layer.borderWidth = 0.5
        tableView.clipsToBounds = true
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 48
        tableView.tableFooterView = UIView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        emptyLabel = UILabel()
        emptyLabel.font = .systemFont(ofSize: 13)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            newlineButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            newlineButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            newlineButton.widthAnchor.constraint(equalToConstant: 65),
            newlineButton.heightAnchor.constraint(equalToConstant: 38),

            lockButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            lockButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            lockButton.widthAnchor.constraint(equalToConstant: 50),
            lockButton.heightAnchor.constraint(equalToConstant: 38),

            tableView.topAnchor.constraint(equalTo: newlineButton.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),

            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: tableView.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: tableView.trailingAnchor, constant: -24)
        ])
    }

    private func styleKey(_ button: UIButton) {
        button.backgroundColor = keyboardKeyColor
        button.layer.cornerRadius = 7
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.separator.withAlphaComponent(0.5).cgColor
    }

    private func migrateLegacyItemsIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationKey) else { return }

        var data = SharedStore.shared.load()
        var allItems = data.history
        let oldItems = data.folders.flatMap(\.items) + data.stockPools.flatMap(\.items)
        allItems.append(contentsOf: oldItems.map {
            HistoryItem(id: $0.id, content: $0.content, createdAt: $0.createdAt)
        })

        var seen = Set<String>()
        data.history = allItems
            .sorted { $0.createdAt > $1.createdAt }
            .filter { seen.insert($0.content).inserted }
            .prefix(SharedStore.historyLimit)
            .map { $0 }

        if SharedStore.shared.save(data) {
            defaults.set(true, forKey: migrationKey)
            appData = data
        }
    }

    private func captureCurrentClipboard() {
        guard viewIfLoaded?.window != nil, hasFullAccess, let text = UIPasteboard.general.string else {
            updateEmptyState()
            return
        }
        if let data = SharedStore.shared.captureClipboard(text) {
            appData = data
            tableView?.reloadData()
        }
        updateEmptyState()
    }

    private func refreshUI() {
        updateLockButton()
        updateEmptyState()
        tableView.reloadData()
    }

    private func updateLockButton() {
        let locked = SharedStore.shared.lockKeyboard
        lockButton.tintColor = locked ? .systemBlue : .label
        lockButton.backgroundColor = keyboardKeyColor
        lockButton.setImage(lockIcon(), for: .normal)
        lockButton.accessibilityLabel = "锁定键盘"
        lockButton.accessibilityValue = locked ? "已锁定" : "未锁定"
    }

    private func lockIcon() -> UIImage {
        let size = CGSize(width: 31, height: 29)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            UIImage(systemName: "keyboard")?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
                .draw(in: CGRect(x: 0, y: 8.4, width: 21.6, height: 15.6))
            UIImage(systemName: "lock.fill")?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
                .draw(in: CGRect(x: 14.4, y: 0, width: 16.8, height: 16.8))
        }
        return image.withRenderingMode(.alwaysTemplate)
    }

    private func updateEmptyState() {
        if !hasFullAccess {
            emptyLabel.text = "开启「允许完全访问」后\n键盘才能读取当前剪贴板。"
        } else {
            emptyLabel.text = "剪贴板列表为空。\n复制一段文字后切回此键盘\n内容将会自动收录。"
        }
        emptyLabel.isHidden = !appData.history.isEmpty
    }

    @objc private func toggleLockKeyboard() {
        playClickFeedback()
        SharedStore.shared.lockKeyboard = !SharedStore.shared.lockKeyboard
        updateLockButton()
    }

    @objc private func insertNewline() {
        playClickFeedback()
        textDocumentProxy.insertText("\n\u{200B}")
        textDocumentProxy.deleteBackward()
    }

    private func insert(_ item: HistoryItem) {
        textDocumentProxy.insertText(item.content)
        if !SharedStore.shared.lockKeyboard {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self, self.viewIfLoaded?.window != nil else { return }
                self.advanceToNextInputMode()
            }
        }
    }

    private func deleteHistoryItem(id: UUID) {
        var data = SharedStore.shared.load()
        guard let index = data.history.firstIndex(where: { $0.id == id }) else { return }
        data.history.remove(at: index)
        guard SharedStore.shared.save(data) else { return }
        appData = data
        tableView.reloadData()
        updateEmptyState()
    }
}

extension KeyboardViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        appData.history.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        var content = cell.defaultContentConfiguration()
        guard appData.history.indices.contains(indexPath.row) else {
            content.text = nil
            cell.contentConfiguration = content
            return cell
        }
        let item = appData.history[indexPath.row]
        content.text = item.content
        content.textProperties.font = .systemFont(ofSize: 17)
        content.textProperties.numberOfLines = 1
        content.textProperties.lineBreakMode = .byTruncatingTail
        content.image = UIImage(
            systemName: "doc.on.clipboard",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17)
        )
        content.imageProperties.tintColor = .secondaryLabel
        cell.contentConfiguration = content
        cell.backgroundColor = keyboardKeyColor
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard appData.history.indices.contains(indexPath.row) else { return }
        playClickFeedback()
        let item = appData.history[indexPath.row]
        insert(item)
    }

    // 系统原生滑动：左滑时删除区从右侧随内容一起展开，滑到底触发删除。
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard appData.history.indices.contains(indexPath.row) else { return nil }
        let itemID = appData.history[indexPath.row].id
        let delete = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, done in
            self?.playDeleteFeedback()
            self?.deleteHistoryItem(id: itemID)
            done(true)
        }
        delete.backgroundColor = .systemRed
        delete.image = UIImage(
            systemName: "trash",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        )?.withTintColor(.white, renderingMode: .alwaysOriginal)
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

