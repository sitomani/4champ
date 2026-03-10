//
//  ComposerTitleView.swift
//  ampplayer
//
//  Copyright © 2026 Aleksi Sitomaniemi
//
import UIKit

class ComposerTitleView: UIView {

  private var toggleSort: (() -> Void)?
  
  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textColor = Appearance.barTitleColor
    label.font = .systemFont(ofSize: 16, weight: .bold)
    label.textAlignment = .center
    return label
  }()
  
  lazy var sortButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage.init(named: "sort-az-asc"), for: .normal)
    return button
  }()
  
  convenience init(toggleSort: @escaping () -> Void) {
    self.init()
    self.toggleSort = toggleSort
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
  
  func updateSortType(_ sortType: SortType?) {
    let imageName: String
    switch sortType {
    case .idAscending:
      imageName = "sort-id-asc"
    case .idDescending:
      imageName = "sort-id-desc"
    case .nameDescending:
      imageName = "sort-az-desc"
    case .nameAscending, .none:
      imageName = "sort-az-asc"
    }
    sortButton.setImage(UIImage.init(named: imageName), for: .normal)
  }
  
  func setupView() {
    addSubview(titleLabel)
    addSubview(sortButton)
    sortButton.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)
    setUpLabelConstrains()
  }
  
  @objc private func sortButtonTapped() {
    toggleSort?()
  }
  
  required init?(coder: NSCoder) {
    abort()
  }
  
  deinit {
    
  }
  private func setUpLabelConstrains() {
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    sortButton.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
        titleLabel.topAnchor.constraint(equalTo: topAnchor),
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

        sortButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4),
        sortButton.trailingAnchor.constraint(equalTo: trailingAnchor),
        sortButton.topAnchor.constraint(equalTo: topAnchor),
        sortButton.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
    
    setContentHuggingPriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)
  }
}
