//
//  CreatePostViewController.swift
//  Thoughts
//
//  Created by Raul Palade on 17/02/23.
//

import UIKit

class CreateNewPostViewController: UITabBarController {
    // Image header
    private let headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "photo")
        imageView.backgroundColor = .tertiarySystemBackground
        return imageView
    }()

    // Title field
    private let titleField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .words
        field.autocorrectionType = .yes
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 50))
        field.leftViewMode = .always
        field.placeholder = "Enter title..."
        field.backgroundColor = .secondarySystemBackground
        field.layer.masksToBounds = true
        return field
    }()

    // Textview for post
    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = true
        textView.font = .systemFont(ofSize: 20)
        textView.backgroundColor = .secondarySystemBackground
        return textView
    }()

    private var selectedHeaderImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(headerImageView)
        view.addSubview(textView)
        view.addSubview(titleField)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapHeader))
        headerImageView.addGestureRecognizer(tap)
        configureButtons()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        titleField.frame = CGRect(x: 10, y: view.safeAreaInsets.top, width: view.width + 10, height: 50)
        headerImageView.frame = CGRect(x: 0, y: titleField.bottom + 5, width: view.width, height: 160)
        textView.frame = CGRect(x: 10, y: headerImageView.bottom + 10, width: view.width - 20, height: view.height - 210 - view.safeAreaInsets.top)
    }

    @objc private func didTapHeader() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    private func configureButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didTapCancel))

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .done, target: self, action: #selector(didTapPost))
    }

    @objc private func didTapCancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func didTapPost() {
        // Check data and post
        guard let title = titleField.text,
              let body = textView.text,
              let headerImage = selectedHeaderImage,
              let email = UserDefaults.standard.string(forKey: "email"),
              !title.trimmingCharacters(in: .whitespaces).isEmpty,
              !body.trimmingCharacters(in: .whitespaces).isEmpty
        else {
            let alert = UIAlertController(title: "Enter Post Details", message: "Please enter a title, body and select a image to continue", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            present(alert, animated: true)
            return
        }

        let newPostId = UUID().uuidString

        // Upload header image
        StorageManager.shared.uploadBlogHeaderImage(email: email, image: headerImage, postId: newPostId) { success in
            guard success else {
                DispatchQueue.main.async {
                    HapticsManager.shared.vibrate(for: .error)
                }
                print("Failed to post url for header")
                return
            }
            StorageManager.shared.downloadUrlForPostHeader(email: email, postId: newPostId) {
                url in
                guard let headerUrl = url else {
                    DispatchQueue.main.async {
                        HapticsManager.shared.vibrate(for: .error)
                    }
                    return
                }

                // Insertion post into database
                let post = BlogPost(identifier: newPostId, title: title, timestamp: Date().timeIntervalSince1970, headerImageUrl: headerUrl, text: body)

                DatabaseManager.shared.insert(blogPost: post, email: email) { [weak self] posted in
                    guard posted else {
                        DispatchQueue.main.async {
                            HapticsManager.shared.vibrate(for: .error)
                        }
                        return
                    }

                    DispatchQueue.main.async {
                        HapticsManager.shared.vibrate(for: .success)
                        self?.didTapCancel()
                    }
                }
            }
        }
    }
}

extension CreateNewPostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        selectedHeaderImage = image
        headerImageView.image = image
    }
}
