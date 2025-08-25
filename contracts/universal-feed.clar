;; Universal Feed Protocol
;; A decentralized content and subscription management smart contract

;; Error codes
(define-constant err-not-authorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-insufficient-balance (err u104))

;; Status constants
(define-constant status-active u1)
(define-constant status-inactive u0)
(define-constant status-suspended u2)

;; Content Feed Structure
(define-map content-feeds
  { feed-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-utf8 500),
    category: (string-ascii 50),
    created-at: uint,
    subscriber-count: uint,
    status: uint
  }
)

;; Subscription tracking
(define-map subscriptions
  { feed-id: uint, subscriber: principal }
  {
    subscribed-at: uint,
    tier: (string-ascii 20)
  }
)

;; Content entries within a feed
(define-map feed-entries
  { feed-id: uint, entry-id: uint }
  {
    content: (string-utf8 1000),
    creator: principal,
    created-at: uint,
    likes: uint,
    comments-count: uint
  }
)

;; Counter tracking
(define-data-var next-feed-id uint u1)
(define-data-var next-entry-id uint u1)

;; Private helper functions

;; Verify feed creator
(define-private (is-feed-creator (feed-id uint) (sender principal))
  (match (map-get? content-feeds { feed-id: feed-id })
    feed (is-eq (get creator feed) sender)
    false
  )
)

;; Public functions

;; Create a new content feed
(define-public (create-feed
  (title (string-ascii 100))
  (description (string-utf8 500))
  (category (string-ascii 50))
)
  (let (
    (feed-id (var-get next-feed-id))
    (creator tx-sender)
  )
    ;; Validate inputs
    (asserts! (> (len title) u0) err-invalid-input)
    (asserts! (> (len description) u0) err-invalid-input)

    ;; Create feed
    (map-set content-feeds
      { feed-id: feed-id }
      {
        creator: creator,
        title: title,
        description: description,
        category: category,
        created-at: block-height,
        subscriber-count: u0,
        status: status-active
      }
    )

    ;; Increment feed ID
    (var-set next-feed-id (+ feed-id u1))

    (ok feed-id)
  )
)

;; Subscribe to a feed
(define-public (subscribe (feed-id uint) (tier (string-ascii 20)))
  (let (
    (feed (unwrap! (map-get? content-feeds { feed-id: feed-id }) err-not-found))
    (subscriber tx-sender)
  )
    ;; Validate feed status
    (asserts! (is-eq (get status feed) status-active) err-not-authorized)

    ;; Prevent duplicate subscriptions
    (asserts! (is-none (map-get? subscriptions { feed-id: feed-id, subscriber: subscriber })) err-already-exists)

    ;; Add subscription
    (map-set subscriptions
      { feed-id: feed-id, subscriber: subscriber }
      {
        subscribed-at: block-height,
        tier: tier
      }
    )

    ;; Update feed subscriber count
    (map-set content-feeds
      { feed-id: feed-id }
      (merge feed { subscriber-count: (+ (get subscriber-count feed) u1) })
    )

    (ok true)
  )
)

;; Add content entry to a feed
(define-public (add-entry
  (feed-id uint)
  (content (string-utf8 1000))
)
  (let (
    (feed (unwrap! (map-get? content-feeds { feed-id: feed-id }) err-not-found))
    (creator tx-sender)
    (entry-id (var-get next-entry-id))
  )
    ;; Validate feed status and creator
    (asserts! (is-eq (get status feed) status-active) err-not-authorized)
    (asserts! (is-eq creator (get creator feed)) err-not-authorized)

    ;; Add entry
    (map-set feed-entries
      { feed-id: feed-id, entry-id: entry-id }
      {
        content: content,
        creator: creator,
        created-at: block-height,
        likes: u0,
        comments-count: u0
      }
    )

    ;; Increment entry ID
    (var-set next-entry-id (+ entry-id u1))

    (ok entry-id)
  )
)

;; Read-only functions for retrieving data

(define-read-only (get-feed (feed-id uint))
  (map-get? content-feeds { feed-id: feed-id })
)

(define-read-only (get-feed-entries (feed-id uint))
  (filter 
    (lambda (entry) 
      (is-eq (get feed-id entry) feed-id)
    )
    (map-keys feed-entries)
  )
)

(define-read-only (get-user-feeds (creator principal))
  (filter 
    (lambda (feed) 
      (is-eq (get creator feed) creator)
    )
    (map-keys content-feeds)
  )
)