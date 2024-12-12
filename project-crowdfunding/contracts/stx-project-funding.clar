;; Open Source Project Funding Contract
;; This contract allows users to create and fund open source projects

;; Error codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u1))
(define-constant ERR-PROJECT-DOES-NOT-EXIST (err u2))
(define-constant ERR-PROJECT-ALREADY-FUNDED (err u3))
(define-constant ERR-INSUFFICIENT-BALANCE (err u4))
(define-constant ERR-INVALID-FUNDING-AMOUNT (err u5))
(define-constant ERR-MILESTONE-DOES-NOT-EXIST (err u6))
(define-constant ERR-MILESTONE-INCOMPLETE (err u7))
(define-constant ERR-INVALID-PROJECT-TITLE (err u8))
(define-constant ERR-INVALID-PROJECT-DESCRIPTION (err u9))
(define-constant ERR-INVALID-MILESTONE-TITLE (err u10))
(define-constant ERR-INVALID-MILESTONE-DESCRIPTION (err u11))
(define-constant ERR-INVALID-DEADLINE (err u12))
(define-constant ERR-INVALID-PROJECT-ID (err u13))
(define-constant ERR-INVALID-MILESTONE-ID (err u14))

;; Data variables
(define-data-var contract-administrator principal tx-sender)
(define-map open-source-projects 
    { project-identifier: uint }
    {
        project-creator: principal,
        project-title: (string-ascii 100),
        project-description: (string-utf8 500),
        target-funding-amount: uint,
        total-funds-raised: uint,
        project-status: (string-ascii 20),
        project-creation-block: uint
    }
)

(define-map project-development-milestones
    { project-identifier: uint, milestone-identifier: uint }
    {
        milestone-title: (string-ascii 100),
        milestone-description: (string-utf8 500),
        milestone-completion-deadline: uint,
        milestone-funding-amount: uint,
        milestone-status: (string-ascii 20)
    }
)

(define-map project-funding-contributors
    { project-identifier: uint, funding-contributor: principal }
    { contribution-amount: uint }
)

;; Counter for project IDs
(define-data-var next-project-identifier uint u0)

;; Helper functions for validation
(define-private (is-valid-string-ascii (value (string-ascii 100)))
    (> (len value) u0)
)

(define-private (is-valid-string-utf8 (value (string-utf8 500)))
    (> (len value) u0)
)

(define-private (is-valid-project-id (project-id uint))
    (and 
        (> project-id u0)
        (<= project-id (var-get next-project-identifier))
    )
)

(define-private (is-valid-milestone-id (milestone-id uint))
    (> milestone-id u0)
)

(define-private (is-valid-deadline (deadline uint))
    (>= deadline block-height)
)

;; Initialize contract
(define-public (initialize-contract)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-administrator)) ERR-UNAUTHORIZED-ACCESS)
        (ok true)
    )
)

;; Create a new project
(define-public (create-open-source-project 
                (project-title (string-ascii 100)) 
                (project-description (string-utf8 500))
                (target-funding-amount uint))
    (begin
        ;; Validate inputs
        (asserts! (is-valid-string-ascii project-title) ERR-INVALID-PROJECT-TITLE)
        (asserts! (is-valid-string-utf8 project-description) ERR-INVALID-PROJECT-DESCRIPTION)
        (asserts! (> target-funding-amount u0) ERR-INVALID-FUNDING-AMOUNT)
        
        (let ((new-project-identifier (+ (var-get next-project-identifier) u1)))
            (map-insert open-source-projects
                { project-identifier: new-project-identifier }
                {
                    project-creator: tx-sender,
                    project-title: project-title,
                    project-description: project-description,
                    target-funding-amount: target-funding-amount,
                    total-funds-raised: u0,
                    project-status: "active",
                    project-creation-block: block-height
                }
            )
            (var-set next-project-identifier new-project-identifier)
            (ok new-project-identifier)
        )
    )
)

;; Add milestone to project
(define-public (add-project-milestone 
                (project-identifier uint)
                (milestone-title (string-ascii 100))
                (milestone-description (string-utf8 500))
                (milestone-deadline uint)
                (milestone-funding-amount uint))
    (begin
        ;; Validate inputs
        (asserts! (is-valid-project-id project-identifier) ERR-INVALID-PROJECT-ID)
        (asserts! (is-valid-string-ascii milestone-title) ERR-INVALID-MILESTONE-TITLE)
        (asserts! (is-valid-string-utf8 milestone-description) ERR-INVALID-MILESTONE-DESCRIPTION)
        (asserts! (is-valid-deadline milestone-deadline) ERR-INVALID-DEADLINE)
        
        (let ((project-details (unwrap! (map-get? open-source-projects { project-identifier: project-identifier }) ERR-PROJECT-DOES-NOT-EXIST)))
            (asserts! (is-eq (get project-creator project-details) tx-sender) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (>= (get target-funding-amount project-details) milestone-funding-amount) ERR-INVALID-FUNDING-AMOUNT)
            
            (map-insert project-development-milestones
                { 
                    project-identifier: project-identifier,
                    milestone-identifier: u1
                }
                {
                    milestone-title: milestone-title,
                    milestone-description: milestone-description,
                    milestone-completion-deadline: milestone-deadline,
                    milestone-funding-amount: milestone-funding-amount,
                    milestone-status: "pending"
                }
            )
            (ok true)
        )
    )
)

