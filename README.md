🧩 Escape Room Smart Contract

Overview

The Escape Room Smart Contract is an on-chain puzzle challenge built on the Stacks blockchain. Players progress through a series of rooms by solving sequential puzzles. Each puzzle (room) requires submitting the correct hashed answer to advance. Successfully completing all rooms rewards the player with a unique NFT that represents their achievement.

This contract gamifies the blockchain experience through interactive logic, reward minting, and progress tracking — all recorded immutably on-chain.

🏗 Features

Sequential Puzzle System: Players must solve each room in order.

On-Chain Answer Verification: Answers are hashed and validated using sha256.

Progress Tracking: Keeps record of each player's current room, completed rooms, and timestamps.

NFT Rewards: Players receive a unique NFT upon completing all puzzles.

Leaderboard: Tracks completion times for competitive ranking.

Reset Option: Allows players to restart their progress.

⚙️ Contract Structure
Constants

TOTAL-ROOMS — total number of puzzle rooms (3 in this version).

Predefined room answer hashes (ROOM-1-ANSWER, ROOM-2-ANSWER, ROOM-3-ANSWER).

Error codes for authorization, invalid room, wrong answer, etc.

Data Variables

next-nft-id — increments with each reward mint.

total-completions — counts total successful completions.

Data Maps
Map	Description
player-progress	Tracks each player’s current room progress.
room-completions	Records which rooms each player has completed, with timestamps.
nft-rewards	Tracks reward claim status and NFT IDs.
nft-metadata	Stores details of minted NFTs (owner, room, time).
completion-times	Records the block height when a player completes all rooms.
🧠 Core Functions
🔓 Public Functions

(start-challenge)
Initializes a player’s journey, setting their progress to Room 1.

(solve-room room answer)
Submits an answer for the given room.

Verifies that the player is solving the correct room in sequence.

Validates the hashed answer.

Updates progress and completion records.

On completing all rooms, records completion time and updates total completions.

(claim-reward)
Mints an NFT for players who completed all rooms and haven’t yet claimed their reward.

(reset-progress)
Resets all progress and completion data for a player (useful for testing or replay).

👁 Read-Only Functions

get-player-progress – Returns a player’s current room.

is-room-completed – Checks if a player has completed a given room.

get-nft-metadata – Retrieves NFT details by ID.

get-player-reward – Returns a player’s reward claim info.

get-completion-time – Gets the completion timestamp for a player.

get-total-completions – Returns total number of successful completions.

get-next-nft-id – Returns the next NFT ID to be minted.

has-claimed-reward – Checks if a player has claimed their reward.

🧩 Game Flow

Start Challenge:

(contract-call? .escape-room start-challenge)


→ Player begins at Room 1.

Solve Rooms Sequentially:

(contract-call? .escape-room solve-room u1 0x<sha256("CLARITY")>)
(contract-call? .escape-room solve-room u2 0x<sha256("STACKS")>)
(contract-call? .escape-room solve-room u3 0x<sha256("BITCOIN")>)


→ Each success unlocks the next room.

Claim Reward:

(contract-call? .escape-room claim-reward)


→ Player mints an NFT upon completing all rooms.

Check Progress or Metadata:

(contract-call? .escape-room get-player-progress tx-sender)
(contract-call? .escape-room get-nft-metadata u1)

🧾 Notes

All progress and NFT data are stored on-chain.

The contract is modular and can be extended to add more rooms or external NFT minting logic.

Ideal for on-chain games, interactive learning apps, and gamified NFT projects.


🔒 Error Codes
Code	Meaning
u100	Not authorized
u101	Already completed
u102	Wrong answer
u103	Room locked
u104	Invalid room
u105	Already claimed

🧾 License
MIT License