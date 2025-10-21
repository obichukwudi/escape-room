;; title: escape-room
;; version: 1.0.0
;; summary: On-chain Escape Room with sequential puzzle challenges
;; description: Players solve puzzles to progress through rooms and earn NFT rewards

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-COMPLETED (err u101))
(define-constant ERR-WRONG-ANSWER (err u102))
(define-constant ERR-ROOM-LOCKED (err u103))
(define-constant ERR-INVALID-ROOM (err u104))
(define-constant ERR-ALREADY-CLAIMED (err u105))

;; Room puzzle answers (hashed with sha256)
;; Room 1: "CLARITY" -> 0x8f4f8e7f6f7e5d4c3b2a1f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c
;; Room 2: "STACKS" -> 0x7e5d4c3b2a1f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5f4e3d
;; Room 3: "BITCOIN" -> 0x6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5f4e3d2c1b0a9f8e7d6c5b
(define-constant ROOM-1-ANSWER 0x8f4f8e7f6f7e5d4c3b2a1f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c)
(define-constant ROOM-2-ANSWER 0x7e5d4c3b2a1f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5f4e3d)
(define-constant ROOM-3-ANSWER 0x6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5f4e3d2c1b0a9f8e7d6c5b)

(define-constant TOTAL-ROOMS u3)

;; data vars
(define-data-var next-nft-id uint u1)
(define-data-var total-completions uint u0)

;; data maps
;; Track player progress: which room they're currently on (0 = not started, 1-3 = room number, 4 = completed all)
(define-map player-progress principal uint)

;; Track completed rooms per player
(define-map room-completions {player: principal, room: uint} {completed: bool, timestamp: uint})

;; Track NFT rewards claimed
(define-map nft-rewards principal {claimed: bool, nft-id: uint})

;; NFT metadata
(define-map nft-metadata uint {
    owner: principal,
    room: uint,
    completion-time: uint
})

;; Leaderboard - track completion times
(define-map completion-times principal uint)

;; public functions

;; Start the escape room challenge
(define-public (start-challenge)
    (let ((current-progress (default-to u0 (map-get? player-progress tx-sender))))
        (if (is-eq current-progress u0)
            (begin
                (map-set player-progress tx-sender u1)
                (ok u1))
            ERR-ALREADY-COMPLETED)))

;; Submit answer for a room
(define-public (solve-room (room uint) (answer (buff 32)))
    (let (
        (current-progress (default-to u0 (map-get? player-progress tx-sender)))
        (answer-hash (sha256 answer))
    )
    ;; Check if player is on the correct room
    (asserts! (is-eq current-progress room) ERR-ROOM-LOCKED)
    (asserts! (<= room TOTAL-ROOMS) ERR-INVALID-ROOM)

    ;; Check if room already completed
    (asserts! (is-none (map-get? room-completions {player: tx-sender, room: room})) ERR-ALREADY-COMPLETED)

    ;; Verify answer based on room
    (asserts!
        (if (is-eq room u1)
            (is-eq answer-hash ROOM-1-ANSWER)
            (if (is-eq room u2)
                (is-eq answer-hash ROOM-2-ANSWER)
                (if (is-eq room u3)
                    (is-eq answer-hash ROOM-3-ANSWER)
                    false)))
        ERR-WRONG-ANSWER)

    ;; Mark room as completed
    (map-set room-completions
        {player: tx-sender, room: room}
        {completed: true, timestamp: block-height})

    ;; Update player progress
    (if (< room TOTAL-ROOMS)
        (begin
            (map-set player-progress tx-sender (+ room u1))
            (ok (+ room u1)))
        (begin
            ;; All rooms completed
            (map-set player-progress tx-sender (+ TOTAL-ROOMS u1))
            (map-set completion-times tx-sender block-height)
            (var-set total-completions (+ (var-get total-completions) u1))
            (ok (+ TOTAL-ROOMS u1))))))

;; Claim NFT reward after completing all rooms
(define-public (claim-reward)
    (let (
        (current-progress (default-to u0 (map-get? player-progress tx-sender)))
        (already-claimed (default-to {claimed: false, nft-id: u0} (map-get? nft-rewards tx-sender)))
        (new-nft-id (var-get next-nft-id))
    )
    ;; Check if all rooms completed
    (asserts! (> current-progress TOTAL-ROOMS) ERR-ROOM-LOCKED)

    ;; Check if reward not already claimed
    (asserts! (not (get claimed already-claimed)) ERR-ALREADY-CLAIMED)

    ;; Mint NFT reward
    (map-set nft-rewards tx-sender {claimed: true, nft-id: new-nft-id})
    (map-set nft-metadata new-nft-id {
        owner: tx-sender,
        room: TOTAL-ROOMS,
        completion-time: (default-to u0 (map-get? completion-times tx-sender))
    })

    (var-set next-nft-id (+ new-nft-id u1))
    (ok new-nft-id)))

;; Reset progress (for testing or if player wants to try again)
(define-public (reset-progress)
    (begin
        (map-delete player-progress tx-sender)
        (map-delete room-completions {player: tx-sender, room: u1})
        (map-delete room-completions {player: tx-sender, room: u2})
        (map-delete room-completions {player: tx-sender, room: u3})
        (map-delete completion-times tx-sender)
        (ok true)))

;; read only functions

;; Get player's current progress
(define-read-only (get-player-progress (player principal))
    (ok (default-to u0 (map-get? player-progress player))))

;; Check if a specific room is completed
(define-read-only (is-room-completed (player principal) (room uint))
    (ok (default-to false
        (get completed (map-get? room-completions {player: player, room: room})))))

;; Get NFT metadata
(define-read-only (get-nft-metadata (nft-id uint))
    (ok (map-get? nft-metadata nft-id)))

;; Get player's NFT reward info
(define-read-only (get-player-reward (player principal))
    (ok (map-get? nft-rewards player)))

;; Get completion time
(define-read-only (get-completion-time (player principal))
    (ok (map-get? completion-times player)))

;; Get total number of completions
(define-read-only (get-total-completions)
    (ok (var-get total-completions)))

;; Get next NFT ID
(define-read-only (get-next-nft-id)
    (ok (var-get next-nft-id)))

;; Check if player has claimed reward
(define-read-only (has-claimed-reward (player principal))
    (ok (default-to false
        (get claimed (map-get? nft-rewards player)))))

