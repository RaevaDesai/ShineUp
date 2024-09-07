//
//  ViewController.swift
//  ShineUp
//
//  Created by Swarasai Mulagari on 9/7/24.
//

import UIKit
import SwiftUI
import CoreML

class ViewController: UIViewController {

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "MarkerFelt-Wide", size: 24)
        label.numberOfLines = 0
        label.textColor = UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1) // Navy blue color
        label.text = ""
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back", for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private let ingredientsCheckButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Ingredients Check", for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemGreen
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(ingredientsCheckButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private var splashScreenHostingController: UIHostingController<SplashScreenView>?
    private var photoCaptureHostingController: UIHostingController<PhotoCaptureView>?
    private var loginHostingController: UIHostingController<LoginView>?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the background color to solid sky blue
        view.backgroundColor = UIColor(red: 0.784, green: 0.894, blue: 0.937, alpha: 1)

        
        showSplashScreen()
        view.addSubview(resultLabel)
        view.addSubview(backButton)
        view.addSubview(ingredientsCheckButton) // Add the ingredients check button
        
        // Set up Auto Layout constraints
        setupConstraints()
    }

    private func setupConstraints() {
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        ingredientsCheckButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            resultLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            resultLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            
            backButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -80), // Move left
            backButton.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 100),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            ingredientsCheckButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 80), // Move right
            ingredientsCheckButton.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            ingredientsCheckButton.widthAnchor.constraint(equalToConstant: 150),
            ingredientsCheckButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func showSplashScreen() {
        let splashScreenView = SplashScreenView(onLogin: { [weak self] in
            self?.navigateToLogin()
        })
        
        splashScreenHostingController = UIHostingController(rootView: splashScreenView)
        
        if let hostingController = splashScreenHostingController {
            addChild(hostingController)
            hostingController.view.frame = view.bounds
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
        }
    }

    private func navigateToLogin() {
        let loginView = LoginView(onLogin: { [weak self] in
            self?.navigateToPhotoCapture()
        })
        
        splashScreenHostingController?.view.removeFromSuperview()
        splashScreenHostingController?.removeFromParent()
        
        let loginHostingController = UIHostingController(rootView: loginView)
        self.loginHostingController = loginHostingController
        
        addChild(loginHostingController)
        loginHostingController.view.frame = view.bounds
        view.addSubview(loginHostingController.view)
        loginHostingController.didMove(toParent: self)
    }

    private func navigateToPhotoCapture() {
        loginHostingController?.view.removeFromSuperview()
        loginHostingController?.removeFromParent()
        
        let photoCaptureView = PhotoCaptureView(onImageCaptured: { [weak self] image in
            DispatchQueue.global(qos: .userInitiated).async {
                self?.analyzeImage(image: image)
            }
        })
        photoCaptureHostingController = UIHostingController(rootView: photoCaptureView)
        
        if let hostingController = photoCaptureHostingController {
            present(hostingController, animated: true, completion: nil)
        }
    }
    
    private func analyzeImage(image: UIImage?) {
        guard let buffer = image?.resize(size: CGSize(width: 224, height: 224))?.getCVPixelBuffer() else {
            DispatchQueue.main.async {
                self.showResult(resultText: "Failed to process image.")
            }
            return
        }

        do {
            let config = MLModelConfiguration()
            let model = try ShineUp(configuration: config)
            let input = ShineUpInput(image: buffer)

            let output = try model.prediction(input: input)
            let text = output.target
            let message = self.getMessage(for: text)
            
            DispatchQueue.main.async {
                // Dismiss the photo capture view before showing the result
                self.photoCaptureHostingController?.dismiss(animated: true, completion: {
                    self.showResult(resultText: message)
                })
            }
        } catch {
            DispatchQueue.main.async {
                self.showResult(resultText: "Error analyzing image.")
            }
        }
    }

    private func getMessage(for condition: String) -> String {
        switch condition.lowercased() {
        case "acne":
            return "This looks like Acne. You can use over-the-counter (OTC) medicated creams, cleansers, and spot treatments to help address pimples as they pop up. 2 common ingredients in acne cream that will help clear you skin is Benzoyl peroxide and Salicylic Acid. Benzoyl peroxide helps dry out existing pimples, prevents new ones from forming, and kills acne-causing bacteria. Salicylic acid helps exfoliate your skin to prevent pores from getting clogged with acne-causing bacteria. Some food ingredients to avoid eating to help treat your acne are milk, sugar, and refined grains. You should also avoid eating fast food and very processed food."
        case "carcinoma":
            return "This looks like Carcinoma. To treat carcinoma, you can get surgery to remove the cancer cells or tumor. If the carcinoma has spread, you can treat it by undergoing chemotherapy, which kills cancer cells or prevents them from multiplying. Or, you can undergo radiation therapy which shrinks tumor before chemotherapy. Some foods that you should avoid are unpasteurized juice, cider, milk, yogurt and backyard eggs. You should also avoid chilled, ready-to-eat sandwiches, or deli-prepared salads made with egg, ham, chicken or seafood. Try to avoid soft cheeses made from unpasteurized milk, including most blue-veined cheeses, Brie, Camembert, feta, goat cheese, and queso fresco or queso blanco. Avoid eating raw or undercooked shellfish, including mussels, clams and oysters. Reheated starchy foods, including rice, pasta and couscous can be quite dangerous as well."
        case "eczema":
            return "This looks like Eczema. To treat eczema, you can apply topical medications to your skin as advised by your provider, like topical steroids. Furthermore, you can also take oral medications like anti-inflammatory medicines, antihistamines or corticosteroids to reduce itchiness and swelling. Light therapy also improve the appearance of your skin and remove blemishes. Avoid eating foods with the ingredients milk, eggs, wheat, soy, peanuts, tree nuts, and shellfish. Try not to eat processed foods either."
        case "keratosis":
            return "This looks like Keratosis. To treat keratosis, you can use creams to remove dead skin cells and to prevent plugged follicles, such as tretitonin or tazarotene creams. Some home remedies that treat keratosis are exfoliation, using warm water to remove dead cells, dry brushing the skin, and apple cider vinegar to break down the keratin. To avoid irritating the keratosis more, you should avoid consuming food that are high in sugar, gluten, dairy, food dyes, processed foods, soda, alcohol, and industrial seed oils like canola, corn, cottonseed, soy, safflower, and sunflower oil."
        default:
            return "Sorry, I'm not sure what this is. Please consult a medical professional for further assistance."
        }
    }

    private func showResult(resultText: String) {
        resultLabel.text = resultText
        resultLabel.isHidden = false
        backButton.isHidden = false
        ingredientsCheckButton.isHidden = false // Show the ingredients check button
    }

    @objc private func backButtonTapped() {
        // Reset the UI to the login screen
        resultLabel.isHidden = true
        backButton.isHidden = true
        ingredientsCheckButton.isHidden = true // Hide the ingredients check button

        navigateToLogin()
    }
    
    @objc private func ingredientsCheckButtonTapped() {
        // Navigate to the IngredientsCheck view when the button is tapped
        let ingredientsCheckView = IngredientsCheck()
        let hostingController = UIHostingController(rootView: ingredientsCheckView)
        present(hostingController, animated: true, completion: nil)
    }
}
