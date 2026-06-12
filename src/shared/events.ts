export const GameEvents = {
  playerStatsChanged: 'player-stats-changed',
  bossStatsChanged: 'boss-stats-changed',
  scoreChanged: 'score-changed',
  bossSpawned: 'boss-spawned',
  bossDefeated: 'boss-defeated',
  playerDied: 'player-died',
  levelWon: 'level-won',
} as const;

export type PlayerStatsPayload = {
  health: number;
  maxHealth: number;
  lives: number;
  special: number;
  maxSpecial: number;
};

export type BossStatsPayload = {
  name: string;
  health: number;
  maxHealth: number;
  active: boolean;
};
