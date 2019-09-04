import Foundation

extension AbstractPost {

    // MARK: - Status

    @objc
    var statusTitle: String? {
        guard let status = self.status else {
            return nil
        }

        return AbstractPost.title(for: status)
    }

    @objc
    var remoteStatus: AbstractPostRemoteStatus {
        get {
            guard let remoteStatusNumber = remoteStatusNumber?.uintValue,
                let status = AbstractPostRemoteStatus(rawValue: remoteStatusNumber) else {
                    return .pushing
            }

            return status
        }

        set {
            remoteStatusNumber = NSNumber(value: newValue.rawValue)
        }
    }

    static func title(for status: Status) -> String {
        return title(forStatus: status.rawValue)
    }

    /// Returns the localized title for the specified status.  Status should be
    /// one of the `PostStatus...` constants.  If a matching title is not found
    /// the status is returned.
    ///
    /// - parameter status: The post status value
    ///
    /// - returns: The localized title for the specified status, or the status if a title was not found.
    ///
    @objc
    static func title(forStatus status: String) -> String {
        switch status {
        case PostStatusDraft:
            return NSLocalizedString("Draft", comment: "Name for the status of a draft post.")
        case PostStatusPending:
            return NSLocalizedString("Pending review", comment: "Name for the status of a post pending review.")
        case PostStatusPrivate:
            return NSLocalizedString("Private", comment: "Name for the status of a post that is marked private.")
        case PostStatusPublish:
            return NSLocalizedString("Published", comment: "Name for the status of a published post.")
        case PostStatusTrash:
            return NSLocalizedString("Trashed", comment: "Name for the status of a trashed post")
        case PostStatusScheduled:
            return NSLocalizedString("Scheduled", comment: "Name for the status of a scheduled post")
        default:
            return status
        }
    }

    // MARK: - Misc

    /// Represent the supported properties used to sort posts.
    ///
    enum SortField {
        case dateCreated
        case dateModified

        /// The keyPath to access the underlying property.
        ///
        var keyPath: String {
            switch self {
            case .dateCreated:
                return #keyPath(AbstractPost.date_created_gmt)
            case .dateModified:
                return #keyPath(AbstractPost.dateModified)
            }
        }
    }

    @objc func containsGutenbergBlocks() -> Bool {
        return content?.contains("<!-- wp:") ?? false
    }

    var analyticsPostType: String? {
        switch self {
        case is Post:
            return "post"
        case is Page:
            return "page"
        default:
            return nil
        }
    }

    // MARK: - Updating the Remote Status
    /// Updates the post after an upload failure.
    ///
    /// - Important: This logic could have been placed in the setter for `remoteStatus`, but it's my belief
    ///     that our code will be much more resilient if we decouple the act of setting the `remoteStatus` value
    ///     and the logic behind processing an upload failure.  In fact I think the `remoteStatus` setter should
    ///     eventually be made private.
    ///
    @objc
    func failedToUpload() {
        guard remoteStatus != .failed, !hasRemote() else {
            return
        }
        
        remoteStatus = .failed

        if !hasRemote() {
            // If the post was not created on the server yet we convert the post to a local draft post with the current date.
            status = .draft
            dateModified = Date()
        }
    }
}
