;; Trust Score Calculator
;; A contract that calculates trust scores based on various factors
;; and stores them on the Stacks blockchain

;; Define the contract
(define-data-var contract-owner principal tx-sender)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-SCORE (err u101))
(define-constant ERR-USER-NOT-FOUND (err u102))
(define-constant ERR-SCORE-OUT-OF-RANGE (err u103))
(define-constant ERR-INVALID-FACTOR-ID (err u104))
(define-constant ERR-INVALID-USER (err u105))
(define-constant ERR-INVALID-NAME (err u106))
(define-constant ERR-INVALID-WEIGHT (err u107))
(define-constant MIN-SCORE u0)
(define-constant MAX-SCORE u100)

;; Data maps
(define-map user-trust-scores
  { user: principal }
  { 
    total-score: uint,
    transaction-count: uint,
    last-updated: uint,
    verification-status: bool
  }
)

(define-map trust-factors
  { factor-id: uint }
  {
    name: (string-ascii 50),
    weight: uint,
    active: bool
  }
)

;; Validation functions
(define-private (is-valid-user (user principal))
  (not (is-eq user tx-sender))  ;; Simple validation - ensure user is not same as tx-sender
)

(define-private (is-valid-factor-id (factor-id uint))
  (< factor-id u1000000)  ;; Simple validation - ensure factor-id is within reasonable range
)

(define-private (is-valid-name (name (string-ascii 50)))
  (> (len name) u0)  ;; Simple validation - ensure name is not empty
)

;; Read-only functions
(define-read-only (get-trust-score (user principal))
  (let ((user-data (map-get? user-trust-scores { user: user })))
    (if (is-some user-data)
        (ok (get total-score (unwrap-panic user-data)))
        ERR-USER-NOT-FOUND))
)

(define-read-only (get-user-data (user principal))
  (map-get? user-trust-scores { user: user })
)

(define-read-only (get-factor (factor-id uint))
  (map-get? trust-factors { factor-id: factor-id })
)

;; Calculate weighted score based on factors
(define-private (calculate-weighted-score (transaction-count uint) (verification-status bool))
  (let (
    (base-score u50)
    (transaction-factor (if (> transaction-count u100) u30 (* transaction-count u3)))
    (verification-bonus (if verification-status u20 u0))
  )
    (+ (+ base-score transaction-factor) verification-bonus)
  )
)

;; Ensure score is within valid range
(define-private (validate-score (score uint))
  (and (>= score MIN-SCORE) (<= score MAX-SCORE))
)

;; Public functions
(define-public (initialize-user (user principal))
  (begin
    (asserts! (is-valid-user user) ERR-INVALID-USER)
    (let ((existing-data (map-get? user-trust-scores { user: user })))
      (if (is-some existing-data)
          (ok true) ;; User already exists
          (begin
            (map-set user-trust-scores
              { user: user }
              {
                total-score: u50, ;; Default starting score
                transaction-count: u0,
                last-updated: block-height,
                verification-status: false
              }
            )
            (ok true))
      )
    )
  )
)

(define-public (update-verification-status (user principal) (status bool))
  (begin
    (asserts! (is-valid-user user) ERR-INVALID-USER)
    (let ((current-data (map-get? user-trust-scores { user: user })))
      (if (is-none current-data)
          (begin
            ;; Initialize the user with default values
            (map-set user-trust-scores
              { user: user }
              {
                total-score: u50, ;; Default starting score
                transaction-count: u0,
                last-updated: block-height,
                verification-status: status
              }
            )
            ;; Calculate initial score with verification status
            (let ((new-score (calculate-weighted-score u0 status)))
              (map-set user-trust-scores
                { user: user }
                {
                  total-score: new-score,
                  transaction-count: u0,
                  last-updated: block-height,
                  verification-status: status
                }
              )
              (ok new-score)
            )
          )
          (begin
            (let (
              (current-unwrapped (unwrap-panic current-data))
              (transaction-count (get transaction-count current-unwrapped))
              (new-score (calculate-weighted-score transaction-count status))
            )
              (map-set user-trust-scores
                { user: user }
                {
                  total-score: new-score,
                  transaction-count: transaction-count,
                  last-updated: block-height,
                  verification-status: status
                }
              )
              (ok new-score)
            )
          )
      )
    )
  )
)

