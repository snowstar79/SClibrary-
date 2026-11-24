import UIKit

/// ВСЁ оформление в стиле iOS 6 собрано здесь — меняй цвета и градиенты под себя.
enum Skin {
    static let barTop = UIColor(red: 0.62, green: 0.74, blue: 0.88, alpha: 1)
    static let barBottom = UIColor(red: 0.27, green: 0.43, blue: 0.66, alpha: 1)
    static let panelTop = UIColor(white: 0.32, alpha: 1)
    static let panelBottom = UIColor(white: 0.08, alpha: 1)
    static let accent = UIColor(red: 0.45, green: 0.72, blue: 1.0, alpha: 1)

    /// Льняная текстура, нарисованная кодом. Хочешь свою — положи linen.png в Assets
    /// и верни UIColor(patternImage: UIImage(named: "linen")!)
    static func linen() -> UIColor {
        let size = CGSize(width: 8, height: 8)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor(white: 0.24, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            for _ in 0..<18 {
                UIColor(white: CGFloat.random(in: 0.14...0.34), alpha: 1).setFill()
                ctx.fill(CGRect(x: Int.random(in: 0..<8), y: Int.random(in: 0..<8), width: 1, height: 1))
            }
        }
        return UIColor(patternImage: img)
    }

    /// Эффект "выдавленного" текста
    static func emboss(_ l: UILabel, dark: Bool = true) {
        l.layer.shadowColor = (dark ? UIColor.black : UIColor.white).cgColor
        l.layer.shadowOffset = CGSize(width: 0, height: dark ? -1 : 1)
        l.layer.shadowOpacity = 0.8
        l.layer.shadowRadius = 0
    }
}

final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    var gradient: CAGradientLayer { layer as! CAGradientLayer }

    init(top: UIColor, bottom: UIColor) {
        super.init(frame: .zero)
        gradient.colors = [top.cgColor, bottom.cgColor]
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 1)
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// Глянцевая кнопка как в iOS 6
final class GlossyButton: UIButton {
    private let base = CAGradientLayer()
    private let gloss = CAGradientLayer()

    init(title: String) {
        super.init(frame: .zero)
        base.colors = [UIColor(red: 0.50, green: 0.64, blue: 0.84, alpha: 1).cgColor,
                       UIColor(red: 0.20, green: 0.36, blue: 0.62, alpha: 1).cgColor]
        gloss.colors = [UIColor(white: 1, alpha: 0.55).cgColor, UIColor(white: 1, alpha: 0.08).cgColor]
        layer.insertSublayer(base, at: 0)
        layer.insertSublayer(gloss, at: 1)
        layer.cornerRadius = 7
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1).cgColor
        setTitle(title, for: .normal)
        titleLabel?.font = .boldSystemFont(ofSize: 16)
        titleLabel?.layer.shadowColor = UIColor.black.cgColor
        titleLabel?.layer.shadowOffset = CGSize(width: 0, height: -1)
        titleLabel?.layer.shadowOpacity = 0.7
        titleLabel?.layer.shadowRadius = 0
        setTitleColor(.white, for: .normal)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        base.frame = bounds
        gloss.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height / 2)
        if let t = titleLabel { bringSubviewToFront(t) }
    }
    override var isHighlighted: Bool { didSet { alpha = isHighlighted ? 0.65 : 1 } }
}
