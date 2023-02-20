//
//  StorageManager.swift
//  Thoughts
//
//  Created by Raul Palade on 17/02/23.
//

import FirebaseStorage
import Foundation
import UIKit

final class StorageManager {
    static let shared = StorageManager()

    private let container = Storage.storage()

    private init() {
    }

    public func uploadUserProfilePicture(email: String, image: UIImage?, completion: @escaping (Bool) -> Void) {
        let path = email
            .replacingOccurrences(of: "@", with: "_")
            .replacingOccurrences(of: ".", with: "_")

        guard let pngData = image?.pngData() else {
            return
        }

        container.reference(withPath: "profile_pictures/\(path)/photo.png").putData(pngData, metadata: nil) {
            metadata, error in
            guard metadata != nil, error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }

    public func downloadUrlForProfilePicture(
        path: String,
        completion: @escaping (URL?) -> Void
    ) {
        container.reference(withPath: path)
            .downloadURL { url, _ in
                completion(url)
            }
    }

    public func downloadUserProfilePicture(email: String, completion: @escaping (Bool) -> Void) {
    }

    public func uploadBlogHeaderImage(blogPost: BlogPost, image: UIImage?, completion: @escaping (URL?) -> Void) {
    }

    public func downloadUrlForPostHeader(blogPost: BlogPost, completion: @escaping (URL?) -> Void) {
    }
}