(define-public (increment-transaction-count (user principal))
  (begin
    (asserts! (is-valid-user user) ERR-INVALID-USER)
    (let ((current-data (map-get? user-trust-scores { user: user })))
      (if (is-none current-data)
          (begin
            ;; Initialize the user with default values
            (map-set user-trust-scores
              { user: user }
              {
                total-score: u50, ;; Default starting score
                transaction-count: u1, ;; Start with 1 transaction
                last-updated: block-height,
                verification-status: false
              }
            )
            ;; Calculate initial score with one transaction
            (let ((new-score (calculate-weighted-score u1 false)))
              (map-set user-trust-scores
                { user: user }
                {
                  total-score: new-score,
                  transaction-count: u1,
                  last-updated: block-height,
                  verification-status: false
                }
              )
              (ok new-score)
            )
          )
          (begin
            (let (
              (current-unwrapped (unwrap-panic current-data))
              (new-count (+ (get transaction-count current-unwrapped) u1))
              (verification-status (get verification-status current-unwrapped))
              (new-score (calculate-weighted-score new-count verification-status))
            )
              (map-set user-trust-scores
                { user: user }
                {
                  total-score: new-score,
                  transaction-count: new-count,
                  last-updated: block-height,
                  verification-status: verification-status
                }
              )
              (ok new-score)
            )
          )
      )
    )
  )
)

(define-public (add-trust-factor (factor-id uint) (name (string-ascii 50)) (weight uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-factor-id factor-id) ERR-INVALID-FACTOR-ID)
    (asserts! (is-valid-name name) ERR-INVALID-NAME)
    (asserts! (<= weight MAX-SCORE) ERR-SCORE-OUT-OF-RANGE)
    (map-set trust-factors
      { factor-id: factor-id }
      {
        name: name,
        weight: weight,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (update-factor-status (factor-id uint) (active bool))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-factor-id factor-id) ERR-INVALID-FACTOR-ID)
    (let ((factor-data (map-get? trust-factors { factor-id: factor-id })))
      (if (is-none factor-data)
          ERR-INVALID-FACTOR-ID
          (begin
            (map-set trust-factors
              { factor-id: factor-id }
              {
                name: (get name (unwrap-panic factor-data)),
                weight: (get weight (unwrap-panic factor-data)),
                active: active
              }
            )
            (ok true)
          )
      )
    )
  )
)

;; Contract owner functions
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq new-owner tx-sender)) ERR-INVALID-USER)
    (var-set contract-owner new-owner)
    (ok true)
  )
)

;; Admin function to directly set a trust score (for special cases)
(define-public (admin-set-trust-score (user principal) (score uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-user user) ERR-INVALID-USER)
    (asserts! (validate-score score) ERR-SCORE-OUT-OF-RANGE)
    (let ((current-data (map-get? user-trust-scores { user: user })))
      (if (is-none current-data)
          (begin
            ;; Initialize the user with admin-set score
            (map-set user-trust-scores
              { user: user }
              {
                total-score: score,
                transaction-count: u0,
                last-updated: block-height,
                verification-status: false
              }
            )
            (ok score)
          )
          (begin
            (let ((current-unwrapped (unwrap-panic current-data)))
              (map-set user-trust-scores
                { user: user }
                {
                  total-score: score,
                  transaction-count: (get transaction-count current-unwrapped),
                  last-updated: block-height,
                  verification-status: (get verification-status current-unwrapped)
                }
              )
              (ok score)
            )
          )
      )
    )
  )
)