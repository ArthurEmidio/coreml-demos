//
//  SentimentAnalysisViewController.swift
//  CoreMLDemos
//
//  Created by Arthur Emídio Teixeira Ferreira on 12/2/17.
//  Copyright © 2017 Arthur Emídio Teixeira Ferreira. All rights reserved.
//

import UIKit
import CoreML

class SentimentAnalysisViewController: UIViewController
{
    @IBOutlet var _statusLabel: UILabel!

    @IBOutlet var _textField: UITextView!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextViewTextDidChange,
                                               object: _textField,
                                               queue: OperationQueue.main,
                                               using: _textChanged)
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        _textField.becomeFirstResponder()
    }

    private func _textChanged(notification: Notification)
    {
        let histogram = _textField.text.getWordCount(minLength: 3)
        if histogram.isEmpty {
            _statusLabel.text = "😶"
        } else {
            do {
                let pred = try SentimentPolarity().prediction(input: histogram)
                let probPositive = pred.classProbability["Pos"]!
                switch probPositive {
                case 0..<0.25:
                    _statusLabel.text = "😩"
                case 0.25..<0.50:
                    _statusLabel.text = "☹️"
                case 0.50..<0.75:
                    _statusLabel.text = "🙂"
                default:
                    _statusLabel.text = "😀"
                }
            } catch let err {
                print("Failed to obtain prediction: \(err.localizedDescription)")
                _statusLabel.text = "🐞"
            }
        }
    }

    @IBAction func didLongPress(_ sender: Any)
    {
        self.modalTransitionStyle = .crossDissolve
        self.dismiss(animated: true)
    }
}

extension String
{
    func getWordCount(minLength: Int) -> [String: Double]
    {
        let str = self + " "
        var histogram = [String: Double]()
        var word = ""

        for c in str {
            if !CharacterSet.alphanumerics.contains(c.unicodeScalars.first!) {
                if !word.isEmpty {
                    if word.count >= minLength {
                        let count = histogram[word] ?? 0
                        histogram[word.lowercased()] = count + 1
                    }
                    word = ""
                }
            } else {
                word.append(c)
            }
        }

        return histogram
    }
}