;; Fund a project
(define-public (contribute-project-funding (project-identifier uint) (funding-amount uint))
    (begin
        (asserts! (is-valid-project-id project-identifier) ERR-INVALID-PROJECT-ID)
        
        (let (
            (project-details (unwrap! (map-get? open-source-projects { project-identifier: project-identifier }) ERR-PROJECT-DOES-NOT-EXIST))
            (current-project-funding (get total-funds-raised project-details))
            (project-funding-goal (get target-funding-amount project-details))
        )
            (asserts! (is-eq (get project-status project-details) "active") ERR-PROJECT-ALREADY-FUNDED)
            (asserts! (> funding-amount u0) ERR-INVALID-FUNDING-AMOUNT)
            (asserts! (<= (+ current-project-funding funding-amount) project-funding-goal) ERR-INVALID-FUNDING-AMOUNT)
            
            ;; Transfer STX from sender to contract
            (try! (stx-transfer? funding-amount tx-sender (as-contract tx-sender)))
            
            ;; Update project funding
            (map-set open-source-projects
                { project-identifier: project-identifier }
                (merge project-details {
                    total-funds-raised: (+ current-project-funding funding-amount)
                })
            )
            
            ;; Record contributor funding
            (match (map-get? project-funding-contributors 
                    { project-identifier: project-identifier, funding-contributor: tx-sender })
                previous-contribution 
                (map-set project-funding-contributors
                    { project-identifier: project-identifier, funding-contributor: tx-sender }
                    { contribution-amount: (+ funding-amount (get contribution-amount previous-contribution)) }
                )
                (map-insert project-funding-contributors
                    { project-identifier: project-identifier, funding-contributor: tx-sender }
                    { contribution-amount: funding-amount }
                )
            )
            
            (ok true)
        )
    )
)

;; Complete milestone
(define-public (complete-project-milestone (project-identifier uint) (milestone-identifier uint))
    (begin
        (asserts! (is-valid-project-id project-identifier) ERR-INVALID-PROJECT-ID)
        (asserts! (is-valid-milestone-id milestone-identifier) ERR-INVALID-MILESTONE-ID)
        
        (let (
            (project-details (unwrap! (map-get? open-source-projects 
                { project-identifier: project-identifier }) ERR-PROJECT-DOES-NOT-EXIST))
            (milestone-details (unwrap! (map-get? project-development-milestones 
                { project-identifier: project-identifier, milestone-identifier: milestone-identifier }) 
                ERR-MILESTONE-DOES-NOT-EXIST))
        )
            (asserts! (is-eq (get project-creator project-details) tx-sender) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (>= block-height (get milestone-completion-deadline milestone-details)) ERR-MILESTONE-INCOMPLETE)
            
            ;; Update milestone status
            (map-set project-development-milestones
                { project-identifier: project-identifier, milestone-identifier: milestone-identifier }
                (merge milestone-details { milestone-status: "completed" })
            )
            
            ;; Transfer milestone amount to project creator
            (try! (as-contract (stx-transfer? 
                (get milestone-funding-amount milestone-details) 
                tx-sender 
                (get project-creator project-details))))
            
            (ok true)
        )
    )
)

;; Read-only functions
;; Get project details
(define-read-only (get-project-details (project-identifier uint))
    (begin
        (asserts! (is-valid-project-id project-identifier) ERR-INVALID-PROJECT-ID)
        (ok (unwrap! (map-get? open-source-projects 
            { project-identifier: project-identifier }) ERR-PROJECT-DOES-NOT-EXIST))
    )
)

;; Get milestone details
(define-read-only (get-milestone-details (project-identifier uint) (milestone-identifier uint))
    (begin
        (asserts! (is-valid-project-id project-identifier) ERR-INVALID-PROJECT-ID)
        (asserts! (is-valid-milestone-id milestone-identifier) ERR-INVALID-MILESTONE-ID)
        (ok (unwrap! (map-get? project-development-milestones 
            { project-identifier: project-identifier, milestone-identifier: milestone-identifier }) 
            ERR-MILESTONE-DOES-NOT-EXIST))
    )
)

;; Get total number of projects
(define-read-only (get-total-projects)
    (ok (var-get next-project-identifier))
)

;; Get contributor funding amount
(define-read-only (get-contributor-funding-amount (project-identifier uint) (funding-contributor principal))
    (begin
        (asserts! (is-valid-project-id project-identifier) ERR-INVALID-PROJECT-ID)
        (ok (unwrap! (map-get? project-funding-contributors 
            { project-identifier: project-identifier, funding-contributor: funding-contributor }) 
            ERR-PROJECT-DOES-NOT-EXIST))
    )
)

;; Check if project is fully funded
(define-read-only (is-project-fully-funded (project-identifier uint))
    (begin
        (asserts! (is-valid-project-id project-identifier) ERR-INVALID-PROJECT-ID)
        (match (map-get? open-source-projects { project-identifier: project-identifier })
            project-details (ok (>= (get total-funds-raised project-details) 
                                   (get target-funding-amount project-details)))
            ERR-PROJECT-DOES-NOT-EXIST
        )
    )
)

;; Check if milestone is completed
(define-read-only (is-milestone-completed (project-identifier uint) (milestone-identifier uint))
    (begin
        (asserts! (is-valid-project-id project-identifier) ERR-INVALID-PROJECT-ID)
        (asserts! (is-valid-milestone-id milestone-identifier) ERR-INVALID-MILESTONE-ID)
        (match (map-get? project-development-milestones 
            { project-identifier: project-identifier, milestone-identifier: milestone-identifier })
            milestone-details (ok (is-eq (get milestone-status milestone-details) "completed"))
            ERR-MILESTONE-DOES-NOT-EXIST
        )
    )
)